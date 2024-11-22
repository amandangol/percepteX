import 'package:flutter/material.dart';

class HomeScreenBackground extends StatelessWidget {
  final Widget child;

  const HomeScreenBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle Geometric Overlays
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw abstract geometric shapes
    final path1 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(0, size.height * 0.4)
      ..lineTo(size.width * 0.4, size.height);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width, size.height * 0.2)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width, size.height * 0.8);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
