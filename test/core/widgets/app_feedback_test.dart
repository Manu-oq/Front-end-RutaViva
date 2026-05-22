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
}
