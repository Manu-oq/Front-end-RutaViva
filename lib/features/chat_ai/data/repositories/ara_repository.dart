import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/ara_session_model.dart';

final araRepositoryProvider = Provider<AraRepository>((ref) {
  return AraRepository(ref.watch(apiClientProvider));
});

class AraRepository {
  final DioClient _client;

  const AraRepository(this._client);

  Future<AraSessionModel> createSession({
    required String initialMessage,
    required LatLng center,
    required double radius,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/ara/sessions',
        data: {
          'initial_message': initialMessage,
          'lat': center.latitude,
          'lon': center.longitude,
          'radius': radius,
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        },
      );
      return AraSessionModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AraSessionModel> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/ara/sessions/$sessionId/messages',
        data: {'message': message},
      );
      return AraSessionModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AraGenerateItineraryResponse> generateItinerary({
    required String sessionId,
    String? finalInstruction,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/ara/sessions/$sessionId/generate-itinerary',
        data: finalInstruction == null || finalInstruction.trim().isEmpty
            ? null
            : {'final_instruction': finalInstruction.trim()},
      );
      return AraGenerateItineraryResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AraItineraryGenerationStatus> startItineraryGenerationAsync({
    required String sessionId,
    String? finalInstruction,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/ara/sessions/$sessionId/generate-itinerary/async',
        data: finalInstruction == null || finalInstruction.trim().isEmpty
            ? null
            : {'final_instruction': finalInstruction.trim()},
      );
      return AraItineraryGenerationStatus.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AraItineraryGenerationStatus> getGenerationStatus({
    required String sessionId,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/ara/sessions/$sessionId/generation-status',
      );
      return AraItineraryGenerationStatus.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
