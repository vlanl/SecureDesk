import 'package:flutter/material.dart';

const sidebarColor = Color(0xFF0C6AF6);
const backgroundStartColor = Color(0xFFFAFBFC);
const backgroundEndColor = Color(0xFFFFFFFF);

class DesktopTitleBar extends StatelessWidget {
  final Widget? child;

  const DesktopTitleBar({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color(0xFF1E1E1E), Color(0xFF2A2A2A)]
                : [backgroundStartColor, backgroundEndColor],
            stops: [0.0, 1.0]),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF333333) : Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: child ?? Offstage(),
          )
        ],
      ),
    );
  }
}
