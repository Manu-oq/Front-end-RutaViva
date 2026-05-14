import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../providers/chat_provider.dart';

class ChatInputField extends ConsumerStatefulWidget {
  const ChatInputField({super.key});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final created = await ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (created) {
      final itinerary = ref.read(itineraryProvider).current;
      if (itinerary == null) {
        return;
      }

      context.pushNamed(
        AppRouteNames.itineraryDetail,
        pathParameters: {'id': itinerary.id},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                controller: _controller,
                enabled: !_isSubmitting,
                onSubmitted: (_) => _submitMessage(),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu deseo...',
                  border: InputBorder.none,
                ),
              ),
            ),
            GestureDetector(
              onTap: _isSubmitting ? null : _submitMessage,
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
