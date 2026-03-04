import 'package:flutter/material.dart';
import 'dart:math' as math;

class FaceBoundBoxPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  FaceBoundBoxPainter({
    this.color = Colors.yellow,
    this.strokeWidth = 6.0,
    this.cornerLength = 32.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = StrokeCap.round;

    // final boxSize = math.min(size.width, size.height);
    // final left = (size.width - boxSize) ;
    // final top = (size.height - boxSize) ;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final tl = rect.topLeft;
    final tr = rect.topRight;
    final bl = rect.bottomLeft;
    final br = rect.bottomRight;

    canvas.drawLine(tl, tl + Offset(cornerLength, 0), paint);
    canvas.drawLine(tl, tl + Offset(0, cornerLength), paint);

    canvas.drawLine(tr, tr + Offset(-cornerLength, 0), paint);
    canvas.drawLine(tr, tr + Offset(0, cornerLength), paint);

    canvas.drawLine(bl, bl + Offset(cornerLength, 0), paint);
    canvas.drawLine(bl, bl + Offset(0, -cornerLength), paint);

    canvas.drawLine(br, br + Offset(-cornerLength, 0), paint);
    canvas.drawLine(br, br + Offset(0, -cornerLength), paint);
  }

  @override
  bool shouldRepaint(FaceBoundBoxPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength;
  }
}
