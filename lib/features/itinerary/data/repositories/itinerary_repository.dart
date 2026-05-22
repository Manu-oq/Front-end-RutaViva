import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/itinerary_model.dart';

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepository(ref.watch(apiClientProvider));
});

final itineraryHistoryProvider = FutureProvider<List<ItineraryModel>>((
  ref,
) async {
  return ref.watch(itineraryRepositoryProvider).getMyItineraries();
});

final itineraryDetailProvider = FutureProvider.family<ItineraryModel, String>((
  ref,
  itineraryId,
) async {
  return ref.watch(itineraryRepositoryProvider).getItineraryById(itineraryId);
});

class ItineraryRepository {
  final DioClient _client;

  const ItineraryRepository(this._client);

  Future<List<ItineraryModel>> getMyItineraries({
    int page = 1,
    int pageSize = 20,
  }) async {
    final paginated = await getMyItinerariesPage(
      page: page,
      pageSize: pageSize,
    );
    return paginated.items;
  }

  Future<PaginatedItinerariesModel> getMyItinerariesPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/itineraries/',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return PaginatedItinerariesModel.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> getItineraryById(String itineraryId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/itineraries/$itineraryId',
      );
      return ItineraryModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> generateItinerary({
    required String query,
    required double lat,
    required double lon,
    required double radius,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/itineraries/generate',
        data: {
          'query': query,
          'lat': lat,
          'lon': lon,
          'radius': radius,
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
        },
      );
      return ItineraryModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> updateStep({
    required String itineraryId,
    required String stepId,
    required String poiId,
  }) async {
    try {
      final response = await _client.patch<dynamic>(
        '/itineraries/$itineraryId/steps/$stepId',
        data: {'poi_id': poiId},
      );
      return _parseItineraryOrFetch(response.data, itineraryId);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> addStep({
    required String itineraryId,
    required String poiId,
    DateTime? arrivalTime,
    DateTime? departureTime,
    Map<String, dynamic>? aiContext,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/itineraries/$itineraryId/steps',
        data: {
          'poi_id': poiId,
          // ignore: use_null_aware_elements
          if (arrivalTime != null)
            'arrival_time': arrivalTime.toUtc().toIso8601String(),
          // ignore: use_null_aware_elements
          if (departureTime != null)
            'departure_time': departureTime.toUtc().toIso8601String(),
          // ignore: use_null_aware_elements
          if (aiContext != null) 'ai_context': aiContext,
        },
      );
      return ItineraryModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> updateStatus({
    required String itineraryId,
    required String status,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/itineraries/$itineraryId/status',
        data: {'status': status},
      );
      return ItineraryModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> deleteStep({
    required String itineraryId,
    required String stepId,
  }) async {
    try {
      final response = await _client.delete<dynamic>(
        '/itineraries/$itineraryId/steps/$stepId',
      );
      return _parseItineraryOrFetch(response.data, itineraryId);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deleteItinerary(String itineraryId) async {
    try {
      await _client.delete<void>('/itineraries/$itineraryId');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> reorderSteps({
    required String itineraryId,
    required List<String> stepIds,
  }) async {
    try {
      final response = await _client.patch<dynamic>(
        '/itineraries/$itineraryId/steps/reorder',
        data: {'step_ids': stepIds},
      );
      return _parseItineraryOrFetch(response.data, itineraryId);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> reorderStepsWithTimes({
    required String itineraryId,
    required List<Map<String, dynamic>> steps,
  }) async {
    try {
      final response = await _client.patch<dynamic>(
        '/itineraries/$itineraryId/steps/reorder-with-times',
        data: steps,
      );
      return _parseItineraryOrFetch(response.data, itineraryId);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> rescheduleStep({
    required String itineraryId,
    required String stepId,
    required DateTime arrivalTime,
    int? durationMinutes,
  }) async {
    try {
      final response = await _client.patch<dynamic>(
        '/itineraries/$itineraryId/steps/$stepId/reschedule',
        data: {
          'arrival_time': arrivalTime.toUtc().toIso8601String(),
          // ignore: use_null_aware_elements
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
        },
      );
      return _parseItineraryOrFetch(response.data, itineraryId);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> getItineraryWeather(String itineraryId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/itineraries/$itineraryId/weather',
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<StepVisitModel> markStepVisited({
    required String itineraryId,
    required String stepId,
    String? note,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/itineraries/$itineraryId/steps/$stepId/visit',
        data: {
          // ignore: use_null_aware_elements
          if (note != null) 'note': note,
        },
      );
      return StepVisitModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<StepVisitModel>> getVisits(String itineraryId) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/itineraries/$itineraryId/visits',
      );
      return (response.data ?? [])
          .map((item) => StepVisitModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryExportModel> exportItinerary(String itineraryId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/itineraries/$itineraryId/export',
      );
      return ItineraryExportModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryShareModel> shareItinerary(String itineraryId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/itineraries/$itineraryId/share',
      );
      return ItineraryShareModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deleteShare(String itineraryId) async {
    try {
      await _client.delete<void>('/itineraries/$itineraryId/share');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryExportModel> getSharedItinerary(String publicId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiConstants.backendOrigin}/share/$publicId',
      );
      return ItineraryExportModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ItineraryModel> _parseItineraryOrFetch(
    dynamic data,
    String itineraryId,
  ) {
    if (data is Map<String, dynamic> && data.containsKey('steps')) {
      return Future.value(ItineraryModel.fromJson(data));
    }
    return getItineraryById(itineraryId);
  }

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
