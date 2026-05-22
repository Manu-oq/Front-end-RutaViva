import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/core/widgets/app_feedback.dart';
import 'package:ruta_viva/core/widgets/inline_error_widget.dart';

void main() {
  testWidgets('InlineErrorWidget renders error message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InlineErrorWidget(
            message: 'No se pudo cargar.',
            onRetry: _noop,
          ),
        ),
      ),
    );

    expect(find.text('No se pudo cargar.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('InlineErrorWidget shows retry button', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InlineErrorWidget(
            message: 'Error de red.',
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(retryCount, equals(1));
  });

  testWidgets('InlineErrorWidget uses compact mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InlineErrorWidget(message: 'Error compacto.', onRetry: _noop),
        ),
      ),
    );

    final feedback = tester.widget<AppFeedbackBanner>(
      find.byType(AppFeedbackBanner),
    );
    expect(feedback.compact, isTrue);
  });
}

void _noop() {}
