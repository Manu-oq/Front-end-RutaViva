import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<List<ItineraryModel>> getMyItineraries() async {
    try {
      final response = await _client.get<List<dynamic>>('/itineraries/');
      return (response.data ?? [])
          .map((item) => ItineraryModel.fromJson(item as Map<String, dynamic>))
          .toList();
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

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
