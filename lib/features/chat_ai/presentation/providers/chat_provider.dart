import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/message_entity.dart';

class ChatNotifier extends Notifier<List<MessageEntity>> {
  @override
  List<MessageEntity> build() {
    return [
      MessageEntity(
        text: "¡Hola! Soy Ara. ¿En qué rincón de la Araucanía quieres perderte hoy?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = MessageEntity(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];

    final typingIndicator = MessageEntity(
      text: "Ara está pensando...",
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    state = [...state, typingIndicator];


    await Future.delayed(const Duration(seconds: 2));


    state = state.where((m) => !m.isTyping).toList(); 
    
    final araResponse = MessageEntity(
      text: "He analizado tu deseo. Basado en la tranquilidad que buscas, te sugiero el sendero de la Cascada del Silencio. ¿Te gustaría ver la ruta?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    state = [...state, araResponse];
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<MessageEntity>>(ChatNotifier.new);