import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/core/widgets/app_feedback.dart';

void main() {
  testWidgets('AppFeedbackBanner renders contextual error message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFeedbackBanner(
            message: 'La contraseña debe tener al menos 8 caracteres.',
          ),
        ),
      ),
    );

    expect(
      find.text('La contraseña debe tener al menos 8 caracteres.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('AppFeedbackBanner exposes retry action', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFeedbackBanner(
            message: 'No pudimos cargar los datos.',
            type: AppFeedbackType.warning,
            actionLabel: 'Reintentar',
            onAction: () => retryCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(retryCount, 1);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('AppFeedbackBanner renders success type with check icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFeedbackBanner(
            message: 'Perfil actualizado correctamente.',
            type: AppFeedbackType.success,
          ),
        ),
      ),
    );

    expect(find.text('Perfil actualizado correctamente.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('AppFeedbackBanner renders info type with info icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFeedbackBanner(
            message: 'Los alojamientos son sugerencias.',
            type: AppFeedbackType.info,
          ),
        ),
      ),
    );

    expect(find.text('Los alojamientos son sugerencias.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });

  testWidgets('AppFeedbackBanner supports onDismiss', (tester) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFeedbackBanner(
            message: 'Mensaje temporal.',
            type: AppFeedbackType.info,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(dismissed, isTrue);
  });
}
