import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../chat_ai/presentation/providers/chat_provider.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../providers/itinerary_provider.dart';
import '../providers/itinerary_detail_notifier.dart';
import '../widgets/day_drop_section.dart';
import '../widgets/day_selector.dart';
import '../widgets/generated_step.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ItineraryDetailController(ref, widget.itinerary);
    _state = _controller.initialState;
  }

  @override
  void didUpdateWidget(covariant _ItineraryDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itinerary.id != widget.itinerary.id ||
        oldWidget.itinerary.steps != widget.itinerary.steps) {
      _controller = ItineraryDetailController(ref, widget.itinerary);
      setState(() => _state = _controller.initialState);
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                contentPadding.left, contentPadding.top,
                contentPadding.right, 0,
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
                      onMap: () => _openFullMap(),
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
                        Text('Recorrido sugerido',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 14),
                        WeatherSection(itinerary: widget.itinerary),
                        const SizedBox(height: 22),
                        DaySelector(
                          key: ValueKey(widget.itinerary.id),
                          days: days,
                          labels: days
                              .map((d) => dayChipLabel(d, _state.steps))
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 10),
                        if (days.length > 1 && widget.itinerary.isEditable)
                          Text(
                            'Mantén presionada una parada y arrástrala a otro día para reorganizarla.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
                              _state.steps, entry.$2),
                          isEditable: widget.itinerary.isEditable,
                          isSavingReorder: _state.isSavingReorder,
                          onDrop: _onReorderStep,
                          onOpenMap: _controller
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
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                contentPadding.left, 12, contentPadding.right, 0,
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
    );
  }

  Widget _wrapContent(BuildContext context, Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: AppResponsive.maxContentWidth(context)),
        child: child,
      ),
    );
  }

  void _onReorderStep(
    ItineraryStepModel movedStep,
    DateTime targetDay,
    int targetIndex,
  ) {
    if (!widget.itinerary.isEditable) {
      _emit(_controller.showFeedback(
        _state,
        'Este itinerario ya no se puede editar.',
        type: AppFeedbackType.info,
      ));
      return;
    }
    final next = _controller.reorderStep(
      _state, movedStep, targetDay, targetIndex,
      onSaveReorder: (payload) async {
        final result = await _controller.saveReorder(_state, payload);
        if (mounted) _emit(result);
      },
    );
    _emit(next);
  }

  Future<void> _onDeleteStep(ItineraryStepModel step) async {
    if (!widget.itinerary.isEditable) {
      _emit(_controller.showFeedback(
        _state,
        'Este itinerario ya no se puede editar.',
        type: AppFeedbackType.info,
      ));
      return;
    }
    final next = await _controller.deleteStep(_state, step.id);
    if (mounted) {
      _emit(next);
      if (next.feedbackMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parada eliminada.')),
        );
      }
    }
  }

  Future<void> _onRescheduleDialog(ItineraryStepModel step) async {
    if (!widget.itinerary.isEditable) {
      _emit(_controller.showFeedback(
        _state,
        'Este itinerario ya no se puede editar.',
        type: AppFeedbackType.info,
      ));
      return;
    }
    final initialTime = step.arrivalTime != null
        ? TimeOfDay(
            hour: step.arrivalTime!.hour, minute: step.arrivalTime!.minute)
        : const TimeOfDay(hour: 9, minute: 0);
    final durationController =
        TextEditingController(text: step.recommendedDuration);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario actualizado.')),
        );
      }
    }
  }

  Future<void> _onChangeStep(ItineraryStepModel step) async {
    if (!widget.itinerary.isEditable) {
      _emit(_controller.showFeedback(
        _state,
        'Este itinerario ya no se puede editar.',
        type: AppFeedbackType.info,
      ));
      return;
    }
    if (_state.isStartingStepReplacement) return;
    _emit(_state.copyWith(isStartingStepReplacement: true));

    final center = ref.read(mapProvider).center;
    final start = widget.itinerary.startDate;
    final end = widget.itinerary.endDate;
    final prompt = 'cambiar la parada de ${step.title}';

    try {
      final sessionFuture = ref.read(chatProvider.notifier).startSessionFromHome(
            initialMessage: prompt,
            center: center,
            radius: 10000,
            startDate: start,
            endDate: end,
            metadata: {
              'intent': 'change_itinerary_step',
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
      final points =
          await ref.read(itineraryPoisProvider(widget.itinerary.id).future);
      ref.read(mapProvider.notifier).showItineraryPois(
            itineraryId: widget.itinerary.id,
            points: points,
          );
      if (!context.mounted) return;
      context.pushNamedSafe(AppRouteNames.focusedMap,
          extra: AppRouteNames.itineraryHistory);
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
  }

  Future<void> _openDayOnMap(DateTime day) async {
    final daySteps = _controller.stepsForDate(_state.steps, day);
    _emit(_state.copyWith(clearFeedback: true));
    try {
      final selectedIds = daySteps.map((s) => s.poiId).toSet();
      final points =
          await ref.read(itineraryPoisProvider(widget.itinerary.id).future);
      final filtered =
          points.where((p) => selectedIds.contains(p.id)).toList();
      ref.read(mapProvider.notifier).showItineraryPois(
            itineraryId: widget.itinerary.id,
            points: filtered,
          );
      if (!context.mounted) return;
      context.pushNamedSafe(AppRouteNames.focusedMap,
          extra: AppRouteNames.itineraryHistory);
    } catch (_) {
      if (!context.mounted) return;
      _emit(_controller.showFeedback(
        _state,
        'No pudimos cargar este día en el mapa. Intenta nuevamente.',
      ));
    }
  }
}
