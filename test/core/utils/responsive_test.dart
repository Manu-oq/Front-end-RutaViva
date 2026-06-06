import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/core/utils/responsive.dart';

void main() {
  group('AppBreakpoints', () {
    test('mobile es 600', () {
      expect(AppBreakpoints.mobile, equals(600));
    });

    test('tablet es 900', () {
      expect(AppBreakpoints.tablet, equals(900));
    });
  });

  group('AppResponsive isMobile/isTablet/isDesktop', () {
    testWidgets('isMobile true cuando width < 600', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              expect(AppResponsive.isMobile(context), isTrue);
              expect(AppResponsive.isTablet(context), isFalse);
              expect(AppResponsive.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet true cuando width entre 600 y 899', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              expect(AppResponsive.isMobile(context), isFalse);
              expect(AppResponsive.isTablet(context), isTrue);
              expect(AppResponsive.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop true cuando width >= 900', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              expect(AppResponsive.isMobile(context), isFalse);
              expect(AppResponsive.isTablet(context), isFalse);
              expect(AppResponsive.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('AppResponsive.value', () {
    testWidgets('retorna mobile cuando width < 600', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              final result = AppResponsive.value<String>(
                context,
                mobile: 'mobile',
                desktop: 'desktop',
              );
              expect(result, equals('mobile'));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('retorna tablet cuando se provee y width 600-899', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              final result = AppResponsive.value<String>(
                context,
                mobile: 'mobile',
                tablet: 'tablet',
                desktop: 'desktop',
              );
              expect(result, equals('tablet'));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('maxContentWidth es infinity en mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              expect(
                AppResponsive.maxContentWidth(context),
                equals(double.infinity),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('cardRadius retorna 30 en desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              expect(AppResponsive.cardRadius(context), equals(30));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('AppResponsive isLandscape', () {
    testWidgets('retorna false en portrait (width < height)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              expect(AppResponsive.isLandscape(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('retorna true en landscape (width > height)', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            builder: (context) {
              expect(AppResponsive.isLandscape(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

class _TestHarness extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const _TestHarness({required this.builder});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: builder);
  }
}
