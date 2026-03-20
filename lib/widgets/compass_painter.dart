import 'package:flutter/material.dart'; // Required for UI drawing tools

class ClassicCompassNeedlePainter extends CustomPainter
{ // Draws a detailed 8-point compass rose
  @override
  void paint(Canvas canvas, Size size)
  { // Drawing logic
    final double w = size.width; // Width
    final double h = size.height; // Height
    final double cx = w / 2; // Center X
    final double cy = h / 2; // Center Y

    final Paint darkRed = Paint()..color = const Color(0xFFA71C1C)..style = PaintingStyle.fill; // Dark Red
    final Paint lightRed = Paint()..color = const Color(0xFFD32F2F)..style = PaintingStyle.fill; // Light Red
    final Paint darkLightBlue = Paint()..color = const Color(0xFF3B6985)..style = PaintingStyle.fill; // Dark Blue
    final Paint lightLightBlue = Paint()..color = const Color(0xFF548CA8)..style = PaintingStyle.fill; // Light Blue
    final Paint darkNavy = Paint()..color = const Color(0xFF112233)..style = PaintingStyle.fill; // Dark Navy
    final Paint lightNavy = Paint()..color = const Color(0xFF1D3557)..style = PaintingStyle.fill; // Light Navy
    final Paint ringPaint = Paint()..color = const Color(0xFF1D3557)..style = PaintingStyle.stroke..strokeWidth = 1.5; // Rings

    canvas.drawCircle(Offset(cx, cy), w / 2.2, ringPaint); // Outer ring
    canvas.drawCircle(Offset(cx, cy), w / 3.0, ringPaint..strokeWidth = 0.5); // Inner ring

    void drawTriangle(Canvas c, Paint p, Offset p1, Offset p2, Offset p3)
    { // Helper to draw a triangle
      Path path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close(); // Build path
      c.drawPath(path, p); // Draw it
    }

    canvas.save(); // Save state
    canvas.translate(cx, cy); // Move to center
    for (int i = 0; i < 4; i++)
    { // Loop to draw the 4 diagonal spikes
      canvas.rotate(45 * 3.14159 / 180); // Rotate 45 degrees
      drawTriangle(canvas, lightNavy, const Offset(0, 0), Offset(0, -w / 2.8), Offset(w / 16, 0)); // Right half
      drawTriangle(canvas, darkNavy, const Offset(0, 0), Offset(0, -w / 2.8), Offset(-w / 16, 0)); // Left half
      canvas.rotate(-45 * 3.14159 / 180); // Reset rotation
      canvas.rotate(90 * 3.14159 / 180); // Move to next quadrant
    }
    canvas.restore(); // Restore state

    canvas.save(); // Save state
    canvas.translate(cx, cy); // Move to center
    drawTriangle(canvas, lightNavy, const Offset(0, 0), Offset(w / 2.4, 0), Offset(0, -w / 12)); // East Top
    drawTriangle(canvas, darkNavy, const Offset(0, 0), Offset(w / 2.4, 0), Offset(0, w / 12)); // East Bottom
    drawTriangle(canvas, darkNavy, const Offset(0, 0), Offset(-w / 2.4, 0), Offset(0, -w / 12)); // West Top
    drawTriangle(canvas, lightNavy, const Offset(0, 0), Offset(-w / 2.4, 0), Offset(0, w / 12)); // West Bottom
    canvas.restore(); // Restore state

    canvas.save(); // Save state
    canvas.translate(cx, cy); // Move to center
    drawTriangle(canvas, darkRed, const Offset(0, 0), Offset(0, -w / 2.0), Offset(-w / 12, 0)); // North Left
    drawTriangle(canvas, lightRed, const Offset(0, 0), Offset(0, -w / 2.0), Offset(w / 12, 0)); // North Right
    drawTriangle(canvas, darkLightBlue, const Offset(0, 0), Offset(0, w / 2.0), Offset(-w / 12, 0)); // South Left
    drawTriangle(canvas, lightLightBlue, const Offset(0, 0), Offset(0, w / 2.0), Offset(w / 12, 0)); // South Right
    canvas.restore(); // Restore state

    canvas.drawCircle(Offset(cx, cy), w / 12, Paint()..color = Colors.white..style = PaintingStyle.fill); // Outer white
    canvas.drawCircle(Offset(cx, cy), w / 18, Paint()..color = const Color(0xFF1D3557)..style = PaintingStyle.fill); // Inner dark
    canvas.drawCircle(Offset(cx, cy), w / 35, Paint()..color = Colors.white..style = PaintingStyle.fill); // Center pin

    void drawText(Canvas c, String text, Offset offset)
    { // Helper to draw text perfectly centered
      TextSpan span = TextSpan(style: const TextStyle(color: Color(0xFF1D3557), fontSize: 14, fontWeight: FontWeight.bold), text: text); // Style
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr); // Painter
      tp.layout(); // Layout
      tp.paint(c, Offset(offset.dx - (tp.width / 2), offset.dy - (tp.height / 2))); // Paint
    }

    drawText(canvas, "N", Offset(cx, cy - w / 2.6)); // North
    drawText(canvas, "S", Offset(cx, cy + w / 2.6)); // South
    drawText(canvas, "E", Offset(cx + w / 2.6, cy)); // East
    drawText(canvas, "W", Offset(cx - w / 2.6, cy)); // West
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Static drawing
}