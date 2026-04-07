import 'package:flutter/material.dart';

class AppColors {
  static const Color volcanicObsidian = Color(0xFF1A1A1B);
  static const Color araucariaGreen = Color(0xFF2D5A27);
  static const Color lapislazuliBlue = Color(0xFF00468B);
  static const Color copper = Color(0xFFB87333);
  static const Color paperWhite = Color(0xFFF9F9F9);
  static const Color surfaceLow = Color(0xFFF3F3F3);
  static const Color surfaceLowest = Color(0xFFFFFFFF);

  static List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: volcanicObsidian.withValues(alpha: 0.04),
      blurRadius: 60,
      spreadRadius: -5,
      offset: const Offset(0, 10),
    ),
  ];
}