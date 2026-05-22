import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/skeleton_container.dart';
import '../../../chat_ai/presentation/providers/chat_provider.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../../weather/data/models/weather_forecast_model.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/cultural_insight_card.dart';
import '../widgets/itinerary_step_widget.dart';

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

class _ItineraryDetailBody extends ConsumerStatefulWidget {
  final ItineraryModel itinerary;

  const _ItineraryDetailBody({required this.itinerary});

  @override
  ConsumerState<_ItineraryDetailBody> createState() =>
      _ItineraryDetailBodyState();
}

class _ItineraryDetailBodyState extends ConsumerState<_ItineraryDetailBody> {
  late List<ItineraryStepModel> _steps;
  bool _showWeather = false;
  bool _isStartingStepReplacement = false;
  int _selectedDayIndex = 0;
  String? _feedbackMessage;
  AppFeedbackType _feedbackType = AppFeedbackType.error;

  @override
  void initState() {
    super.initState();
    _steps = [...widget.itinerary.steps];
  }

  @override
  void didUpdateWidget(covariant _ItineraryDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itinerary.id != widget.itinerary.id ||
        oldWidget.itinerary.steps != widget.itinerary.steps) {
      _steps = [...widget.itinerary.steps];
      _selectedDayIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _tripDays();
    final safeSelectedIndex = days.isEmpty
        ? 0
        : _selectedDayIndex.clamp(0, days.length - 1);
    final selectedDay = days.isEmpty ? null : days[safeSelectedIndex];
    final selectedSteps = selectedDay == null
        ? _steps
        : _stepsForDate(selectedDay);
    final outsideRangeSteps = _outsideRangeSteps(days);
    final isMobile = AppResponsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
        title: Text(
          _dateRangeLabel(widget.itinerary),
          style: theme.textTheme.labelLarge,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(itineraryDetailProvider(widget.itinerary.id));
        },
        child: SingleChildScrollView(
          padding: AppResponsive.value<EdgeInsets>(
            context,
            mobile: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            tablet: const EdgeInsets.fromLTRB(20, 8, 20, 104),
            desktop: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ItineraryHero(
                    itinerary: widget.itinerary,
                    stepsCount: _steps.length,
                    dateLabel: _dateRangeLabel(widget.itinerary),
                    onHistory: () =>
                        context.goNamed(AppRouteNames.itineraryHistory),
                    onMap: () async {
                      try {
                        final points = await ref.read(
                          itineraryPoisProvider(widget.itinerary.id).future,
                        );
                        ref
                            .read(mapProvider.notifier)
                            .showItineraryPois(
                              itineraryId: widget.itinerary.id,
                              points: points,
                            );
                        if (!context.mounted) return;
                        context.pushNamedSafe(
                          AppRouteNames.focusedMap,
                          extra: AppRouteNames.itineraryHistory,
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No pudimos cargar los lugares de esta ruta en el mapa.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  if (_feedbackMessage != null) ...[
                    SizedBox(height: isMobile ? 14 : 16),
                    AppFeedbackBanner(
                      message: _feedbackMessage!,
                      type: _feedbackType,
                      onDismiss: () => setState(() => _feedbackMessage = null),
                    ),
                  ],
                  SizedBox(height: isMobile ? 22 : 28),
                  Text('Recorrido sugerido', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                  _WeatherToggle(
                    isOpen: _showWeather,
                    onTap: () => setState(() => _showWeather = !_showWeather),
                  ),
                  if (_showWeather) ...[
                    const SizedBox(height: 12),
                    _WeatherDashboard(itinerary: widget.itinerary),
                  ],
                  const SizedBox(height: 22),
                  _DaySelector(
                    days: days,
                    labels: days.map(_dayChipLabel).toList(growable: false),
                    selectedIndex: safeSelectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedDayIndex = index),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DayHeader(
                          label: selectedDay == null
                              ? 'Recorrido'
                              : _fullDayLabel(selectedDay),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: selectedSteps.isEmpty
                            ? null
                            : () => _openSelectedDayOnMap(selectedSteps),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver día en mapa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (selectedSteps.isEmpty)
                    const _EmptyDayCard()
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedSteps.length,
                      onReorder: _onStepsReordered,
                      proxyDecorator: (child, index, animation) =>
                          _ReorderProxyDecorator(
                            animation: animation,
                            child: child,
                          ),
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final step = selectedSteps[index];
                        return _GeneratedStep(
                          key: ValueKey(step.id),
                          step: step,
                          onDelete: () => _deleteStep(step),
                          onChange: () => _changeStep(step),
                          onReschedule: () => _openRescheduleDialog(step),
                        );
                      },
                    ),
                  if (outsideRangeSteps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _OutOfRangeWarning(count: outsideRangeSteps.length),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime> _tripDays() {
    final start = widget.itinerary.startDate;
    final end = widget.itinerary.endDate;
    if (start != null && end != null && !end.isBefore(start)) {
      final startDay = _dateOnly(start);
      final endDay = _dateOnly(end);
      return List.generate(
        endDay.difference(startDay).inDays + 1,
        (index) => startDay.add(Duration(days: index)),
      );
    }

    final stepDays = _steps.map(_stepDay).whereType<DateTime>().toSet().toList()
      ..sort();
    return stepDays.isEmpty ? [_dateOnly(DateTime.now())] : stepDays;
  }

  List<ItineraryStepModel> _stepsForDate(DateTime day) {
    return _steps.where((step) {
      final stepDay = _stepDay(step);
      if (stepDay == null) return false;
      return _isSameDay(stepDay, day);
    }).toList()..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
  }

  List<ItineraryStepModel> _outsideRangeSteps(List<DateTime> days) {
    if (days.isEmpty) return const [];
    final first = days.first;
    final last = days.last;
    return _steps.where((step) {
      final day = _stepDay(step);
      if (day == null) return false;
      return day.isBefore(first) || day.isAfter(last);
    }).toList();
  }

  Future<void> _openSelectedDayOnMap(List<ItineraryStepModel> steps) async {
    setState(() => _feedbackMessage = null);
    try {
      final selectedIds = steps.map((step) => step.poiId).toSet();
      final points = await ref.read(
        itineraryPoisProvider(widget.itinerary.id).future,
      );
      final filtered = points
          .where((point) => selectedIds.contains(point.id))
          .toList(growable: false);
      ref
          .read(mapProvider.notifier)
          .showItineraryPois(
            itineraryId: widget.itinerary.id,
            points: filtered,
          );
      if (!mounted) return;
      context.pushNamedSafe(
        AppRouteNames.focusedMap,
        extra: AppRouteNames.itineraryHistory,
      );
    } catch (_) {
      if (!mounted) return;
      _showFeedback(
        'No pudimos cargar este día en el mapa. Intenta nuevamente.',
      );
    }
  }

  Future<void> _deleteStep(ItineraryStepModel step) async {
    setState(() => _feedbackMessage = null);
    try {
      final updated = await ref
          .read(itineraryRepositoryProvider)
          .deleteStep(itineraryId: widget.itinerary.id, stepId: step.id);
      if (!mounted) return;
      setState(() => _steps = [...updated.steps]);
      _invalidateItineraryData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Parada eliminada.')));
    } catch (error) {
      if (!mounted) return;
      _showFeedback('No pudimos eliminar la parada. Intenta nuevamente.');
    }
  }

  Future<void> _openRescheduleDialog(ItineraryStepModel step) async {
    final initialTime = step.arrivalTime != null
        ? TimeOfDay(
            hour: step.arrivalTime!.hour,
            minute: step.arrivalTime!.minute,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    final durationController = TextEditingController(
      text: step.recommendedDuration,
    );
    final result = await showDialog<_RescheduleResult>(
      context: context,
      builder: (ctx) => _RescheduleDialog(
        initialTime: initialTime,
        durationController: durationController,
      ),
    );
    durationController.dispose();
    if (result == null) return;
    final mins = int.tryParse(durationController.text.trim());
    await _rescheduleStep(step, result.time, mins);
  }

  Future<void> _changeStep(ItineraryStepModel step) async {
    if (_isStartingStepReplacement) {
      return;
    }
    setState(() => _isStartingStepReplacement = true);

    final center = ref.read(mapProvider).center;
    final start = widget.itinerary.startDate;
    final end = widget.itinerary.endDate;
    final prompt = 'Quiero cambiar la parada de ${step.title}.';

    try {
      await ref
          .read(chatProvider.notifier)
          .startSessionFromHome(
            initialMessage: prompt,
            center: center,
            radius: 10000,
            startDate: start,
            endDate: end,
            metadata: {
              'intent': 'change_itinerary_step',
              'itinerary_id': widget.itinerary.id,
              'step_id': step.id,
              'poi_id': step.poiId,
              'poi_name': step.title,
            },
          );
      if (!mounted) return;
      context.pushNamed('chat_focused');
    } finally {
      if (mounted) {
        setState(() => _isStartingStepReplacement = false);
      }
    }
  }

  void _invalidateItineraryData() {
    ref.invalidate(itineraryDetailProvider(widget.itinerary.id));
    ref.invalidate(itineraryPoisProvider(widget.itinerary.id));
    ref.invalidate(itineraryHistoryProvider);
  }

  Future<void> _rescheduleStep(
    ItineraryStepModel step,
    TimeOfDay arrivalTime,
    int? durationMinutes,
  ) async {
    setState(() => _feedbackMessage = null);
    final now = DateTime.now();
    final arrival = DateTime(
      now.year,
      now.month,
      now.day,
      arrivalTime.hour,
      arrivalTime.minute,
    );
    try {
      final updated = await ref
          .read(itineraryRepositoryProvider)
          .rescheduleStep(
            itineraryId: widget.itinerary.id,
            stepId: step.id,
            arrivalTime: arrival,
            durationMinutes: durationMinutes,
          );
      if (!mounted) return;
      setState(() => _steps = [...updated.steps]);
      _invalidateItineraryData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Horario actualizado.')));
    } catch (_) {
      if (!mounted) return;
      _showFeedback('No pudimos actualizar el horario. Intenta nuevamente.');
    }
  }

  void _onStepsReordered(int oldIndex, int newIndex) {
    final days = _tripDays();
    if (days.isEmpty) return;
    final safeSelected = _selectedDayIndex.clamp(0, days.length - 1);
    final day = days[safeSelected];
    final daySteps = _stepsForDate(day);
    if (oldIndex >= daySteps.length || newIndex >= daySteps.length) return;

    final actualNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final reorderedIds = daySteps.map((s) => s.id).toList();
    final movedId = reorderedIds.removeAt(oldIndex);
    reorderedIds.insert(actualNewIndex, movedId);

    setState(() {
      _steps = _steps.map((s) {
        final sDay = _stepDay(s);
        if (sDay != null && _isSameDay(sDay, day)) {
          final newPos = reorderedIds.indexOf(s.id);
          if (newPos >= 0) {
            return s.copyWith(stepOrder: newPos);
          }
        }
        return s;
      }).toList();
    });

    final payload = reorderedIds.asMap().entries.map((entry) {
      return {
        'step_id': entry.value,
        'day_index': safeSelected,
        'position': entry.key,
      };
    }).toList();

    unawaited(_saveReorder(payload));
  }

  Future<void> _saveReorder(List<Map<String, dynamic>> payload) async {
    setState(() => _feedbackMessage = null);
    try {
      final updated = await ref
          .read(itineraryRepositoryProvider)
          .reorderStepsWithTimes(
            itineraryId: widget.itinerary.id,
            steps: payload,
          );
      if (!mounted) return;
      setState(() => _steps = [...updated.steps]);
      _invalidateItineraryData();
    } catch (_) {
      if (!mounted) return;
      ref.invalidate(itineraryDetailProvider(widget.itinerary.id));
      _showFeedback('No pudimos guardar el orden. Revisa la conexión.');
    }
  }

  void _showFeedback(
    String message, {
    AppFeedbackType type = AppFeedbackType.error,
  }) {
    setState(() {
      _feedbackMessage = message;
      _feedbackType = type;
    });
  }

  String _dateRangeLabel(ItineraryModel itinerary) {
    if (itinerary.startDate == null || itinerary.endDate == null) {
      return 'ITINERARIO';
    }
    return '${_shortDate(itinerary.startDate!)} — ${_shortDate(itinerary.endDate!)}';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _fullDayLabel(DateTime date) {
    final backendLabel = _backendDayLabel(date);
    if (backendLabel != null) {
      return backendLabel;
    }
    return '${_weekdayName(date)} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _dayChipLabel(DateTime date) {
    final backendLabel = _backendDayLabel(date);
    if (backendLabel != null) {
      return backendLabel;
    }
    return '${_shortWeekdayName(date)} ${date.day}';
  }

  String? _backendDayLabel(DateTime date) {
    for (final step in _steps) {
      final label = step.dayLabel?.trim();
      if (label == null || label.isEmpty) continue;
      final stepDay = _stepDay(step);
      if (stepDay != null && _isSameDay(stepDay, date)) {
        return label;
      }
    }
    return null;
  }

  DateTime? _stepDay(ItineraryStepModel step) {
    final explicitDay = step.dayDate;
    if (explicitDay != null) {
      return _dateOnly(explicitDay);
    }
    final arrival = step.arrivalTime;
    if (arrival != null) {
      return _dateOnly(arrival);
    }
    return null;
  }

  String _weekdayName(DateTime date) {
    const names = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return names[date.weekday - 1];
  }

  String _shortWeekdayName(DateTime date) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[date.weekday - 1];
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
  final int? stepsCount;
  final VoidCallback onHistory;
  final VoidCallback onMap;

  const _ItineraryHero({
    required this.itinerary,
    required this.dateLabel,
    this.stepsCount,
    required this.onHistory,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppResponsive.cardRadius(context) + 4,
        ),
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
                label: '${stepsCount ?? itinerary.steps.length} paradas',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            itinerary.title,
            style:
                (isMobile
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.displayLarge)
                    ?.copyWith(
                      color: Colors.white,
                      fontSize: isMobile ? 28 : 40,
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
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile)
                FilledButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Abrir mapa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                )
              else
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
              SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 10 : 0),
              if (isMobile)
                OutlinedButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Ver historial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.42),
                    ),
                  ),
                )
              else
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

class _WeatherToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _WeatherToggle({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(isOpen ? Icons.expand_less_rounded : Icons.cloud_outlined),
      label: Text(isOpen ? 'Ocultar clima' : 'Revisar clima'),
    );
  }
}

class _WeatherDashboard extends ConsumerWidget {
  final ItineraryModel itinerary;

  const _WeatherDashboard({required this.itinerary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final start = itinerary.startDate ?? DateTime.now();
    final end = itinerary.endDate ?? start.add(const Duration(days: 2));
    final points = ref.watch(itineraryPoisProvider(itinerary.id));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clima del viaje',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pronóstico según las coordenadas principales de esta ruta.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          points.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No hay coordenadas para consultar clima.');
              }
              final first = items.first.coordinates;
              final forecast = ref.watch(
                weatherForecastProvider(
                  WeatherForecastRequest(
                    lat: first.latitude,
                    lon: first.longitude,
                    startDate: start,
                    endDate: end,
                  ),
                ),
              );
              return forecast.when(
                data: (days) {
                  if (days.isEmpty) {
                    return const Text('No hay pronóstico disponible.');
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < days.length; i++)
                        _WeatherDayCard(day: days[i], index: i),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(minHeight: 3),
                error: (error, stackTrace) =>
                    const Text('No pudimos cargar el clima para estos días.'),
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 3),
            error: (error, stackTrace) =>
                const Text('No pudimos leer los lugares de esta ruta.'),
          ),
        ],
      ),
    );
  }
}

class _WeatherDayCard extends StatelessWidget {
  final WeatherForecastDay day;
  final int index;

  const _WeatherDayCard({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxTemp = day.maxTempC?.round();
    final minTemp = day.minTempC?.round();
    final rain = day.precipitationProbability;
    return Container(
      width: 164,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wb_cloudy_outlined, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            day.label ?? 'Día ${index + 1}',
            style: theme.textTheme.labelLarge,
          ),
          Text(
            '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 8),
          Text(
            maxTemp == null
                ? 'Temperatura no disp.'
                : '${minTemp ?? maxTemp}° / $maxTemp°C',
          ),
          Text(
            rain == null
                ? '${day.precipitationMm?.toStringAsFixed(1) ?? '—'} mm lluvia'
                : '$rain% precipitaciones',
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<DateTime> days;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DaySelector({
    required this.days,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onSelected(index),
            label: Text(labels[index]),
            avatar: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.free_breakfast_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ara dejó este día libre para descanso, traslado o exploración espontánea.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutOfRangeWarning extends StatelessWidget {
  final int count;

  const _OutOfRangeWarning({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? 'Hay una parada con fecha fuera del rango del viaje.'
                  : 'Hay $count paradas con fecha fuera del rango del viaje.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;

  const _DayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

class _GeneratedStep extends StatelessWidget {
  final ItineraryStepModel step;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onReschedule;

  const _GeneratedStep({
    super.key,
    required this.step,
    required this.onDelete,
    required this.onChange,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final infoParts = <String>[
      if (step.recommendedDuration.isNotEmpty) step.recommendedDuration,
      if (step.poiNombre != null && step.poiNombre!.isNotEmpty) step.poiNombre!,
    ];
    final weather = step.aiContext?['weather'] as Map<String, dynamic>?;

    return ItineraryStepWidget(
      time: _stepTimeLabel(step),
      description: infoParts.join(' • '),
      child: CulturalInsightCard(
        label: step.title,
        text: step.tips.isNotEmpty
            ? '${step.reason}\n\nConsejo: ${step.tips}'
            : step.reason,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (weather != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StepWeatherChip(weather: weather),
              ),
            Wrap(
              spacing: 8,
              children: [
                ReorderableDragStartListener(
                  index: 0,
                  child: IconButton(
                    tooltip: 'Arrastrar para reordenar',
                    icon: const Icon(Icons.drag_handle_rounded),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: onReschedule,
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('Horario'),
                ),
                TextButton.icon(
                  onPressed: () => context.pushNamedSafe(
                    AppRouteNames.poiDetail,
                    pathParameters: {'id': step.poiId},
                  ),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Ver lugar'),
                ),
                TextButton.icon(
                  onPressed: onChange,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Cambiar lugar'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
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

class _StepWeatherChip extends StatelessWidget {
  final Map<String, dynamic> weather;

  const _StepWeatherChip({required this.weather});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = weather['description']?.toString() ?? '';
    final temp = weather['temperature_c'];
    final rain = weather['precipitation_probability'];
    final icon = _weatherIcon(description);
    final parts = <String>[
      if (temp != null) '${(temp as num).round()}°C',
      if (rain != null) '$rain% lluvia',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.14 : 0.7,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.leaf.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.leaf),
          const SizedBox(width: 6),
          if (parts.isNotEmpty)
            Flexible(
              child: Text(
                parts.join(' • '),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.deepForest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (description.isNotEmpty && parts.isNotEmpty)
            Text(
              ' — $description',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.deepForest.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  IconData _weatherIcon(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('lluvia') || lower.contains('rain')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('nube') || lower.contains('cloud')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('sol') ||
        lower.contains('sun') ||
        lower.contains('clear')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.cloud_outlined;
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
          constraints: BoxConstraints(
            maxWidth: AppResponsive.maxContentWidth(context),
          ),
          child: Padding(
            padding: AppResponsive.pagePadding(context),
            child: const _EmptyStateCard(
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
        padding: AppResponsive.pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SkeletonContainer(height: 28, width: 200),
                const SizedBox(height: 12),
                const SkeletonContainer(height: 14),
                const SizedBox(height: 40),
                ...List.generate(
                  4,
                  (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonContainer(height: 14, width: 140),
                        SizedBox(height: 12),
                        SkeletonContainer(
                          height: 90,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          constraints: BoxConstraints(
            maxWidth: AppResponsive.maxContentWidth(context),
          ),
          child: Padding(
            padding: AppResponsive.pagePadding(context),
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
    final isMobile = AppResponsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
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
          Text(
            title,
            style: isMobile
                ? theme.textTheme.titleLarge
                : theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: isMobile
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ReorderProxyDecorator extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const _ReorderProxyDecorator({required this.child, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(animation.value);
        return Transform.scale(
          scale: 1.0 + (value * 0.06),
          child: Material(
            elevation: 6,
            shadowColor: Theme.of(
              context,
            ).colorScheme.shadow.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(26),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _RescheduleResult {
  final TimeOfDay time;

  const _RescheduleResult({required this.time});
}

class _RescheduleDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final TextEditingController durationController;

  const _RescheduleDialog({
    required this.initialTime,
    required this.durationController,
  });

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Cambiar horario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.access_time_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text('${_time.format(context)} hs'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: const Text('Cambiar'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duracion (minutos, opcional)',
                hintText: 'Ej: 60',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_RescheduleResult(time: _time)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
