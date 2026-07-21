import 'package:flutter/material.dart';

/// The four-bars-and-a-strike tally mark used as the app icon, redrawn as a
/// themeable vector icon (so it tints correctly for selected/unselected
/// states, e.g. in a [NavigationBar]) instead of using the raster app icon.
class TallyIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const TallyIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor = color ?? iconTheme.color ?? Colors.black;
    return CustomPaint(
      size: Size.square(resolvedSize),
      painter: _TallyPainter(color: resolvedColor),
    );
  }
}

class _TallyPainter extends CustomPainter {
  final Color color;

  _TallyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final barGap = size.width * 0.2;
    final top = size.height * 0.18;
    final bottom = size.height * 0.82;
    final startX = size.width * 0.5 - barGap * 1.5;

    for (var i = 0; i < 4; i++) {
      final x = startX + i * barGap;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }

    final strikeX0 = startX - barGap * 0.35;
    final strikeX1 = startX + barGap * 3 + barGap * 0.35;
    final strikeY0 = bottom + size.height * 0.05;
    final strikeY1 = top - size.height * 0.05;
    canvas.drawLine(
      Offset(strikeX0, strikeY0),
      Offset(strikeX1, strikeY1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TallyPainter oldDelegate) =>
      oldDelegate.color != color;
}
