import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/storage/local_storage_provider.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';

class ItineraryState {
  final ItineraryModel? current;
  final bool isLoading;
  final String? errorMessage;

  const ItineraryState({
    this.current,
    this.isLoading = false,
    this.errorMessage,
  });

  ItineraryState copyWith({
    ItineraryModel? current,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearCurrent = false,
  }) {
    return ItineraryState(
      current: clearCurrent ? null : (current ?? this.current),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ItineraryNotifier extends Notifier<ItineraryState> {
  static const _storageKey = 'ruta_viva.last_itinerary';

  @override
  ItineraryState build() {
    final json = ref.read(sharedPreferencesProvider).getString(_storageKey);
    if (json != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return ItineraryState(current: ItineraryModel.fromJson(map));
      } catch (_) {}
    }
    return const ItineraryState();
  }

  void setCurrent(ItineraryModel itinerary) {
    state = ItineraryState(current: itinerary);
    ref.invalidate(itineraryHistoryProvider);
    _persist(itinerary);
  }

  void clearCurrent() {
    state = const ItineraryState();
    ref.read(sharedPreferencesProvider).remove(_storageKey);
  }

  void clearCurrentIfMatches(String itineraryId) {
    if (state.current?.id == itineraryId) {
      clearCurrent();
    }
  }

  Future<void> refreshCurrent() async {
    final current = state.current;
    if (current == null) {
      return;
    }

    try {
      final fresh = await ref
          .read(itineraryRepositoryProvider)
          .getItineraryById(current.id);
      state = state.copyWith(current: fresh, clearError: true);
      _persist(fresh);
    } catch (error) {
      if (error is ApiException && error.statusCode == 404) {
        clearCurrent();
      }
    }
  }

  Future<ItineraryModel?> generate({
    required String query,
    LatLng center = araucaniaDefaultCenter,
    double radius = defaultSearchRadiusMeters,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final now = DateTime.now();
    final start =
        startDate ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final end = endDate ?? start.add(const Duration(days: 1));

    if (end.isBefore(start)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'La fecha de término no puede ser anterior a la fecha de inicio.',
      );
      return null;
    }

    if (end.difference(start).inDays > 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'El viaje puede tener como máximo 7 días.',
      );
      return null;
    }

    try {
      final itinerary = await ref
          .read(itineraryRepositoryProvider)
          .generateItinerary(
            query: query,
            lat: center.latitude,
            lon: center.longitude,
            radius: radius,
            startDate: start,
            endDate: end,
          );
      state = ItineraryState(current: itinerary);
      ref.invalidate(itineraryHistoryProvider);
      _persist(itinerary);
      return itinerary;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
      return null;
    }
  }

  void _persist(ItineraryModel itinerary) {
    ref
        .read(sharedPreferencesProvider)
        .setString(_storageKey, jsonEncode(itinerary.toJson()));
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'No se pudo generar el itinerario.';
  }
}

final itineraryProvider = NotifierProvider<ItineraryNotifier, ItineraryState>(
  ItineraryNotifier.new,
);
