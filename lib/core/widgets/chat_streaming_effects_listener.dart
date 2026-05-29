import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import '../../features/chat_ai/presentation/providers/chat_provider.dart';
import '../router/app_routes.dart';

class ChatStreamingEffectsListener extends ConsumerStatefulWidget {
  final Widget child;

  const ChatStreamingEffectsListener({super.key, required this.child});

  @override
  ConsumerState<ChatStreamingEffectsListener> createState() =>
      _ChatStreamingEffectsListenerState();
}

class _ChatStreamingEffectsListenerState
    extends ConsumerState<ChatStreamingEffectsListener> {
  bool _isNavigating = false;
  bool _isShowingNotification = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(chatPendingNavigationProvider, (previous, next) {
      if (!mounted ||
          _isNavigating ||
          _isShowingNotification ||
          next == null ||
          next == previous) {
        return;
      }
      unawaited(_showItineraryReadyNotification(context, next));
    });

    return widget.child;
  }

  Future<void> _showItineraryReadyNotification(
    BuildContext context,
    String itineraryId,
  ) async {
    _isShowingNotification = true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        duration: const Duration(seconds: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: const Row(
          children: [
            Icon(Icons.route_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itinerario listo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text('Ara terminó de armar tu ruta personalizada.'),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => unawaited(_navigateToItinerary(itineraryId)),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(chatProvider.notifier).consumePendingNavigation();
    });
    await controller.closed;
    if (mounted) {
      _isShowingNotification = false;
    }
  }

  Future<void> _navigateToItinerary(String itineraryId) async {
    _isNavigating = true;
    try {
      await ref
          .read(appRouterProvider)
          .pushNamed(
            AppRouteNames.itineraryDetail,
            pathParameters: {'id': itineraryId},
          );
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }
}
