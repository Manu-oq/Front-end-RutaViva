import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/chat_ai/domain/entities/message_entity.dart';
import 'package:ruta_viva/features/chat_ai/presentation/widgets/chat_bubble.dart';

void main() {
  testWidgets(
    'ChatBubble does not render quick reply chips when actions empty',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'Encontré opciones para Villarrica.',
              isUser: false,
              actions: [],
            ),
          ),
        ),
      );

      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('Encontré opciones para Villarrica.'), findsOneWidget);
    },
  );

  testWidgets('ChatBubble renders quick reply label instead of prompt', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatBubble(
            message: '¿Qué hacemos ahora?',
            isUser: false,
            actions: [
              MessageAction(
                id: 'more',
                label: 'Buscar más opciones',
                prompt: 'buscar_mas',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Buscar más opciones'), findsOneWidget);
    expect(find.text('buscar_mas'), findsNothing);
  });

  testWidgets('ChatBubble shows unknown evidence indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatBubble(
            message: 'No tengo ese dato confirmado.',
            isUser: false,
            evidenceLevel: 'unknown',
          ),
        ),
      ),
    );

    expect(find.text('Dato no confirmado'), findsOneWidget);
  });

  testWidgets('ChatBubble keeps long Ara text untruncated', (tester) async {
    const text =
        '¡Dale! Villarrica es ideal para familias. Encontré varias opciones cerca del lago. '
        'También puedo considerar actividades tranquilas y tiempos de descanso. '
        'Si querés, puedo armar todo de una con esas preferencias.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ChatBubble(message: text, isUser: false),
          ),
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(text));
    expect(textWidget.maxLines, isNull);
    expect(textWidget.overflow, isNull);
  });

  testWidgets(
    'ChatBubble muestra pista de scroll cuando llegan más de 3 POIs',
    (tester) async {
      final pois = List.generate(
        5,
        (index) => MessageCandidatePoi(
          id: 'poi-$index',
          name: 'POI ${index + 1}',
          categoryIds: const [1],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: ChatBubble(
                  message: 'Te dejo varias opciones.',
                  isUser: false,
                  candidatePois: pois,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('5 opciones recomendadas'), findsOneWidget);
      expect(find.text('Desliza para ver más opciones'), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);
    },
  );

  testWidgets(
    'ChatBubble no muestra pista de scroll cuando hay 3 POIs o menos',
    (tester) async {
      final pois = List.generate(
        3,
        (index) => MessageCandidatePoi(
          id: 'poi-$index',
          name: 'POI ${index + 1}',
          categoryIds: const [1],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: ChatBubble(
                  message: 'Te dejo varias opciones.',
                  isUser: false,
                  candidatePois: pois,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('3 opciones recomendadas'), findsOneWidget);
      expect(find.text('Desliza para ver más opciones'), findsNothing);
      expect(find.byType(Scrollbar), findsNothing);
    },
  );
}
