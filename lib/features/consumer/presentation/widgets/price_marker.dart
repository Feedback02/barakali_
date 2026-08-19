import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Renders a branded map pin (a rounded pill with a category icon + a price,
/// and a downward pointer) to a [BitmapDescriptor] for use as a custom Google
/// Maps marker. The default anchor (0.5, 1.0) puts the pointer tip on the
/// merchant's exact coordinate.
///
/// Drawn at [scale] (the device pixel ratio) for crispness, then handed back to
/// the plugin at logical size via `imagePixelRatio: scale`.
Future<BitmapDescriptor> buildPriceMarker({
  required String label,
  required IconData icon,
  required Color background,
  required Color foreground,
  required double scale,
}) async {
  // Logical layout constants (multiplied by [scale] when painting).
  const double fontSize = 13;
  const double iconSize = 15;
  const double padH = 9;
  const double padV = 6;
  const double gap = 4;
  const double pointer = 7;
  const double radius = 13;
  const double border = 2;

  final iconPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconSize * scale,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: foreground,
      ),
    ),
  )..layout();

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: label,
      style: TextStyle(
        fontSize: fontSize * scale,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    ),
  )..layout();

  const contentH = iconSize > fontSize ? iconSize : fontSize;
  final pillW = (padH * 2 + iconSize + gap) * scale + textPainter.width;
  final pillH = (padV * 2 + contentH) * scale;
  final totalH = pillH + pointer * scale;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final pillRect = Rect.fromLTWH(0, 0, pillW, pillH);
  final rrect = RRect.fromRectAndRadius(
    pillRect,
    Radius.circular(radius * scale),
  );

  // Soft drop shadow so the pin reads above the map tiles.
  canvas.drawShadow(
    Path()..addRRect(rrect),
    Colors.black.withValues(alpha: 0.4),
    3 * scale,
    true,
  );

  final bgPaint = Paint()..color = background;
  canvas.drawRRect(rrect, bgPaint);

  // Downward pointer triangle, centered on the pill's bottom edge.
  final cx = pillW / 2;
  final pointerPath = Path()
    ..moveTo(cx - pointer * scale, pillH - 1)
    ..lineTo(cx + pointer * scale, pillH - 1)
    ..lineTo(cx, pillH + pointer * scale)
    ..close();
  canvas.drawPath(pointerPath, bgPaint);

  // White hairline border for separation on busy tiles.
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = border * scale;
  canvas.drawRRect(rrect, borderPaint);

  final iconLeft = padH * scale;
  iconPainter.paint(canvas, Offset(iconLeft, (pillH - iconPainter.height) / 2));
  textPainter.paint(
    canvas,
    Offset(
      iconLeft + iconPainter.width + gap * scale,
      (pillH - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(pillW.ceil(), totalH.ceil());
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: scale,
  );
}
