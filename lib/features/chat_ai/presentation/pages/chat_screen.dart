import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_field.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final itineraryState = ref.watch(itineraryProvider);
    final theme = Theme.of(context);

    _scrollToBottom();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  const ChatHeader(),
                  if (itineraryState.current != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _LastItineraryBanner(
                        title: itineraryState.current!.title,
                        isLoading: itineraryState.isLoading,
                        onOpen: () => context.pushNamed(
                          AppRouteNames.itineraryDetail,
                          pathParameters: {'id': itineraryState.current!.id},
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ChatBubble(
                          message: msg.text,
                          isUser: msg.isUser,
                          isTyping: msg.isTyping,
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: ChatInputField(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LastItineraryBanner extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onOpen;

  const _LastItineraryBanner({
    required this.title,
    required this.isLoading,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        dense: true,
        leading: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.route_outlined, color: theme.colorScheme.primary),
        title: Text(
          isLoading ? 'Ara está generando una ruta...' : 'Última ruta generada',
          style: theme.textTheme.labelLarge,
        ),
        subtitle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: TextButton(
          onPressed: isLoading ? null : onOpen,
          child: const Text('Ver'),
        ),
      ),
    );
  }
}
