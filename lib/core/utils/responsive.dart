import 'package:flutter/widgets.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
}

class AppResponsive {
  const AppResponsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? desktop;
    return desktop;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      tablet: const EdgeInsets.fromLTRB(20, 16, 20, 112),
      desktop: const EdgeInsets.fromLTRB(24, 20, 24, 120),
    );
  }

  static EdgeInsets compactPagePadding(BuildContext context) {
    return value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      tablet: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      desktop: const EdgeInsets.fromLTRB(24, 16, 24, 40),
    );
  }

  static double maxContentWidth(BuildContext context) {
    return value<double>(
      context,
      mobile: double.infinity,
      tablet: 760,
      desktop: 860,
    );
  }

  static double cardRadius(BuildContext context) {
    return value<double>(context, mobile: 22, tablet: 26, desktop: 30);
  }

  static double cardPadding(BuildContext context) {
    return value<double>(context, mobile: 16, tablet: 18, desktop: 20);
  }

  static bool get shouldReduceMotion {
    final binding = WidgetsBinding.instance.platformDispatcher;
    return binding.accessibilityFeatures.disableAnimations;
  }
}
