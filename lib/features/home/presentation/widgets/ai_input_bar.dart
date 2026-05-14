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
    context.pushNamed(
      AppRouteNames.itineraryDetail,
      pathParameters: {'id': itinerary.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itineraryState = ref.watch(itineraryProvider);

    return GlassContainer(
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !itineraryState.isLoading,
                  onSubmitted: (_) => _generate(),
                  decoration: InputDecoration(
                    hintText: '¿Qué quieres recorrer hoy?',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              tooltip: 'Generar ruta',
              onPressed: itineraryState.isLoading ? null : _generate,
              icon: itineraryState.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}
