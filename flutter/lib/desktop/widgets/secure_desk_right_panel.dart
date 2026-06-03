// SecureDesk right panel - decorative banner + real PeerTabPage + security tip

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';

class SecureDeskRightPanel extends StatefulWidget {
  const SecureDeskRightPanel({Key? key}) : super(key: key);

  @override
  State<SecureDeskRightPanel> createState() => _SecureDeskRightPanelState();
}

class _SecureDeskRightPanelState extends State<SecureDeskRightPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildBanner(context),
          Expanded(child: _buildPeerContent(context)),
          _buildSecurityTip(context),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1B3A2D), Color(0xFF0F2B1F)]
              : [Color(0xFFE8F5EB), Color(0xFFCDE8D3)],
        ),
      ),
      child: Stack(
        children: [
          // Clouds - positioned between text (left side) and sun (right side), vertically in mid-banner
          Positioned(
            left: 175,
            top: 18,
            child: _buildCloud(36, 16, Colors.white.withOpacity(0.88)),
          ),
          Positioned(
            left: 220,
            top: 32,
            child: _buildCloud(28, 12, Colors.white.withOpacity(0.7)),
          ),
          // Decorative nature elements - trees and hills (near to far)
          Positioned(
            right: 30,
            bottom: 0,
            child: _buildTree(45, Color(0xFF2E7D32).withOpacity(0.45)),
          ),
          Positioned(
            right: 65,
            bottom: 0,
            child: _buildTree(32, Color(0xFF388E3C).withOpacity(0.38)),
          ),
          Positioned(
            right: 90,
            bottom: 0,
            child: _buildTree(38, Color(0xFF43A047).withOpacity(0.32)),
          ),
          // Near hill (darker, bigger)
          Positioned(
            right: -10,
            bottom: -2,
            child: _buildHill(110, 42, Color(0xFF4CAF50).withOpacity(0.28)),
          ),
          // Far hill (lighter, smaller)
          Positioned(
            right: 50,
            bottom: -2,
            child: _buildHill(80, 30, Color(0xFF81C784).withOpacity(0.18)),
          ),
          // Sun with pulse animation
          Positioned(
            right: 22,
            top: 10,
            child: _buildSun(),
          ),
          // Floating leaves
          Positioned(
            left: 12,
            bottom: 8,
            child: Icon(Icons.eco, size: 22,
                color: isDark
                    ? Colors.green.shade300.withOpacity(0.7)
                    : Colors.green.shade700.withOpacity(0.5)),
          ),
          Positioned(
            left: 42,
            top: 16,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(Icons.spa, size: 16,
                  color: isDark
                      ? Colors.green.shade200.withOpacity(0.4)
                      : Colors.green.shade600.withOpacity(0.3)),
            ),
          ),
          // Text content
          Positioned(
            left: 20,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '轻松远程，无限连接',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.green.shade200 : Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '安全、快速、稳定的远程桌面体验',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.green.shade300.withOpacity(0.8)
                        : Color(0xFF2E7D32).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSun() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.15);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFFF59D).withOpacity(0.95),
                  Color(0xFFFFF176).withOpacity(0.6),
                  Color(0xFFFFD54F).withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: [0.2, 0.4, 0.7, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloud(double width, double height, Color color) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CloudPainter(color),
    );
  }

  Widget _buildTree(double height, Color color) {
    return CustomPaint(
      size: Size(height * 0.5, height),
      painter: _TreePainter(color),
    );
  }

  Widget _buildHill(double width, double height, Color color) {
    return CustomPaint(
      size: Size(width, height),
      painter: _HillPainter(color),
    );
  }

  Widget _buildPeerContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: const PeerTabPage(),
    );
  }

  Widget _buildSecurityTip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A2E1A) : Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF2E7D32).withOpacity(0.3) : Color(0xFFA5D6A7),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 30,
              color: isDark ? Color(0xFF66BB6A) : Color(0xFF43A047)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '端到端加密保护您的连接',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Color(0xFFA5D6A7) : Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '连接已加密，数据通过安全通道传输',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? Color(0xFF81C784).withOpacity(0.7)
                        : Color(0xFF388E3C).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.eco, size: 18,
              color: isDark
                  ? Color(0xFF66BB6A).withOpacity(0.5)
                  : Color(0xFF43A047).withOpacity(0.5)),
        ],
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final Color color;

  _CloudPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final r = h * 0.45;

    // Main cloud body - overlapping circles
    canvas.drawCircle(Offset(w * 0.35, h * 0.55), r, paint);
    canvas.drawCircle(Offset(w * 0.55, h * 0.35), r * 1.15, paint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.5), r * 0.85, paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), r * 0.7, paint);

    // Smooth bottom
    final bottomPath = Path();
    bottomPath.moveTo(w * 0.1, h * 0.7);
    bottomPath.quadraticBezierTo(w * 0.3, h * 1.05, w * 0.55, h * 0.7);
    bottomPath.quadraticBezierTo(w * 0.7, h * 0.95, w * 0.85, h * 0.65);
    bottomPath.quadraticBezierTo(w * 0.9, h * 0.7, w * 0.9, h * 0.7);
    bottomPath.lineTo(w * 0.1, h * 0.7);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TreePainter extends CustomPainter {
  final Color color;

  _TreePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final trunkPaint = Paint()
      ..color = Color(0xFF5D4037).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Trunk
    final trunkPath = Path();
    trunkPath.moveTo(size.width * 0.45, size.height);
    trunkPath.lineTo(size.width * 0.55, size.height);
    trunkPath.lineTo(size.width * 0.52, size.height * 0.4);
    trunkPath.lineTo(size.width * 0.48, size.height * 0.4);
    trunkPath.close();
    canvas.drawPath(trunkPath, trunkPaint);

    // Foliage - three layers
    final foliagePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Bottom layer
    final bottomPath = Path();
    bottomPath.moveTo(size.width * 0.1, size.height * 0.55);
    bottomPath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.2,
        size.width * 0.9, size.height * 0.55);
    bottomPath.lineTo(size.width * 0.1, size.height * 0.55);
    bottomPath.close();
    canvas.drawPath(bottomPath, foliagePaint);

    // Middle layer
    final middlePath = Path();
    middlePath.moveTo(size.width * 0.15, size.height * 0.4);
    middlePath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.05,
        size.width * 0.85, size.height * 0.4);
    middlePath.lineTo(size.width * 0.15, size.height * 0.4);
    middlePath.close();
    canvas.drawPath(middlePath, foliagePaint..color = color.withOpacity(0.8));

    // Top layer
    final topPath = Path();
    topPath.moveTo(size.width * 0.25, size.height * 0.25);
    topPath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.0,
        size.width * 0.75, size.height * 0.25);
    topPath.lineTo(size.width * 0.25, size.height * 0.25);
    topPath.close();
    canvas.drawPath(topPath, foliagePaint..color = color.withOpacity(0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HillPainter extends CustomPainter {
  final Color color;

  _HillPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
        size.width * 0.3, size.height * 0.3,
        size.width * 0.6, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.8, size.height * 0.7,
        size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
