// SecureDesk right panel — compact banner with night landscape
// Style: blue-toned night scene with jagged mountains, full moon, stars,
//        pine trees with visible trunks

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';

class SecureDeskRightPanel extends StatefulWidget {
  const SecureDeskRightPanel({Key? key}) : super(key: key);

  @override
  State<SecureDeskRightPanel> createState() => _SecureDeskRightPanelState();
}

class _SecureDeskRightPanelState extends State<SecureDeskRightPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Color(0xFF1565C0)).withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _LandscapePainter(isDark: isDark, anim: _glowController),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildPeerContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2)),
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
        color: isDark ? Color(0xFF1A2E3D) : Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF2C8CFF).withOpacity(0.30) : Color(0xFF90CAF9),
        ),
      ),
      child: Row(children: [
        Icon(Icons.shield_outlined, size: 30,
            color: isDark ? Color(0xFF64B5F6) : Color(0xFF1976D2)),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('\u7AEF\u5230\u7AEF\u52A0\u5BC6\u4FDD\u62A4\u60A8\u7684\u8FDE\u63A5',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? Color(0xFF90CAF9) : Color(0xFF1565C0))),
          SizedBox(height: 3),
          Text('\u8FDE\u63A5\u5DF2\u52A0\u5BC6\uFF0C\u6570\u636E\u901A\u8FC7\u5B89\u5168\u901A\u9053\u4F20\u8F93',
              style: TextStyle(fontSize: 10,
                  color: isDark ? Color(0xFF64B5F6).withOpacity(0.70) : Color(0xFF1976D2).withOpacity(0.70))),
        ])),
        Icon(Icons.lock_outline, size: 18,
            color: isDark ? Color(0xFF64B5F6).withOpacity(0.50) : Color(0xFF1976D2).withOpacity(0.50)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Landscape Painter — angular jagged peaks + full moon + stars + pine trees
// ══════════════════════════════════════════════════════════════════════════════

class _LandscapePainter extends CustomPainter {
  final bool isDark;
  final Animation<double> anim;

  _LandscapePainter({required this.isDark, required this.anim});

  @override
  bool shouldRepaint(covariant _LandscapePainter old) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Draw order: sky → stars → full moon glow → full moon → back mountain → front mountain → snow caps → trees → text
    _paintSky(canvas, w, h);
    _paintStars(canvas, w, h);
    _paintMoonGlow(canvas, w, h);
    _paintMoon(canvas, w, h);
    _paintBackMountain(canvas, w, h);
    _paintFrontMountain(canvas, w, h);
    _paintSnowCaps(canvas, w, h);
    _paintPineTrees(canvas, w, h);
    _paintText(canvas, w, h);
  }

  // ─── SKY ──────────────────────────────────────────────────────
  void _paintSky(Canvas c, double w, double h) {
    final shader = LinearGradient(
      begin: Alignment(-1.0, -1.0), end: Alignment(1.0, 1.0),
      colors: isDark
        ? [Color(0xFF1A3A5C), Color(0xFF143D60), Color(0xFF0D2840)]
        : [Color(0xFF42A5F5), Color(0xFF1E88E5), Color(0xFF1565C0)],
      stops: [0.0, 0.55, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()
      ..shader = shader
      ..style = PaintingStyle.fill);
  }

  // ─── STARS ────────────────────────────────────────────────────
  void _paintStars(Canvas c, double w, double h) {
    final bright = Paint()..color=Colors.white.withOpacity(isDark?0.50:0.65)..style=PaintingStyle.fill;
    final dim   = Paint()..color=Colors.white.withOpacity(isDark?0.18:0.25)..style=PaintingStyle.fill;
    // (x_ratio, y_ratio, radius)
    final data = <List<double>>[
      [0.18,0.07,1.15], [0.32,0.04,0.85], [0.48,0.09,0.95], [0.62,0.05,0.75],
      [0.25,0.17,0.55], [0.41,0.13,0.48], [0.56,0.16,0.62], [0.70,0.12,0.50],
      [0.34,0.24,0.38], [0.52,0.22,0.35], [0.66,0.21,0.42],
    ];
    for (final s in data)
      c.drawCircle(Offset(w*s[0],h*s[1]), s[2], s[2]>0.65?bright:dim);
  }

  // ─── FULL MOON GLOW ──────────────────────────────────────────
  void _paintMoonGlow(Canvas c, double w, double h) {
    final mx = w * 0.80, my = h * 0.22;
    final t = anim.value;
    final gr = 28 + t * 6;
    c.drawCircle(Offset(mx, my), gr, Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withOpacity(0.14 + t * 0.03),
        Colors.white.withOpacity(0.05),
        Colors.transparent,
      ], stops: [0.0, 0.55, 1.0])
        .createShader(Rect.fromCircle(center: Offset(mx, my), radius: gr)));
  }

  // ─── FULL MOON (circle, no crescent cutout) ──────────────────
  void _paintMoon(Canvas c, double w, double h) {
    final mx = w * 0.80, my = h * 0.22;
    // Full moon body — radial gradient for 3D sphere look
    final bodyGrad = RadialGradient(colors: [
      Color(0xFFFDFDFD),     // bright center
      Color(0xFFE8ECF1),     // mid-tone
      Color(0xFFCDD4DA),     // edge shadow
    ], stops: [0.0, 0.45, 1.0]);
    c.drawCircle(Offset(mx, my), 11.5, Paint()
      ..shader = bodyGrad.createShader(Rect.fromCircle(center: Offset(mx, my), radius: 11.5)));

    // Subtle crater texture — tiny faint dots on surface
    final craterP = Paint()..color=Colors.grey.withOpacity(0.08)..style=PaintingStyle.fill;
    c.drawCircle(Offset(mx - 2.8, my - 2.0), 1.8, craterP);
    c.drawCircle(Offset(mx + 2.2, my + 1.5), 1.3, craterP);
    c.drawCircle(Offset(mx - 0.5, my + 3.0), 1.0, craterP);
  }

  // ─── BACK MOUNTAIN (lighter, smaller angular peak) ───────────
  void _paintBackMountain(Canvas c, double w, double h) {
    // Angular polygon path — sharp ridges with straight line segments
    final path = Path()
      ..moveTo(w * 0.54, h)
      ..lineTo(w * 0.58, h * 0.58)       // left slope up
      ..lineTo(w * 0.63, h * 0.38)       // first ridge point
      ..lineTo(w * 0.68, h * 0.30)       // main peak top
      ..lineTo(w * 0.73, h * 0.36)       // right side of peak
      ..lineTo(w * 0.78, h * 0.44)       // secondary ridge
      ..lineTo(w * 0.84, h * 0.40)       // small bump
      ..lineTo(w * 0.90, h * 0.52)       // slope down
      ..lineTo(w * 0.96, h * 0.68)
      ..lineTo(w * 1.02, h)
      ..close();

    final shader = LinearGradient(
      begin: Alignment(0.0, -1.0), end: Alignment(0.0, 1.0),
      colors: isDark
        ? [Color(0xFF3A7CA5).withOpacity(0.48), Color(0xFF256083).withOpacity(0.42)]
        : [Color(0xFF81D4FA).withOpacity(0.52), Color(0xFF4FC3F7).withOpacity(0.44)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    c.drawPath(path, Paint()
      ..shader = shader
      ..style = PaintingStyle.fill);
  }

  // ─── FRONT MOUNTAIN (darker, larger dominant angular peak) ─────
  void _paintFrontMountain(Canvas c, double w, double h) {
    // Angular polygon — sharp edges, distinct facets
    final path = Path()
      ..moveTo(w * 0.62, h)
      ..lineTo(w * 0.66, h * 0.62)
      ..lineTo(w * 0.71, h * 0.46)
      ..lineTo(w * 0.76, h * 0.32)       // main sharp peak apex
      ..lineTo(w * 0.82, h * 0.38)       // steep right face
      ..lineTo(w * 0.87, h * 0.48)
      ..lineTo(w * 0.92, h * 0.56)
      ..lineTo(w * 0.98, h * 0.72)
      ..lineTo(w * 1.03, h)
      ..close();

    // Two-face shading: left facet lighter, right facet darker
    // Split at peak x = w * 0.76

    // Left facet (lighter — facing light source)
    final leftPath = Path()
      ..moveTo(w * 0.76, h * 0.32)         // peak apex
      ..lineTo(w * 0.71, h * 0.46)
      ..lineTo(w * 0.66, h * 0.62)
      ..lineTo(w * 0.62, h)
      ..lineTo(w * 0.76, h)                 // base center
      ..close();

    final leftGrad = LinearGradient(
      begin: Alignment(-1.0, -1.0), end: Alignment(0.5, 1.0),
      colors: isDark
        ? [Color(0xFF3B8DBF), Color(0xFF266A94)]
        : [Color(0xFF5BB8F5), Color(0xFF339BE5)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    c.drawPath(leftPath, Paint()..shader = leftGrad..style = PaintingStyle.fill);

    // Right facet (darker — shadowed side)
    final rightPath = Path()
      ..moveTo(w * 0.76, h * 0.32)         // peak apex
      ..lineTo(w * 0.82, h * 0.38)
      ..lineTo(w * 0.87, h * 0.48)
      ..lineTo(w * 0.92, h * 0.56)
      ..lineTo(w * 0.98, h * 0.72)
      ..lineTo(w * 1.03, h)
      ..lineTo(w * 0.76, h)                 // base center
      ..close();

    final rightGrad = LinearGradient(
      begin: Alignment(0.0, -1.0), end: Alignment(1.0, 0.5),
      colors: isDark
        ? [Color(0xFF21527A), Color(0xFF153A54)]
        : [Color(0xFF2589CC), Color(0xFF0D67AB)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    c.drawPath(rightPath, Paint()..shader = rightGrad..style = PaintingStyle.fill);

    // Ridge highlight line along the main peak edge
    c.drawLine(Offset(w * 0.76, h * 0.32), Offset(w * 0.66, h * 0.62), Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.06 : 0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke);
  }

  // ─── SNOW CAPS (white tips on angular peaks) ──────────────────
  void _paintSnowCaps(Canvas c, double w, double h) {
    final snowP = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.35 : 0.55)
      ..style = PaintingStyle.fill;

    // Back mountain snow cap — small triangle at its peak (x=0.68w, y=0.30h)
    final backCap = Path()
      ..moveTo(w * 0.66, h * 0.37)
      ..lineTo(w * 0.68, h * 0.30)
      ..lineTo(w * 0.71, h * 0.36)
      ..close();
    c.drawPath(backCap, snowP);

    // Front mountain snow cap — larger triangle at main peak (x=0.76w, y=0.32h)
    final frontSnow = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.42 : 0.60)
      ..style = PaintingStyle.fill;

    final frontCap = Path()
      ..moveTo(w * 0.73, h * 0.39)
      ..lineTo(w * 0.76, h * 0.32)           // peak apex
      ..lineTo(w * 0.80, h * 0.38)
      ..close();
    c.drawPath(frontCap, frontSnow);

    // Snow highlight streak down the sunlit left ridge
    c.drawLine(Offset(w * 0.74, h * 0.365), Offset(w * 0.69, h * 0.48), Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.15 : 0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  // ─── PINE TREES (3 trees with visible trunks) ────────────────
  void _paintPineTrees(Canvas c, double w, double h) {
    _drawPineTree(c, w, h, w * 0.66, h * 0.97, 0.60);   // left tree — smallest
    _drawPineTree(c, w, h, w * 0.77, h * 0.98, 0.78);   // middle tree
    _drawPineTree(c, w, h, w * 0.89, h * 0.99, 1.00);   // right tree — largest
  }

  /// Draw a single pine tree with visible trunk + 3-tier triangular canopy
  void _drawPineTree(Canvas c, double w, double h, double bx, double by, double scale) {
    final trunkH = h * 0.24 * scale;
    final trunkTopW = w * 0.005 * scale;
    final trunkBotW = w * 0.013 * scale;
    final canopyH = h * 0.40 * scale;
    final canopyW = w * 0.055 * scale;
    final topY = by - trunkH;

    // ── TRUNK (tapered rectangle, brown gradient) ──
    final trunkShader = LinearGradient(
      begin: Alignment(0.0, -1.0), end: Alignment(0.0, 1.0),
      colors: isDark
        ? [Color(0xFF6D5D4A), Color(0xFF4A3E30)]
        : [Color(0xFF8D7B63), Color(0xFF5E513D)],
    ).createShader(Rect.fromLTWH(bx - trunkBotW, topY, trunkBotW * 2, trunkH));
    c.drawPath(Path()
      ..moveTo(bx - trunkTopW, topY)
      ..lineTo(bx + trunkTopW, topY)
      ..lineTo(bx + trunkBotW, by)
      ..lineTo(bx - trunkBotW, by)
      ..close(), Paint()..shader = trunkShader..style = PaintingStyle.fill);

    // Trunk left-edge highlight
    c.drawLine(Offset(bx - trunkTopW, topY), Offset(bx - trunkBotW, by), Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke);

    final baseY = topY - canopyH * 0.02;

    final cDark  = isDark ? Color(0xFF1B5238) : Color(0xFF1B6B3E);
    final cMid   = isDark ? Color(0xFF246B44) : Color(0xFF278B50);
    final cLight = isDark ? Color(0xFF2D8856) : Color(0xFF35AB63);

    final fillPaint = (Color col) => Paint()..color = col..style = PaintingStyle.fill;

    // Tier 3 (bottom, largest)
    final t3h = canopyH * 0.42;
    c.drawPath(Path()
      ..moveTo(bx, baseY - t3h * 0.08)
      ..lineTo(bx - canopyW, baseY + t3h * 0.92)
      ..lineTo(bx + canopyW, baseY + t3h * 0.92)
      ..close(), fillPaint(cDark));

    // Tier 2 (middle)
    final t2h = canopyH * 0.34;
    final t2BaseY = baseY - t3h * 0.38;
    c.drawPath(Path()
      ..moveTo(bx, t2BaseY - t2h * 0.12)
      ..lineTo(bx - canopyW * 0.75, t2BaseY + t2h * 0.85)
      ..lineTo(bx + canopyW * 0.75, t2BaseY + t2h * 0.85)
      ..close(), fillPaint(cMid));

    // Tier 1 (top, smallest)
    final t1h = canopyH * 0.28;
    final t1BaseY = t2BaseY - t2h * 0.42;
    c.drawPath(Path()
      ..moveTo(bx, t1BaseY - t1h * 0.45)
      ..lineTo(bx - canopyW * 0.52, t1BaseY + t1h * 0.52)
      ..lineTo(bx + canopyW * 0.52, t1BaseY + t1h * 0.52)
      ..close(), fillPaint(cLight));
  }

  // ─── TEXT OVERLAY ─────────────────────────────────────────────
  void _paintText(Canvas c, double w, double h) {
    final titleTp = TextPainter(
      text: TextSpan(text:'Secure Remote Desktop', style: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3,
        color: isDark ? Colors.white : Color(0xFFFFFFFF),
        shadows: [Shadow(color: Colors.black.withOpacity(0.28), blurRadius: 8, offset: Offset(0,1))],
      )),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w * 0.50);
    titleTp.paint(c, Offset(w * 0.052, h * 0.19));

    final sub1Tp = TextPainter(
      text: TextSpan(text:'\u8F7B\u677E\u8FDC\u7A0B\uFF0C\u65E0\u9650\u8FDE\u63A5', style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: isDark ? Color(0xFFB3D9FF) : Color(0xFFE3F2FD).withOpacity(0.95),
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    sub1Tp.paint(c, Offset(w * 0.052, h * 0.40));

    final sub2Tp = TextPainter(
      text: TextSpan(text:'\u5B89\u5168\u3001\u5FEB\u901F\u3001\u7A33\u5B9A\u7684\u8FDC\u7A0B\u684C\u9762\u4F53\u9A8C', style: TextStyle(
        fontSize: 9.5, fontWeight: FontWeight.w400,
        color: isDark ? Color(0xFF90CAF9).withOpacity(0.75) : Color(0xFFBBDEFB).withOpacity(0.80),
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    sub2Tp.paint(c, Offset(w * 0.052, h * 0.54));

    // Version label — right-aligned below "Secure Remote Desktop" title
    final verTp = TextPainter(
      text: TextSpan(text:'V1.4.8', style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(isDark ? 0.50 : 0.65),
        letterSpacing: 0.5,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    // Right-align with the title's right edge (title starts at w*0.052)
    verTp.paint(c, Offset(w * 0.052 + titleTp.width - verTp.width, h * 0.40));
  }
}
