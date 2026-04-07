import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/chat_provider.dart';

class ChatInputField extends ConsumerWidget { 
  const ChatInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = TextEditingController(); 

    return GlassContainer(
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (value) {
                  ref.read(chatProvider.notifier).sendMessage(value);
                  controller.clear();
                },
                decoration: const InputDecoration(
                  hintText: "Escribe tu deseo...",
                  border: InputBorder.none,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(chatProvider.notifier).sendMessage(controller.text);
                controller.clear();
              },
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}