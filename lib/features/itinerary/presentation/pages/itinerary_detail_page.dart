import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
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
import '../../data/models/itinerary_model.dart';
import '../../data/models/itinerary_reorder_payload.dart';
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
    final contentPadding = AppResponsive.value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      tablet: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      desktop: const EdgeInsets.fromLTRB(24, 8, 24, 32),
    );

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
        onRefresh: _refreshItinerary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                contentPadding.left,
                contentPadding.top,
                contentPadding.right,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _wrapContent(
                    context,
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
                  ),
                  if (!widget.itinerary.isEditable) ...[
                    const SizedBox(height: 14),
                    _wrapContent(
                      context,
                      _ReadOnlyItineraryBanner(isPast: widget.itinerary.isPast),
                    ),
                  ],
                  if (_feedbackMessage != null) ...[
                    SizedBox(height: isMobile ? 14 : 16),
                    _wrapContent(
                      context,
                      AppFeedbackBanner(
                        message: _feedbackMessage!,
                        type: _feedbackType,
                        onDismiss: () =>
                            setState(() => _feedbackMessage = null),
                      ),
                    ),
                  ],
                  SizedBox(height: isMobile ? 22 : 28),
                  _wrapContent(
                    context,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recorrido sugerido',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        _WeatherToggle(
                          isOpen: _showWeather,
                          onTap: () =>
                              setState(() => _showWeather = !_showWeather),
                        ),
                        if (_showWeather) ...[
                          const SizedBox(height: 12),
                          _WeatherDashboard(itinerary: widget.itinerary),
                        ],
                        const SizedBox(height: 22),
                        _DaySelector(
                          days: days,
                          labels: days
                              .map(_dayChipLabel)
                              .toList(growable: false),
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
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: contentPadding.left),
              sliver: selectedSteps.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 0,
                          right: 0,
                          bottom: 12,
                        ),
                        child: _wrapContent(context, const _EmptyDayCard()),
                      ),
                    )
                  : SliverReorderableList(
                      itemCount: selectedSteps.length,
                      onReorderItem: _onStepsReordered,
                      proxyDecorator: (child, index, animation) =>
                          _ReorderProxyDecorator(
                            animation: animation,
                            child: child,
                          ),
                      itemBuilder: (context, index) {
                        final step = selectedSteps[index];
                        return Padding(
                          key: ValueKey(step.id),
                          padding: EdgeInsets.only(
                            bottom: index == selectedSteps.length - 1 ? 0 : 10,
                          ),
                          child: _wrapContent(
                            context,
                            _GeneratedStep(
                              step: step,
                              dragIndex: index,
                              isEditable: widget.itinerary.isEditable,
                              onDelete: () => _deleteStep(step),
                              onChange: () => _changeStep(step),
                              onReschedule: () => _openRescheduleDialog(step),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                contentPadding.left,
                selectedSteps.isEmpty ? 0 : 12,
                contentPadding.right,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (outsideRangeSteps.isNotEmpty)
                    _wrapContent(
                      context,
                      _OutOfRangeWarning(count: outsideRangeSteps.length),
                    ),
                  SizedBox(height: contentPadding.bottom),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapContent(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppResponsive.maxContentWidth(context),
        ),
        child: child,
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
    if (!_ensureEditable()) return;
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
      _handleMutationError(
        error,
        fallback: 'No pudimos eliminar la parada. Intenta nuevamente.',
      );
    }
  }

  Future<void> _openRescheduleDialog(ItineraryStepModel step) async {
    if (!_ensureEditable()) return;
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
    if (!_ensureEditable()) return;
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

  Future<void> _refreshItinerary() async {
    ref.invalidate(itineraryDetailProvider(widget.itinerary.id));
    ref.invalidate(itineraryWeatherProvider(widget.itinerary.id));
    try {
      await ref.read(itineraryDetailProvider(widget.itinerary.id).future);
    } catch (error) {
      debugPrint(
        '[Itinerary] Refresh failed for ${widget.itinerary.id}: $error',
      );
    }
  }

  Future<void> _rescheduleStep(
    ItineraryStepModel step,
    TimeOfDay arrivalTime,
    int? durationMinutes,
  ) async {
    if (!_ensureEditable()) return;
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
    } catch (error) {
      if (!mounted) return;
      _handleMutationError(
        error,
        fallback: 'No pudimos actualizar el horario. Intenta nuevamente.',
      );
    }
  }

  void _onStepsReordered(int oldIndex, int newIndex) {
    if (!_ensureEditable()) return;
    final days = _tripDays();
    if (days.isEmpty) return;
    final safeSelected = _selectedDayIndex.clamp(0, days.length - 1);
    final day = days[safeSelected];
    final daySteps = _stepsForDate(day);
    if (oldIndex >= daySteps.length || newIndex > daySteps.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) {
      return;
    }

    final reorderedIds = daySteps.map((s) => s.id).toList();
    final movedId = reorderedIds.removeAt(oldIndex);
    reorderedIds.insert(newIndex, movedId);

    final nextSteps = _steps.map((s) {
      final sDay = _stepDay(s);
      if (sDay != null && _isSameDay(sDay, day)) {
        final newPos = reorderedIds.indexOf(s.id);
        if (newPos >= 0) {
          return s.copyWith(stepOrder: newPos + 1);
        }
      }
      return s;
    }).toList();

    setState(() => _steps = nextSteps);

    final payload = buildReorderWithTimesPayload(
      steps: nextSteps,
      dayIndexForStep: (step) => _dayIndexForStep(step, days),
    );

    unawaited(_saveReorder(payload));
  }

  int _dayIndexForStep(ItineraryStepModel step, List<DateTime> days) {
    final explicitDayIndex = step.dayIndex;
    if (explicitDayIndex != null && explicitDayIndex > 0) {
      return explicitDayIndex;
    }

    final stepDay = _stepDay(step);
    if (stepDay != null) {
      final dateIndex = days.indexWhere((day) => _isSameDay(day, stepDay));
      if (dateIndex >= 0) {
        return dateIndex + 1;
      }
    }

    return 1;
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
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(itineraryDetailProvider(widget.itinerary.id));
      _handleMutationError(
        error,
        fallback: 'No pudimos guardar el orden. Revisa la conexión.',
      );
    }
  }

  bool _ensureEditable() {
    if (widget.itinerary.isEditable) {
      return true;
    }
    _showReadOnlyFeedback();
    return false;
  }

  void _showReadOnlyFeedback() {
    _showFeedback(
      'Este itinerario ya no se puede editar.',
      type: AppFeedbackType.info,
    );
  }

  void _handleMutationError(Object error, {required String fallback}) {
    if (error is ApiException && error.statusCode == 409) {
      _showFeedback(error.message, type: AppFeedbackType.info);
      unawaited(_refreshItinerary());
      return;
    }
    _showFeedback(fallback);
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
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
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

class _ReadOnlyItineraryBanner extends StatelessWidget {
  final bool isPast;

  const _ReadOnlyItineraryBanner({required this.isPast});

  @override
  Widget build(BuildContext context) {
    return AppFeedbackBanner(
      type: AppFeedbackType.info,
      message: isPast
          ? 'Este itinerario ya pasó y solo está disponible para visualización.'
          : 'Este itinerario está disponible solo para visualización y ya no se puede editar.',
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
    final isWeatherNotApplicable =
        itinerary.isPast ||
        itinerary.status == 'completed' ||
        itinerary.status == 'cancelled';

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
            'Información dinámica por parada entregada por Ruta Viva.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (isWeatherNotApplicable)
            const _WeatherStatusMessage(
              icon: Icons.history_rounded,
              message:
                  'El clima ya no se consulta para itinerarios finalizados o pasados.',
            )
          else
            ref
                .watch(itineraryWeatherProvider(itinerary.id))
                .when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const _WeatherStatusMessage(
                        icon: Icons.cloud_off_outlined,
                        message: 'No se pudo cargar el clima en este momento.',
                      );
                    }
                    return _AdaptiveItineraryWeatherCards(items: items);
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 3),
                  error: (error, stackTrace) => const _WeatherStatusMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'No se pudo cargar el clima en este momento.',
                  ),
                ),
        ],
      ),
    );
  }
}

class _AdaptiveItineraryWeatherCards extends StatelessWidget {
  final List<ItineraryStepWeatherModel> items;

  const _AdaptiveItineraryWeatherCards({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardWidth = columns == 1
            ? availableWidth
            : (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _ItineraryWeatherCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _ItineraryWeatherCard extends StatelessWidget {
  final ItineraryStepWeatherModel item;

  const _ItineraryWeatherCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weather = item.weather;
    final isAvailable =
        item.weatherAvailable &&
        item.weatherStatus == 'available' &&
        weather != null;
    final statusMessage = _statusMessage(item);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAvailable
            ? theme.colorScheme.primary.withValues(alpha: 0.07)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAvailable
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvailable
                    ? _weatherIcon(weather.description ?? '')
                    : _statusIcon(item.weatherStatus),
                color: isAvailable
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.poiName ?? 'Parada',
                  style: theme.textTheme.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (item.dayDate != null) ...[
            const SizedBox(height: 4),
            Text(
              _shortDate(item.dayDate!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (isAvailable) ...[
            Text(weather.description ?? 'Clima disponible'),
            const SizedBox(height: 4),
            Text(
              [
                if (weather.temperatureC != null)
                  '${weather.temperatureC!.round()}°C',
                if (weather.precipitationProbability != null)
                  '${weather.precipitationProbability}% precipitaciones',
              ].join(' • '),
            ),
          ] else
            Text(
              statusMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }

  static String _statusMessage(ItineraryStepWeatherModel item) {
    final backendMessage = item.weatherMessage?.trim();
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }
    return switch (item.weatherStatus) {
      'out_of_range' =>
        'El pronóstico detallado estará disponible más cerca de la fecha del viaje.',
      'not_applicable' =>
        'El clima ya no se consulta para itinerarios finalizados o pasados.',
      'unavailable' => 'No se pudo cargar el clima en este momento.',
      _ => 'No se pudo cargar el clima en este momento.',
    };
  }

  static String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static IconData _statusIcon(String status) {
    return switch (status) {
      'out_of_range' => Icons.event_available_outlined,
      'not_applicable' => Icons.history_rounded,
      _ => Icons.cloud_off_outlined,
    };
  }

  static IconData _weatherIcon(String description) {
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
    return Icons.wb_cloudy_outlined;
  }
}

class _WeatherStatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _WeatherStatusMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
    final textScale = MediaQuery.textScalerOf(context).scale(14);
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWrap = constraints.maxWidth >= 520 || textScale > 18;
        final chips = List<Widget>.generate(days.length, (index) {
          final selected = index == selectedIndex;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onSelected(index),
            label: Text(
              labels[index],
              maxLines: useWrap ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            avatar: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary,
            ),
          );
        });

        if (useWrap) {
          return Wrap(spacing: 8, runSpacing: 8, children: chips);
        }

        final chipHeight = textScale.clamp(54.0, 72.0).toDouble();
        return SizedBox(
          height: chipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => chips[index],
          ),
        );
      },
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
  final int dragIndex;
  final bool isEditable;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onReschedule;

  const _GeneratedStep({
    required this.step,
    required this.dragIndex,
    required this.isEditable,
    required this.onDelete,
    required this.onChange,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final infoParts = <String>[
      if (step.recommendedDuration.isNotEmpty) step.recommendedDuration,
      if (step.poiName != null && step.poiName!.isNotEmpty) step.poiName!,
    ];

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
            Wrap(
              spacing: 8,
              children: [
                if (isEditable) ...[
                  ReorderableDragStartListener(
                    index: dragIndex,
                    child: IconButton(
                      tooltip: 'Arrastrar para reordenar',
                      icon: const Icon(Icons.drag_handle_rounded),
                      onPressed: () {},
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Horario'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => context.pushNamedSafe(
                    AppRouteNames.poiDetail,
                    pathParameters: {'id': step.poiId},
                  ),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Ver lugar'),
                ),
                if (isEditable) ...[
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
