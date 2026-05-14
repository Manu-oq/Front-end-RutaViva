import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/skeleton_container.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/cultural_insight_card.dart';
import '../widgets/itinerary_step_widget.dart';
import '../widgets/trail_intelligence_box.dart';

class ItineraryDetailPage extends ConsumerWidget {
  final String? itineraryId;

  const ItineraryDetailPage({super.key, this.itineraryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (itineraryId != null) {
      final itinerary = ref.watch(itineraryDetailProvider(itineraryId!));
      return itinerary.when(
        data: (value) => _ItineraryDetailBody(itinerary: value),
        loading: () => const _ItineraryDetailSkeleton(),
        error: (error, stackTrace) => _ItineraryDetailError(error: error),
      );
    }

    final itineraryState = ref.watch(itineraryProvider);
    if (itineraryState.isLoading) {
      return const _ItineraryDetailSkeleton();
    }

    final itinerary = itineraryState.current;
    if (itinerary == null) {
      return const _NoItineraryState();
    }

    return _ItineraryDetailBody(itinerary: itinerary);
  }
}

class _ItineraryDetailBody extends ConsumerWidget {
  final ItineraryModel itinerary;

  const _ItineraryDetailBody({required this.itinerary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
        title: Text(
          _dateRangeLabel(itinerary),
          style: theme.textTheme.labelLarge,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(itineraryDetailProvider(itinerary.id));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ItineraryHero(
                    itinerary: itinerary,
                    dateLabel: _dateRangeLabel(itinerary),
                    onHistory: () =>
                        context.goNamed(AppRouteNames.itineraryHistory),
                    onMap: () => context.goNamed(AppRouteNames.map),
                  ),
                  const SizedBox(height: 28),
                  Text('Recorrido sugerido', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                  for (final step in itinerary.steps)
                    _GeneratedStep(step: step),
                  const SizedBox(height: 6),
                  const TrailIntelligenceBox(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dateRangeLabel(ItineraryModel itinerary) {
    if (itinerary.startDate == null || itinerary.endDate == null) {
      return 'ITINERARIO';
    }
    return '${_shortDate(itinerary.startDate!)} — ${_shortDate(itinerary.endDate!)}';
  }

  String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _ItineraryHero extends StatelessWidget {
  final ItineraryModel itinerary;
  final String dateLabel;
  final VoidCallback onHistory;
  final VoidCallback onMap;

  const _ItineraryHero({
    required this.itinerary,
    required this.dateLabel,
    required this.onHistory,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: AppColors.liftedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(icon: Icons.calendar_today_outlined, label: dateLabel),
              _HeroPill(
                icon: Icons.place_outlined,
                label: '${itinerary.steps.length} paradas',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            itinerary.title,
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Una ruta armada para descubrir lugares, pausas y detalles locales a tu ritmo.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Abrir mapa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Ver historial',
                onPressed: onHistory,
                icon: const Icon(Icons.history),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedStep extends StatelessWidget {
  final ItineraryStepModel step;

  const _GeneratedStep({required this.step});

  @override
  Widget build(BuildContext context) {
    final infoParts = <String>[
      if (step.recommendedDuration.isNotEmpty) step.recommendedDuration,
      if (step.poiNombre != null && step.poiNombre!.isNotEmpty) step.poiNombre!,
    ];

    return ItineraryStepWidget(
      time: _stepTimeLabel(step),
      description: infoParts.join(' • '),
      child: CulturalInsightCard(
        label: step.title,
        text: step.tips.isNotEmpty
            ? '${step.reason}\n\nConsejo: ${step.tips}'
            : step.reason,
        action: TextButton.icon(
          onPressed: () => context.pushNamed(
            AppRouteNames.poiDetail,
            pathParameters: {'id': step.poiId},
          ),
          icon: const Icon(Icons.place_outlined),
          label: const Text('Ver lugar'),
        ),
      ),
    );
  }

  String _stepTimeLabel(ItineraryStepModel step) {
    final arrival = step.arrivalTime;
    if (arrival == null) {
      return 'Parada ${step.stepOrder}';
    }
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute — Parada ${step.stepOrder}';
  }
}

class _NoItineraryState extends StatelessWidget {
  const _NoItineraryState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _EmptyStateCard(
              icon: Icons.route_outlined,
              title: 'Aún no hay una ruta generada',
              text:
                  'Escribe una intención desde Inicio o Ara Assistant para generar un itinerario.',
            ),
          ),
        ),
      ),
    );
  }
}

class _ItineraryDetailSkeleton extends StatelessWidget {
  const _ItineraryDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SkeletonContainer(height: 28, width: 200),
            const SizedBox(height: 12),
            SkeletonContainer(height: 14),
            const SizedBox(height: 40),
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonContainer(height: 14, width: 140),
                    const SizedBox(height: 12),
                    SkeletonContainer(
                      height: 90,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryDetailError extends StatelessWidget {
  final Object error;

  const _ItineraryDetailError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
        title: const Text('Itinerario'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _EmptyStateCard(
              icon: Icons.warning_amber_rounded,
              title: 'No se pudo cargar el itinerario',
              text: '$error',
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.text,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }
}
