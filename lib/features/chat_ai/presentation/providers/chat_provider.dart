import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../domain/entities/message_entity.dart';

class ChatNotifier extends Notifier<List<MessageEntity>> {
  @override
  List<MessageEntity> build() {
    return [
      MessageEntity(
        text:
            '¡Hola! Soy Ara. Cuéntame qué tipo de recorrido quieres hacer hoy.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return false;
    }

    final userMessage = MessageEntity(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];

    final typingIndicator = MessageEntity(
      text: 'Ara está preparando una ruta para ti...',
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    state = [...state, typingIndicator];

    final itinerary = await ref
        .read(itineraryProvider.notifier)
        .generate(query: text);

    state = [
      for (final message in state)
        if (!identical(message, typingIndicator)) message,
    ];

    if (itinerary == null) {
      final errorMessage =
          ref.read(itineraryProvider).errorMessage ??
          'No pude generar la ruta. Revisa tu sesión o intenta con otra búsqueda.';
      state = [
        ...state,
        MessageEntity(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
      return false;
    }

    final araResponse = MessageEntity(
      text:
          'Listo. Generé “${itinerary.title}” con ${itinerary.steps.length} paradas para explorar.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = [...state, araResponse];
    return true;
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<MessageEntity>>(
  ChatNotifier.new,
);
