use crate::client::translate;
#[cfg(windows)]
use crate::ipc::Data;
#[cfg(windows)]
use hbb_common::tokio;
use hbb_common::{allow_err, log};
use base::config::keys;
use std::sync::{Arc, Mutex};
#[cfg(windows)]
use std::time::Duration;

pub fn start_tray() {
    // SecureDesk: 总是创建托盘进程，若配置为隐藏则创建后立即销毁并刷新系统托盘区域。
    // 这样可以运行期通过 IPC 动态显示/隐藏托盘图标（见 Data::HideTray）。
    #[cfg(target_os = "linux")]
    crate::server::check_zombie();

    allow_err!(make_tray());
}

fn make_tray() -> hbb_common::ResultType<()> {
    // https://github.com/tauri-apps/tray-icon/blob/dev/examples/tao.rs
    use hbb_common::anyhow::Context;
    use tao::event_loop::{ControlFlow, EventLoopBuilder};
    use tray_icon::{
        menu::{Menu, MenuEvent, MenuItem},
        TrayIcon, TrayIconBuilder, TrayIconEvent as TrayEvent,
    };

    // Duplicated tray icons kept piling up through the blind spots of
    // `check_process("--tray", ..)`. https://github.com/rustdesk/rustdesk/issues/15689
    #[cfg(windows)]
    if !crate::platform::windows::try_lock_tray_single_instance() {
        log::info!("Another tray process is already running in this session, exit");
        return Ok(());
    }

    let icon;
    #[cfg(target_os = "macos")]
    {
        icon = include_bytes!("../res/mac-tray-dark-x2.png"); // use as template, so color is not important
    }
    #[cfg(not(target_os = "macos"))]
    {
        icon = include_bytes!("../res/tray-icon.ico");
    }

    let (icon_rgba, icon_width, icon_height) = {
        let image = load_icon_from_asset()
            .unwrap_or(image::load_from_memory(icon).context("Failed to open icon path")?)
            .into_rgba8();
        let (width, height) = image.dimensions();
        let rgba = image.into_raw();
        (rgba, width, height)
    };
    let icon = tray_icon::Icon::from_rgba(icon_rgba, icon_width, icon_height)
        .context("Failed to open icon")?;

    let mut event_loop = EventLoopBuilder::new().build();

    let tray_menu = Menu::new();
    let hide_stop_service = crate::ui_interface::get_builtin_option(
        keys::OPTION_HIDE_STOP_SERVICE,
    ) == "Y";
    // The tray icon is only shown when the service is running, so we don't need to check
    // the `stop-service` option here.
    let quit_i = if !hide_stop_service {
        Some(MenuItem::new(translate("Stop service".to_owned()), true, None))
    } else {
        None
    };
    let open_i = MenuItem::new(translate("Open".to_owned()), true, None);
    if let Some(quit_i) = &quit_i {
        tray_menu.append_items(&[&open_i, quit_i]).ok();
    } else {
        tray_menu.append_items(&[&open_i]).ok();
    }
    let tooltip = |count: usize| {
        if count == 0 {
            format!(
                "{} {}",
                crate::get_app_name(),
                translate("Service is running".to_owned()),
            )
        } else {
            format!(
                "{} - {}\n{}",
                crate::get_app_name(),
                translate("Ready".to_owned()),
                translate("{".to_string() + &format!("{count}") + "} sessions"),
            )
        }
    };
    let mut _tray_icon: Arc<Mutex<Option<TrayIcon>>> = Default::default();

    let menu_channel = MenuEvent::receiver();
    let tray_channel = TrayEvent::receiver();
    #[cfg(windows)]
    let (ipc_sender, ipc_receiver) = std::sync::mpsc::channel::<Data>();

    let open_func = move || {
        if cfg!(not(feature = "flutter")) {
            crate::run_me::<&str>(vec![]).ok();
            return;
        }
        #[cfg(target_os = "macos")]
        crate::platform::macos::handle_application_should_open_untitled_file();
        #[cfg(target_os = "windows")]
        {
            // Do not use "start uni link" way, it may not work on some Windows, and pop out error
            // dialog, I found on one user's desktop, but no idea why, Windows is shit.
            // Use `run_me` instead.
            // `allow_multiple_instances` in `flutter/windows/runner/main.cpp` allows only one instance without args.
            crate::run_me::<&str>(vec![]).ok();
        }
        #[cfg(target_os = "linux")]
        {
            // Do not use "xdg-open", it won't read the config.
            if crate::dbus::invoke_new_connection(crate::get_uri_prefix()).is_err() {
                if let Ok(task) = crate::run_me::<&str>(vec![]) {
                    crate::server::CHILD_PROCESS.lock().unwrap().push(task);
                }
            }
        }
    };

    // SecureDesk: 托盘图标 IPC 监听器（接收隐藏/显示指令并转发到事件循环）
    #[cfg(windows)]
    {
        let ipc_sender_for_tray = ipc_sender.clone();
        std::thread::spawn(move || {
            start_ipc_listener(ipc_sender_for_tray);
        });
    }
    #[cfg(windows)]
    {
        let ipc_sender_for_count = ipc_sender.clone();
        std::thread::spawn(move || {
            start_query_session_count(ipc_sender_for_count);
        });
    }
    #[cfg(windows)]
    let mut last_click = std::time::Instant::now();
    #[cfg(target_os = "macos")]
    {
        use tao::platform::macos::EventLoopExtMacOS;
        event_loop.set_activation_policy(tao::platform::macos::ActivationPolicy::Accessory);
    }
    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::WaitUntil(
            std::time::Instant::now() + std::time::Duration::from_millis(100),
        );

        if let tao::event::Event::NewEvents(tao::event::StartCause::Init) = event {
            // SecureDesk: 先按配置决定是否隐藏；托盘仍然创建，稍后按需销毁，
            // 以便运行期可以通过 IPC 再次显示出来。
            #[cfg(windows)]
            let hide_tray = crate::ui_interface::get_option(keys::OPTION_HIDE_TRAY) == "Y";
            // We create the icon once the event loop is actually running
            // to prevent issues like https://github.com/tauri-apps/tray-icon/issues/90
            let mut builder = TrayIconBuilder::new()
                .with_id(crate::get_app_name().to_lowercase())
                .with_menu(Box::new(tray_menu.clone()))
                .with_tooltip(tooltip(0))
                .with_icon(icon.clone());
            #[cfg(target_os = "macos")]
            {
                builder = builder.with_icon_as_template(true);
            }
            #[cfg(target_os = "windows")]
            {
                // Required since tray-icon 0.17
                // Fixes #15215, #15222, #15410
                builder = builder.with_menu_on_left_click(false);
            }
            let tray = builder.build();
            match tray {
                Ok(tray) => _tray_icon = Arc::new(Mutex::new(Some(tray))),
                Err(err) => {
                    log::error!("Failed to create tray icon: {}", err);
                }
            };

            // We have to request a redraw here to have the icon actually show up.
            // Tao only exposes a redraw method on the Window so we use core-foundation directly.
            #[cfg(target_os = "macos")]
            unsafe {
                use core_foundation::runloop::{CFRunLoopGetMain, CFRunLoopWakeUp};

                let rl = CFRunLoopGetMain();
                CFRunLoopWakeUp(rl);
            }

            // SecureDesk: 配置为隐藏时，创建后立即销毁图标并刷新系统托盘区域
            #[cfg(windows)]
            if hide_tray {
                *_tray_icon.lock().unwrap() = None;
                refresh_tray_area();
            }
        }

        if let Ok(event) = menu_channel.try_recv() {
            if let Some(quit_i) = &quit_i {
                if event.id == quit_i.id() {
                    /* failed in windows, seems no permission to check system process
                    if !crate::check_process("--server", false) {
                        *control_flow = ControlFlow::Exit;
                        return;
                    }
                    */
                    // Remove the icon first: on success `uninstall_service()` ends
                    // this process with `std::process::exit`, which skips the
                    // destructor that would remove it, leaving a ghost icon behind.
                    #[cfg(windows)]
                    let _ = _tray_icon
                        .lock()
                        .unwrap()
                        .as_mut()
                        .map(|t| t.set_visible(false));
                    if !crate::platform::uninstall_service(false, false) {
                        *control_flow = ControlFlow::Exit;
                    }
                    // Still alive, so stopping the service failed or was cancelled
                    // in the UAC prompt. Show the icon again.
                    #[cfg(windows)]
                    let _ = _tray_icon
                        .lock()
                        .unwrap()
                        .as_mut()
                        .map(|t| t.set_visible(true));
                } else if event.id == open_i.id() {
                    open_func();
                }
            } else if event.id == open_i.id() {
                open_func();
            }
        }

        if let Ok(_event) = tray_channel.try_recv() {
            #[cfg(target_os = "windows")]
            match _event {
                TrayEvent::Click {
                    button,
                    button_state,
                    ..
                } => {
                    if button == tray_icon::MouseButton::Left
                        && button_state == tray_icon::MouseButtonState::Up
                    {
                        if last_click.elapsed() < std::time::Duration::from_secs(1) {
                            return;
                        }
                        open_func();
                        last_click = std::time::Instant::now();
                    }
                }
                _ => {}
            }
        }

        #[cfg(windows)]
        if let Ok(data) = ipc_receiver.try_recv() {
            match data {
                Data::ControlledSessionCount(count) => {
                    _tray_icon
                        .lock()
                        .unwrap()
                        .as_mut()
                        .map(|t| t.set_tooltip(Some(tooltip(count))));
                }
                // SecureDesk: 动态隐藏/显示托盘图标
                Data::HideTray(hide) => {
                    let mut tray_guard = _tray_icon.lock().unwrap();
                    if hide {
                        // 销毁图标对象以隐藏
                        *tray_guard = None;
                        refresh_tray_area();
                    } else if tray_guard.is_none() {
                        // 重建图标对象以显示
                        let mut builder = TrayIconBuilder::new()
                            .with_id(crate::get_app_name().to_lowercase())
                            .with_menu(Box::new(tray_menu.clone()))
                            .with_tooltip(tooltip(0))
                            .with_icon(icon.clone())
                            .with_menu_on_left_click(false);
                        #[cfg(target_os = "macos")]
                        {
                            builder = builder.with_icon_as_template(true);
                        }
                        match builder.build() {
                            Ok(tray) => *tray_guard = Some(tray),
                            Err(err) => {
                                log::error!("Failed to create tray icon: {}", err);
                            }
                        }
                    }
                }
                _ => {}
            }
        }
    });
}

#[cfg(windows)]
#[tokio::main(flavor = "current_thread")]
async fn start_query_session_count(sender: std::sync::mpsc::Sender<Data>) {
    let mut last_count = 0;
    loop {
        if let Ok(mut c) = crate::ipc::connect(1000, "").await {
            let mut timer = crate::rustdesk_interval(tokio::time::interval(Duration::from_secs(1)));
            loop {
                tokio::select! {
                    res = c.next() => {
                        match res {
                            Err(err) => {
                                log::error!("ipc connection closed: {}", err);
                                break;
                            }

                            Ok(Some(Data::ControlledSessionCount(count))) => {
                                if count != last_count {
                                    last_count = count;
                                    sender.send(Data::ControlledSessionCount(count)).ok();
                                }
                            }
                            _ => {}
                        }
                    }

                    _ = timer.tick() => {
                        c.send(&Data::ControlledSessionCount(0)).await.ok();
                    }
                }
            }
        }
        hbb_common::sleep(1.).await;
    }
}

/// 强制刷新 Windows 系统托盘区域，避免图标隐藏后出现幽灵图标。
/// 通过向托盘窗口发送鼠标移动消息触发 Windows 重绘。
#[cfg(windows)]
fn refresh_tray_area() {
    use std::mem;
    use winapi::shared::windef::RECT;
    use winapi::um::winuser::{
        FindWindowExW, FindWindowW, GetClientRect, SendMessageW, WM_MOUSEMOVE,
    };

    unsafe {
        // 查找任务栏窗口
        let taskbar_hwnd = FindWindowW(encode_wide("Shell_TrayWnd").as_ptr(), std::ptr::null());
        if taskbar_hwnd.is_null() {
            log::warn!("Could not find taskbar window");
            return;
        }

        // 查找托盘通知区域
        let tray_hwnd = FindWindowExW(
            taskbar_hwnd,
            std::ptr::null_mut(),
            encode_wide("TrayNotifyWnd").as_ptr(),
            std::ptr::null(),
        );
        if tray_hwnd.is_null() {
            log::warn!("Could not find tray notification window");
            return;
        }

        // 获取托盘区域尺寸
        let mut rect: RECT = mem::zeroed();
        if GetClientRect(tray_hwnd, &mut rect) == 0 {
            log::warn!("Could not get tray rect");
            return;
        }

        // 遍历托盘区域发送鼠标移动消息，每 5 像素一个采样点
        let mut x = rect.left;
        while x < rect.right {
            let mut y = rect.top;
            while y < rect.bottom {
                let lparam = ((y as u32) << 16) | (x as u32);
                SendMessageW(tray_hwnd, WM_MOUSEMOVE, 0, lparam as isize);
                y += 5;
            }
            x += 5;
        }

        log::info!("Tray area refreshed");
    }
}

/// 将 UTF-8 字符串转换为 Windows API 所需的 UTF-16 宽字符，并添加 null 终止符。
#[cfg(windows)]
fn encode_wide(s: &str) -> Vec<u16> {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    OsStr::new(s).encode_wide().chain(Some(0)).collect()
}

/// 启动 IPC 服务器接收托盘控制消息，并转发到事件循环。
#[cfg(windows)]
fn start_ipc_listener(sender: std::sync::mpsc::Sender<Data>) {
    use hbb_common::futures::StreamExt;

    tokio::runtime::Runtime::new()
        .unwrap()
        .block_on(async move {
            if let Ok(mut incoming) = crate::ipc::new_listener("hide-tray").await {
                while let Some(Ok(stream)) = incoming.next().await {
                    let sender_clone = sender.clone();
                    tokio::spawn(async move {
                        let mut stream = crate::ipc::Connection::new(stream);
                        loop {
                            match stream.next().await {
                                Ok(Some(Data::HideTray(hide))) => {
                                    sender_clone.send(Data::HideTray(hide)).ok();
                                }
                                Ok(None) | Err(_) => break,
                                _ => {}
                            }
                        }
                    });
                }
            }
        });
}

fn load_icon_from_asset() -> Option<image::DynamicImage> {
    let Some(path) = std::env::current_exe().map_or(None, |x| x.parent().map(|x| x.to_path_buf()))
    else {
        return None;
    };
    #[cfg(target_os = "macos")]
    let path = path.join("../Frameworks/App.framework/Resources/flutter_assets/assets/icon.png");
    #[cfg(windows)]
    let path = path.join(r"data\flutter_assets\assets\icon.png");
    #[cfg(target_os = "linux")]
    let path = path.join(r"data/flutter_assets/assets/icon.png");
    if path.exists() {
        if let Ok(image) = image::open(path) {
            return Some(image);
        }
    }
    None
}
