import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final Map<String, BitmapDescriptor> _glowCache = {};

/// Create a circular glow bitmap with [diameter] logical pixels and [color].
/// Returns a cached BitmapDescriptor for repeated use.
Future<BitmapDescriptor> createGlowBitmap(Color color, int diameter) async {
  final key = '${color.value}-$diameter';
  if (_glowCache.containsKey(key)) return _glowCache[key]!;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final double DPR = ui.window.devicePixelRatio;
  final double px = diameter * DPR;

  // Draw transparent background
  final paint = Paint()..isAntiAlias = true;

  // Draw a soft circular glow using a blurred paint
  final center = Offset(px / 2, px / 2);
  final radius = px / 2;
  // Make the glow subtle (less opaque) so it works on light backgrounds
  paint.color = color.withOpacity(0.6);
  // Blur amount scaled by devicePixelRatio for consistent appearance
  paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * DPR);
  canvas.drawCircle(center, radius * 0.6, paint);

  final picture = recorder.endRecording();
  final img = await picture.toImage(px.toInt(), px.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final descriptor = BitmapDescriptor.fromBytes(bytes);
  _glowCache[key] = descriptor;
  return descriptor;
}
