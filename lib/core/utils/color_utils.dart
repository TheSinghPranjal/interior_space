import 'package:flutter/material.dart';

class ColorUtils {
  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color fromHex(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }

  static Map<String, double> toHsl(Color color) {
    final r = color.r / 255;
    final g = color.g / 255;
    final b = color.b / 255;
    final max = [r, g, b].reduce((a, c) => a > c ? a : c);
    final min = [r, g, b].reduce((a, c) => a < c ? a : c);
    final l = (max + min) / 2;

    if (max == min) {
      return {'h': 0, 's': 0, 'l': l * 100};
    }

    final d = max - min;
    final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    double h;
    if (max == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h /= 6;

    return {'h': h * 360, 's': s * 100, 'l': l * 100};
  }
}
