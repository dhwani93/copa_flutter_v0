import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Safe replacement for the deprecated `withOpacity`/`withValues` call.
  /// Returns a new color with the same RGB channels and the given opacity.
  Color withOpacitySafe(double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    final r = (this.r * 255).round();
    final g = (this.g * 255).round();
    final b = (this.b * 255).round();
    return Color.fromARGB(a, r, g, b);
  }
}
