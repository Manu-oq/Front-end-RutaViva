import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Ruta Viva identity: forest, moss, earth, mist and warm sun.
  static const Color forest = Color(0xFF0F3D2E);
  static const Color deepForest = Color(0xFF09251D);
  static const Color moss = Color(0xFF2F6B45);
  static const Color leaf = Color(0xFF4E9A62);
  static const Color mint = Color(0xFFE8F3EA);
  static const Color mist = Color(0xFFF4F7F1);
  static const Color cloud = Color(0xFFFFFFFF);
  static const Color earth = Color(0xFF7A5635);
  static const Color sun = Color(0xFFF2B84B);
  static const Color clay = Color(0xFFD98B5F);
  static const Color ink = Color(0xFF16211C);
  static const Color mutedInk = Color(0xFF5D6A61);

  // Backwards-compatible aliases used by older widgets.
  static const Color volcanicObsidian = ink;
  static const Color araucariaGreen = forest;
  static const Color lapislazuliBlue = Color(0xFF2F6F8F);
  static const Color copper = earth;
  static const Color paperWhite = mist;
  static const Color surfaceLow = Color(0xFFEAF0E7);
  static const Color surfaceLowest = cloud;

  static List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: deepForest.withValues(alpha: 0.08),
      blurRadius: 40,
      spreadRadius: -10,
      offset: const Offset(0, 18),
    ),
  ];

  static List<BoxShadow> liftedShadow = [
    BoxShadow(
      color: deepForest.withValues(alpha: 0.14),
      blurRadius: 30,
      spreadRadius: -14,
      offset: const Offset(0, 18),
    ),
  ];
}
