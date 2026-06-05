import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../chat_ai/presentation/providers/chat_provider.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../map/domain/entities/map_point.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../providers/itinerary_provider.dart';
import '../providers/itinerary_detail_notifier.dart';
import '../widgets/day_drop_section.dart';
import '../widgets/day_selector.dart';
import '../widgets/generated_step.dart';
import '../widgets/inter_day_drag_drawer.dart';
import '../widgets/itinerary_info_banners.dart';
import '../widgets/itinerary_detail_error.dart';
import '../widgets/itinerary_detail_skeleton.dart';
import '../widgets/itinerary_hero.dart';
import '../widgets/reschedule_dialog.dart';
import '../widgets/weather_section.dart';

class ItineraryDetailPage extends ConsumerWidget {
  final String? itineraryId;

  const ItineraryDetailPage({super.key, this.itineraryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (itineraryId != null) {
      final itinerary = ref.watch(itineraryDetailProvider(itineraryId!));
      return itinerary.when(
        data: (value) => _ItineraryDetailBody(itinerary: value),
        loading: () => const ItineraryDetailSkeleton(),
        error: (error, stackTrace) => ItineraryDetailError(error: error),
      );
    }

    final itineraryState = ref.watch(itineraryProvider);
    if (itineraryState.isLoading) {
      return const ItineraryDetailSkeleton();
    }

    final itinerary = itineraryState.current;
    if (itinerary == null) {
      return const NoItineraryState();
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
  late ItineraryDetailController _controller;
  late ItineraryDetailState _state;
  DateTime? _selectedDay;
  int _daySelectorResetRevision = 0;
  bool _isDraggingStep = false;
  DateTime? _draggingFromDay;

  @override
  void initState() {
    super.initState();
    _controller = ItineraryDetailController(ref, widget.itinerary);
    _state = _controller.initialState;
    final days = _controller.tripDays(_state.steps);
    _selectedDay = days.isEmpty ? null : days.first;
  }

  @override
  void didUpdateWidget(covariant _ItineraryDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itinerary.id != widget.itinerary.id ||
        oldWidget.itinerary.steps != widget.itinerary.steps) {
      _controller = ItineraryDetailController(ref, widget.itinerary);
      setState(() {
        _state = _controller.initialState;
        final days = _controller.tripDays(_state.steps);
        _selectedDay = days.isEmpty ? null : days.first;
        _isDraggingStep = false;
        _draggingFromDay = null;
        _daySelectorResetRevision++;
      });
    }
  }

  void _emit(ItineraryDetailState next) => setState(() => _state = next);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _controller.tripDays(_state.steps);
    final outsideSteps = _controller.outsideRangeSteps(_state.steps, days);
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
          dateRangeLabel(widget.itinerary),
          style: theme.textTheme.labelLarge,
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscapeBody(
              context,
              days,
              outsideSteps,
              isMobile,
              contentPadding,
            );
          }
          return _buildPortraitBody(
            context,
            days,
            outsideSteps,
            isMobile,
            contentPadding,
          );
        },
      ),
    );
  }

  Widget _buildPortraitBody(
    BuildContext context,
    List<DateTime> days,
    List<ItineraryStepModel> outsideSteps,
    bool isMobile,
    EdgeInsets contentPadding,
  ) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
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
                      ItineraryHero(
                        itinerary: widget.itinerary,
                        stepsCount: _state.steps.length,
                        dateLabel: dateRangeLabel(widget.itinerary),
                        onHistory: () =>
                            context.goNamed(AppRouteNames.itineraryHistory),
                        onMap: _openFullMap,
                      ),
                    ),
                    if (!widget.itinerary.isEditable) ...[
                      const SizedBox(height: 14),
                      _wrapContent(
                        context,
                        ReadOnlyItineraryBanner(
                          isPast: widget.itinerary.isPast,
                        ),
                      ),
                    ],
                    if (_state.feedbackMessage != null) ...[
                      SizedBox(height: isMobile ? 14 : 16),
                      _wrapContent(
                        context,
                        AppFeedbackBanner(
                          message: _state.feedbackMessage!,
                          type: _state.feedbackType ?? AppFeedbackType.error,
                          onDismiss: () =>
                              _emit(_state.copyWith(clearFeedback: true)),
                        ),
                      ),
                    ],
                    if (outsideSteps.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _wrapContent(
                        context,
                        OutOfRangeWarning(count: outsideSteps.length),
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          WeatherSection(itinerary: widget.itinerary),
                          const SizedBox(height: 22),
                          DaySelector(
                            key: ValueKey(
                              '${widget.itinerary.id}-$_daySelectorResetRevision',
                            ),
                            days: days,
                            labels: days
                                .map((d) => dayChipLabel(d, _state.steps))
                                .toList(growable: false),
                            onSelected: (index, day) =>
                                setState(() => _selectedDay = day),
                          ),
                          const SizedBox(height: 10),
                          if (days.length > 1 && widget.itinerary.isEditable)
                            Text(
                              'Mantén presionada una parada y arrástrala a otro día para reorganizarla.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: contentPadding.left),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    for (final entry in days.indexed)
                      if (_selectedDay == null ||
                          isSameDay(entry.$2, _selectedDay!))
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.$1 == days.length - 1 ? 0 : 18,
                          ),
                          child: _wrapContent(
                            context,
                            DayDropSection(
                              label: fullDayLabel(entry.$2, _state.steps),
                              day: entry.$2,
                              steps: _controller.stepsForDate(
                                _state.steps,
                                entry.$2,
                              ),
                              isEditable: widget.itinerary.isEditable,
                              isSavingReorder: _state.isSavingReorder,
                              onDrop: _onReorderStep,
                              onOpenMap:
                                  _controller
                                      .stepsForDate(_state.steps, entry.$2)
                                      .isEmpty
                                  ? null
                                  : () => _openDayOnMap(entry.$2),
                              stepBuilder: (context, step) => GeneratedStep(
                                step: step,
                                isEditable: widget.itinerary.isEditable,
                                isSavingReorder: _state.isSavingReorder,
                                onDelete: () => _onDeleteStep(step),
                                onChange: () => _onChangeStep(step),
                                onReschedule: () => _onRescheduleDialog(step),
                                onDragStarted: () =>
                                    _onStepDragStarted(step, entry.$2),
                                onDragEnded: _onStepDragEnded,
                              ),
                            ),
                          ),
                        ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  contentPadding.left,
                  12,
                  contentPadding.right,
                  0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: contentPadding.bottom),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: InterDayDragDrawer(
              visible: _isDraggingStep,
              days: days,
              currentDay: _draggingFromDay,
              enabled: widget.itinerary.isEditable && !_state.isSavingReorder,
              onDrop: _onInterDayDrop,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeBody(
    BuildContext context,
    List<DateTime> days,
    List<ItineraryStepModel> outsideSteps,
    bool isMobile,
    EdgeInsets contentPadding,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                contentPadding.left,
                contentPadding.top,
                contentPadding.right,
                0,
              ),
              child: _wrapContent(
                context,
                DaySelector(
                  key: ValueKey(
                    '${widget.itinerary.id}-$_daySelectorResetRevision',
                  ),
                  days: days,
                  labels: days
                      .map((d) => dayChipLabel(d, _state.steps))
                      .toList(growable: false),
                  onSelected: (index, day) =>
                      setState(() => _selectedDay = day),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 60,
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          contentPadding.left,
                          0,
                          contentPadding.right,
                          contentPadding.bottom,
                        ),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final day = days[index];
                          if (_selectedDay != null &&
                              !isSameDay(day, _selectedDay!)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == days.length - 1 ? 0 : 18,
                            ),
                            child: _wrapContent(
                              context,
                              DayDropSection(
                                label: fullDayLabel(day, _state.steps),
                                day: day,
                                steps: _controller.stepsForDate(
                                  _state.steps,
                                  day,
                                ),
                                isEditable: widget.itinerary.isEditable,
                                isSavingReorder: _state.isSavingReorder,
                                onDrop: _onReorderStep,
                                onOpenMap:
                                    _controller
                                        .stepsForDate(_state.steps, day)
                                        .isEmpty
                                    ? null
                                    : () => _openDayOnMap(day),
                                stepBuilder: (context, step) => GeneratedStep(
                                  step: step,
                                  isEditable: widget.itinerary.isEditable,
                                  isSavingReorder: _state.isSavingReorder,
                                  onDelete: () => _onDeleteStep(step),
                                  onChange: () => _onChangeStep(step),
                                  onReschedule: () => _onRescheduleDialog(step),
                                  onDragStarted: () =>
                                      _onStepDragStarted(step, day),
                                  onDragEnded: _onStepDragEnded,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 40,
                    child: _ItineraryMiniMap(
                      itineraryId: widget.itinerary.id,
                      steps: _selectedDay == null
                          ? const <ItineraryStepModel>[]
                          : _controller.stepsForDate(
                              _state.steps,
                              _selectedDay!,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: InterDayDragDrawer(
              visible: _isDraggingStep,
              days: days,
              currentDay: _draggingFromDay,
              enabled: widget.itinerary.isEditable && !_state.isSavingReorder,
              onDrop: _onInterDayDrop,
            ),
          ),
        ),
      ],
    );
  }

  Widget _wrapContent(BuildContext context, Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppResponsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  void _onStepDragStarted(ItineraryStepModel step, DateTime fromDay) {
    if (!widget.itinerary.isEditable || _state.isSavingReorder) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isDraggingStep = true;
      _draggingFromDay = fromDay;
    });
  }

  void _onStepDragEnded() {
    if (!_isDraggingStep && _draggingFromDay == null) return;
    setState(() {
      _isDraggingStep = false;
      _draggingFromDay = null;
    });
  }

  void _onInterDayDrop(ItineraryStepModel step, DateTime targetDay) {
    if (!widget.itinerary.isEditable) {
      _onStepDragEnded();
      _emit(
        _controller.showFeedback(
          _state,
          'Este itinerario ya no se puede editar.',
          type: AppFeedbackType.info,
        ),
      );
      return;
    }
    final fromDay = _draggingFromDay ?? stepDay(step) ?? targetDay;
    HapticFeedback.lightImpact();
    setState(() {
      _isDraggingStep = false;
      _draggingFromDay = null;
      _selectedDay = targetDay;
      _daySelectorResetRevision++;
    });

    final next = _controller.moveStepToDay(
      _state,
      step,
      fromDay: fromDay,
      toDay: targetDay,
      onSaveReorder: (payload) async {
        final result = await _controller.saveReorder(_state, payload);
        if (mounted) _emit(result);
      },
    );
    _emit(next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Movido a ${weekdayName(targetDay)}')),
    );
  }

  void _onReorderStep(
    ItineraryStepModel movedStep,
    DateTime targetDay,
    int targetIndex,
  ) {
    if (!widget.itinerary.isEditable) {
      _emit(
        _controller.showFeedback(
          _state,
          'Este itinerario ya no se puede editar.',
          type: AppFeedbackType.info,
        ),
      );
      return;
    }
    final next = _controller.reorderStep(
      _state,
      movedStep,
      targetDay,
      targetIndex,
      onSaveReorder: (payload) async {
        final result = await _controller.saveReorder(_state, payload);
        if (mounted) _emit(result);
      },
    );
    _emit(next);
  }

  Future<void> _onDeleteStep(ItineraryStepModel step) async {
    if (!widget.itinerary.isEditable) {
      _emit(
        _controller.showFeedback(
          _state,
          'Este itinerario ya no se puede editar.',
          type: AppFeedbackType.info,
        ),
      );
      return;
    }
    final next = await _controller.deleteStep(_state, step.id);
    if (mounted) {
      _emit(next);
      if (next.feedbackMessage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Parada eliminada.')));
      }
    }
  }

  Future<void> _onRescheduleDialog(ItineraryStepModel step) async {
    if (!widget.itinerary.isEditable) {
      _emit(
        _controller.showFeedback(
          _state,
          'Este itinerario ya no se puede editar.',
          type: AppFeedbackType.info,
        ),
      );
      return;
    }
    final initialTime = step.arrivalTime != null
        ? TimeOfDay(
            hour: step.arrivalTime!.hour,
            minute: step.arrivalTime!.minute,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    final durationController = TextEditingController(
      text: step.recommendedDuration,
    );
    final result = await showDialog<RescheduleResult>(
      context: context,
      builder: (ctx) => RescheduleDialog(
        initialTime: initialTime,
        durationController: durationController,
      ),
    );
    durationController.dispose();
    if (result == null) return;
    final mins = int.tryParse(durationController.text.trim());
    final next = await _controller.rescheduleStep(
      _state,
      stepId: step.id,
      arrivalTime: result.time,
      durationMinutes: mins,
    );
    if (mounted) {
      _emit(next);
      if (next.feedbackMessage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Horario actualizado.')));
      }
    }
  }

  Future<void> _onChangeStep(ItineraryStepModel step) async {
    if (!widget.itinerary.isEditable) {
      _emit(
        _controller.showFeedback(
          _state,
          'Este itinerario ya no se puede editar.',
          type: AppFeedbackType.info,
        ),
      );
      return;
    }
    if (_state.isStartingStepReplacement) return;
    _emit(_state.copyWith(isStartingStepReplacement: true));

    final center = ref.read(mapProvider).center;
    final start = widget.itinerary.startDate;
    final end = widget.itinerary.endDate;
    final prompt = 'cambiar la parada de ${step.title}';

    try {
      final sessionFuture = ref
          .read(chatProvider.notifier)
          .startSessionFromHome(
            initialMessage: prompt,
            center: center,
            radius: 10000,
            startDate: start,
            endDate: end,
            metadata: {
              'intent': 'change_itinerary_step',
              'conversation_mode': 'replacement',
              'itinerary_id': widget.itinerary.id,
              'step_id': step.id,
            },
          );
      if (!mounted) return;
      context.goNamed(AppRouteNames.chat);
      await sessionFuture;
    } finally {
      if (mounted) {
        _emit(_state.copyWith(isStartingStepReplacement: false));
      }
    }
  }

  Future<void> _onRefresh() async {
    await _controller.refresh();
  }

  Future<void> _openFullMap() async {
    try {
      final points = await ref.read(
        itineraryPoisProvider(widget.itinerary.id).future,
      );
      ref
          .read(mapProvider.notifier)
          .showItineraryPois(itineraryId: widget.itinerary.id, points: points);
      if (!mounted) return;
      context.pushNamedSafe(
        AppRouteNames.focusedMap,
        extra: AppRouteNames.itineraryHistory,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos cargar los lugares de esta ruta en el mapa.',
          ),
        ),
      );
    }
  }

  Future<void> _openDayOnMap(DateTime day) async {
    final daySteps = _controller.stepsForDate(_state.steps, day);
    _emit(_state.copyWith(clearFeedback: true));
    try {
      final selectedIds = daySteps
          .map((s) => s.poiId)
          .whereType<String>()
          .toSet();
      final points = await ref.read(
        itineraryPoisProvider(widget.itinerary.id).future,
      );
      final filtered = points.where((p) => selectedIds.contains(p.id)).toList();
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
      _emit(
        _controller.showFeedback(
          _state,
          'No pudimos cargar este día en el mapa. Intenta nuevamente.',
        ),
      );
    }
  }
}

class _ItineraryMiniMap extends ConsumerWidget {
  final String itineraryId;
  final List<ItineraryStepModel> steps;

  const _ItineraryMiniMap({required this.itineraryId, required this.steps});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final poiIds = steps.map((step) => step.poiId).whereType<String>().toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: poiIds.isEmpty
          ? const _MiniMapEmptyState(
              title: 'Mapa del recorrido',
              message: 'Este día no tiene paradas.',
            )
          : ref
                .watch(itineraryPoisProvider(itineraryId))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const _MiniMapEmptyState(
                    title: 'No pudimos cargar el mapa',
                    message: 'Reintenta abriendo el mapa completo.',
                  ),
                  data: (points) {
                    final pointById = {
                      for (final point in points) point.id: point,
                    };
                    final dayPoints = poiIds
                        .map((id) => pointById[id])
                        .whereType<MapPoint>()
                        .toList(growable: false);
                    if (dayPoints.isEmpty) {
                      return const _MiniMapEmptyState(
                        title: 'Sin coordenadas',
                        message:
                            'No hay coordenadas para las paradas de este día.',
                      );
                    }
                    final center = _averageCenter(dayPoints);
                    return ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: dayPoints.length == 1 ? 13 : 11,
                          minZoom: 7,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.rutaviva.app',
                          ),
                          if (dayPoints.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: dayPoints
                                      .map((point) => point.coordinates)
                                      .toList(growable: false),
                                  color: theme.colorScheme.primary,
                                  strokeWidth: 3,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              for (final entry in dayPoints.indexed)
                                Marker(
                                  point: entry.$2.coordinates,
                                  width: 34,
                                  height: 34,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.shadow
                                              .withValues(alpha: 0.22),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.$1 + 1}',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  LatLng _averageCenter(List<MapPoint> points) {
    final latitude =
        points.fold<double>(
          0,
          (sum, point) => sum + point.coordinates.latitude,
        ) /
        points.length;
    final longitude =
        points.fold<double>(
          0,
          (sum, point) => sum + point.coordinates.longitude,
        ) /
        points.length;
    return LatLng(latitude, longitude);
  }
}

class _MiniMapEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _MiniMapEmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
