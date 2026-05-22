import 'responsive.dart';

class AppDurations {
  const AppDurations._();

  static final Duration short = AppResponsive.shouldReduceMotion
      ? Duration.zero
      : const Duration(milliseconds: 150);

  static final Duration medium = AppResponsive.shouldReduceMotion
      ? Duration.zero
      : const Duration(milliseconds: 200);

  static final Duration long = AppResponsive.shouldReduceMotion
      ? Duration.zero
      : const Duration(milliseconds: 300);

  static final Duration scroll = AppResponsive.shouldReduceMotion
      ? Duration.zero
      : const Duration(milliseconds: 250);
}
