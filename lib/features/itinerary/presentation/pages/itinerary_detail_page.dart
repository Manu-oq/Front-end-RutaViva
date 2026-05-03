import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        leading: const BackButton(color: Colors.black),
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(itinerary.title, style: theme.textTheme.displayLarge),
              const SizedBox(height: 12),
              Text(
                'Ruta persistida en backend con ${itinerary.steps.length} paradas.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              for (final step in itinerary.steps) _GeneratedStep(step: step),
              const SizedBox(height: 16),
              const TrailIntelligenceBox(),
              const SizedBox(height: 100),
            ],
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aún no hay una ruta generada',
              style: theme.textTheme.displayLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Escribe una intención desde Inicio o Ara Assistant para generar un itinerario usando el backend.',
              style: theme.textTheme.bodyLarge,
            ),
          ],
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
        leading: const BackButton(color: Colors.black),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Itinerario')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se pudo cargar el itinerario',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('$error'),
          ],
        ),
      ),
    );
  }
}
