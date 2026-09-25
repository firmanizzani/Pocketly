import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(radius: radius ?? size * 0.24),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final u = s / 100;

    final bg = Paint()..color = const Color(0xFF10B981);
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = const Color(0xFF34D399);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, bg);

    white.strokeWidth = 7 * u;
    final arc = Path()
      ..moveTo(50 * u, 22 * u)
      ..arcTo(
        Rect.fromCircle(center: Offset(50 * u, 50 * u), radius: 28 * u),
        -1.5708,
        4.712,
        false,
      );
    canvas.drawPath(arc, white);

    canvas.drawLine(Offset(50 * u, 32 * u), Offset(50 * u, 68 * u), white);

    white.strokeWidth = 6.5 * u;
    final sPath = Path()
      ..moveTo(40 * u, 40 * u)
      ..cubicTo(40 * u, 36 * u, 44 * u, 34 * u, 50 * u, 34 * u)
      ..cubicTo(56 * u, 34 * u, 60 * u, 37 * u, 60 * u, 41 * u)
      ..cubicTo(60 * u, 46 * u, 54 * u, 48 * u, 50 * u, 50 * u)
      ..cubicTo(44 * u, 52 * u, 40 * u, 54 * u, 40 * u, 59 * u)
      ..cubicTo(40 * u, 64 * u, 44 * u, 66 * u, 50 * u, 66 * u)
      ..cubicTo(57 * u, 66 * u, 60 * u, 62 * u, 60 * u, 62 * u);
    canvas.drawPath(sPath, white);

    canvas.drawCircle(Offset(75 * u, 27 * u), 9 * u, dot);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
