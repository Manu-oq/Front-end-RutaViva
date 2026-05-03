import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';

class AIInputBar extends ConsumerStatefulWidget {
  const AIInputBar({super.key});

  @override
  ConsumerState<AIInputBar> createState() => _AIInputBarState();
}

class _AIInputBarState extends ConsumerState<AIInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }

    final itinerary = await ref
        .read(itineraryProvider.notifier)
        .generate(query: query);

    if (!mounted) {
      return;
    }

    if (itinerary == null) {
      final message =
          ref.read(itineraryProvider).errorMessage ??
          'No se pudo generar la ruta.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    _controller.clear();
    context.goNamed(
      AppRouteNames.itineraryDetail,
      pathParameters: {'id': itinerary.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itineraryState = ref.watch(itineraryProvider);

    return GlassContainer(
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !itineraryState.isLoading,
                onSubmitted: (_) => _generate(),
                decoration: InputDecoration(
                  hintText: '¿A dónde quiere ir tu corazón?',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            GestureDetector(
              onTap: itineraryState.isLoading ? null : _generate,
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: itineraryState.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
