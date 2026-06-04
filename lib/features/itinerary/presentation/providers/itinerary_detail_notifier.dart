import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/models/itinerary_reorder_payload.dart';
import '../../data/repositories/itinerary_repository.dart';

class ItineraryDetailState {
  final List<ItineraryStepModel> steps;
  final bool isSavingReorder;
  final bool isStartingStepReplacement;
  final String? feedbackMessage;
  final AppFeedbackType? feedbackType;

  const ItineraryDetailState({
    required this.steps,
    this.isSavingReorder = false,
    this.isStartingStepReplacement = false,
    this.feedbackMessage,
    this.feedbackType,
  });

  ItineraryDetailState copyWith({
    List<ItineraryStepModel>? steps,
    bool? isSavingReorder,
    bool? isStartingStepReplacement,
    String? feedbackMessage,
    AppFeedbackType? feedbackType,
    bool clearFeedback = false,
  }) {
    return ItineraryDetailState(
      steps: steps ?? this.steps,
      isSavingReorder: isSavingReorder ?? this.isSavingReorder,
      isStartingStepReplacement:
          isStartingStepReplacement ?? this.isStartingStepReplacement,
      feedbackMessage: clearFeedback
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackType: feedbackType ?? this.feedbackType,
    );
  }
}

class ItineraryDetailController {
  final WidgetRef _ref;
  final ItineraryModel itinerary;

  ItineraryDetailController(this._ref, this.itinerary);

  ItineraryDetailState get initialState =>
      ItineraryDetailState(steps: [...itinerary.steps]);

  List<DateTime> tripDays(List<ItineraryStepModel> steps) {
    final start = itinerary.startDate;
    final end = itinerary.endDate;
    if (start != null && end != null && !end.isBefore(start)) {
      final startDay = dateOnly(start);
      final endDay = dateOnly(end);
      return List.generate(
        endDay.difference(startDay).inDays + 1,
        (index) => startDay.add(Duration(days: index)),
      );
    }
    final stepDays = steps.map(stepDay).whereType<DateTime>().toSet().toList()
      ..sort();
    return stepDays.isEmpty ? [dateOnly(DateTime.now())] : stepDays;
  }

  List<ItineraryStepModel> stepsForDate(
    List<ItineraryStepModel> steps,
    DateTime day,
  ) {
    return steps.where((step) {
      final sDay = stepDay(step);
      if (sDay == null) return false;
      return isSameDay(sDay, day);
    }).toList()..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
  }

  List<ItineraryStepModel> outsideRangeSteps(
    List<ItineraryStepModel> steps,
    List<DateTime> days,
  ) {
    if (days.isEmpty) return const [];
    final first = days.first;
    final last = days.last;
    return steps.where((step) {
      final day = stepDay(step);
      if (day == null) return false;
      return day.isBefore(first) || day.isAfter(last);
    }).toList();
  }

  int dayIndexForStep(ItineraryStepModel step, List<DateTime> days) {
    final explicitDayIndex = step.dayIndex;
    if (explicitDayIndex != null && explicitDayIndex > 0) {
      return explicitDayIndex;
    }
    final sDay = stepDay(step);
    if (sDay != null) {
      final dateIndex = days.indexWhere((day) => isSameDay(day, sDay));
      if (dateIndex >= 0) return dateIndex + 1;
    }
    return 1;
  }

  Future<ItineraryDetailState> deleteStep(
    ItineraryDetailState state,
    String stepId,
  ) async {
    var next = state.copyWith(clearFeedback: true);
    try {
      final updated = await _ref
          .read(itineraryRepositoryProvider)
          .deleteStep(itineraryId: itinerary.id, stepId: stepId);
      next = next.copyWith(steps: [...updated.steps]);
      _invalidateRelated();
    } catch (error) {
      next = _handleMutationError(
        next,
        error,
        fallback: 'No pudimos eliminar la parada. Intenta nuevamente.',
      );
    }
    return next;
  }

  Future<ItineraryDetailState> rescheduleStep(
    ItineraryDetailState state, {
    required String stepId,
    required TimeOfDay arrivalTime,
    int? durationMinutes,
  }) async {
    var next = state.copyWith(clearFeedback: true);
    final now = DateTime.now();
    final arrival = DateTime(
      now.year,
      now.month,
      now.day,
      arrivalTime.hour,
      arrivalTime.minute,
    );
    try {
      final updated = await _ref
          .read(itineraryRepositoryProvider)
          .rescheduleStep(
            itineraryId: itinerary.id,
            stepId: stepId,
            arrivalTime: arrival,
            durationMinutes: durationMinutes,
          );
      next = next.copyWith(steps: [...updated.steps]);
      _invalidateRelated();
    } catch (error) {
      next = _handleMutationError(
        next,
        error,
        fallback: 'No pudimos actualizar el horario. Intenta nuevamente.',
      );
    }
    return next;
  }

  ItineraryDetailState reorderStep(
    ItineraryDetailState state,
    ItineraryStepModel movedStep,
    DateTime targetDay,
    int targetIndex, {
    required void Function(List<Map<String, dynamic>> payload) onSaveReorder,
  }) {
    if (state.isSavingReorder) return state;
    final days = tripDays(state.steps);
    if (days.isEmpty) return state;
    final targetDayIndex = days.indexWhere((day) => isSameDay(day, targetDay));
    if (targetDayIndex < 0) return state;

    final dayBuckets = <DateTime, List<ItineraryStepModel>>{
      for (final day in days) day: stepsForDate(state.steps, day),
    };
    for (final entry in dayBuckets.entries) {
      entry.value.removeWhere((step) => step.id == movedStep.id);
    }

    final destination = dayBuckets[targetDay] ?? <ItineraryStepModel>[];
    final safeIndex = targetIndex.clamp(0, destination.length);
    destination.insert(
      safeIndex,
      movedStep.copyWith(dayDate: targetDay, dayIndex: targetDayIndex + 1),
    );
    dayBuckets[targetDay] = destination;

    final outsideSteps = state.steps.where((step) {
      final sDay = stepDay(step);
      if (step.id == movedStep.id) return false;
      if (sDay == null) return true;
      return !days.any((day) => isSameDay(day, sDay));
    }).toList();

    final nextSteps = <ItineraryStepModel>[
      for (final day in days)
        for (final entry
            in (dayBuckets[day] ?? const <ItineraryStepModel>[]).indexed)
          entry.$2.copyWith(
            dayDate: day,
            dayIndex: days.indexWhere((d) => isSameDay(d, day)) + 1,
            stepOrder: entry.$1 + 1,
          ),
      ...outsideSteps,
    ];

    final next = state.copyWith(steps: nextSteps, isSavingReorder: true);

    final payload = buildReorderWithTimesPayload(
      steps: nextSteps,
      dayIndexForStep: (step) => dayIndexForStep(step, days),
    );

    onSaveReorder(payload);
    return next;
  }

  Future<ItineraryDetailState> saveReorder(
    ItineraryDetailState state,
    List<Map<String, dynamic>> payload,
  ) async {
    var next = state.copyWith(clearFeedback: true, isSavingReorder: true);
    try {
      final updated = await _ref
          .read(itineraryRepositoryProvider)
          .reorderStepsWithTimes(itineraryId: itinerary.id, steps: payload);
      next = next.copyWith(steps: [...updated.steps], isSavingReorder: false);
      _invalidateRelated();
    } catch (error) {
      _ref.invalidate(itineraryDetailProvider(itinerary.id));
      next = _handleMutationError(
        next,
        error,
        fallback: 'No pudimos guardar el orden. Revisa la conexión.',
      );
      next = next.copyWith(isSavingReorder: false);
    }
    return next;
  }

  Future<void> refresh() async {
    _ref.invalidate(itineraryDetailProvider(itinerary.id));
    _ref.invalidate(itineraryWeatherProvider(itinerary.id));
    try {
      await _ref.read(itineraryDetailProvider(itinerary.id).future);
    } catch (_) {}
  }

  void _invalidateRelated() {
    _ref.invalidate(itineraryDetailProvider(itinerary.id));
    _ref.invalidate(itineraryPoisProvider(itinerary.id));
    _ref.invalidate(itineraryHistoryProvider);
  }

  ItineraryDetailState _handleMutationError(
    ItineraryDetailState state,
    Object error, {
    required String fallback,
  }) {
    if (error is ApiException && error.statusCode == 409) {
      unawaited(refresh());
      return state.copyWith(
        feedbackMessage: error.message,
        feedbackType: AppFeedbackType.info,
      );
    }
    return state.copyWith(feedbackMessage: fallback);
  }

  ItineraryDetailState showFeedback(
    ItineraryDetailState state,
    String message, {
    AppFeedbackType type = AppFeedbackType.error,
  }) {
    return state.copyWith(feedbackMessage: message, feedbackType: type);
  }
}
