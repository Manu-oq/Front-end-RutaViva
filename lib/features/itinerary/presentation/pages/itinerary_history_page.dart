import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/skeleton_container.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';

class ItineraryHistoryPage extends ConsumerWidget {
  const ItineraryHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itineraries = ref.watch(itineraryHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis itinerarios'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(itineraryHistoryProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: itineraries.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyItineraryHistory(
              onCreate: () => context.goNamed(AppRouteNames.home),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemBuilder: (context, index) {
              final itinerary = items[index];
              return _ItineraryCard(itinerary: itinerary);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemBuilder: (context, index) => SkeletonContainer(
            height: 120,
            borderRadius: const BorderRadius.all(Radius.circular(22)),
          ),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: 4,
        ),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No se pudo cargar el historial',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('$error', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(itineraryHistoryProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  final ItineraryModel itinerary;

  const _ItineraryCard({required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.pushNamed(
          AppRouteNames.itineraryDetail,
          pathParameters: {'id': itinerary.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itinerary.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_dateRange(itinerary)} • ${itinerary.steps.length} paradas • ${itinerary.status}',
                style: theme.textTheme.bodySmall,
              ),
              if (itinerary.steps.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: itinerary.steps.take(3).map((step) {
                    return Chip(
                      label: Text(step.poiNombre ?? 'Parada ${step.stepOrder}'),
                      visualDensity: VisualDensity.compact,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.route_outlined,
            size: 52,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes itinerarios guardados',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Genera una ruta desde Inicio o Ara Assistant. El backend la persistirá y aparecerá aquí.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar una ruta'),
          ),
        ],
      ),
    );
  }
}
