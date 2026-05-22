import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/skeleton_container.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../providers/itinerary_provider.dart';

class ItineraryHistoryPage extends ConsumerWidget {
  const ItineraryHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itineraries = ref.watch(itineraryHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRouteName: AppRouteNames.home),
        title: const Text('Mis itinerarios'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(itineraryHistoryProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surfaceContainerLow,
              theme.colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: itineraries.when(
          data: (items) {
            if (items.isEmpty) {
              return _EmptyItineraryHistory(
                onCreate: () => context.goNamed(AppRouteNames.home),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemBuilder: (context, index) {
                    final itinerary = items[index];
                    return _ItineraryCard(
                      itinerary: itinerary,
                      onDelete: () => _deleteItinerary(context, ref, itinerary),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemCount: items.length,
                ),
              ),
            );
          },
          loading: () => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemBuilder: (context, index) => const SkeletonContainer(
                  height: 142,
                  borderRadius: BorderRadius.all(Radius.circular(26)),
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemCount: 4,
              ),
            ),
          ),
          error: (error, stackTrace) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _HistoryStateCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'No se pudo cargar el historial',
                  text: '$error',
                  action: ElevatedButton.icon(
                    onPressed: () => ref.invalidate(itineraryHistoryProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItinerary(
    BuildContext context,
    WidgetRef ref,
    ItineraryModel itinerary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar itinerario'),
        content: Text(
          '¿Quieres eliminar "${itinerary.title}"? Esta ruta dejará de aparecer en tu historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(itineraryRepositoryProvider).deleteItinerary(itinerary.id);
      ref.read(itineraryProvider.notifier).clearCurrentIfMatches(itinerary.id);
      ref.invalidate(itineraryHistoryProvider);
      ref.invalidate(itineraryDetailProvider(itinerary.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Itinerario eliminado.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos eliminar el itinerario.')),
      );
    }
  }
}

class _ItineraryCard extends StatelessWidget {
  final ItineraryModel itinerary;
  final VoidCallback onDelete;

  const _ItineraryCard({required this.itinerary, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.ambientShadow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.pushNamedSafe(
          AppRouteNames.itineraryDetail,
          pathParameters: {'id': itinerary.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.route, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.title,
                          style: theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_dateRange(itinerary)} • ${itinerary.steps.length} paradas',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opciones de itinerario',
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (itinerary.steps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: itinerary.steps.take(4).map((step) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.42,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        step.poiNombre ?? 'Parada ${step.stepOrder}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange(ItineraryModel itinerary) {
    final start = itinerary.startDate;
    final end = itinerary.endDate;
    if (start == null || end == null) {
      return 'Sin fechas';
    }
    return '${_shortDate(start)} — ${_shortDate(end)}';
  }

  String _shortDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _EmptyItineraryHistory extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyItineraryHistory({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _HistoryStateCard(
            icon: Icons.route_outlined,
            title: 'Aún no tienes itinerarios guardados',
            text:
                'Genera una ruta desde Inicio o Ara Assistant y aparecerá aquí.',
            action: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar una ruta'),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Widget action;

  const _HistoryStateCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.primary,
            child: Icon(icon),
          ),
          const SizedBox(height: 18),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(text, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          action,
        ],
      ),
    );
  }
}
