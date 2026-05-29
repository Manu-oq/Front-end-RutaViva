import 'dart:async';
import 'dart:convert';

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
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/ara/sessions/$sessionId/messages',
        data: {
          'message': message,
          if (startDate != null) 'start_date': _dateOnly(startDate),
          if (endDate != null) 'end_date': _dateOnly(endDate),
        },
      );
      return AraSessionModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Stream<AraGenerationStreamEvent> generateItineraryStream({
    required String sessionId,
    String? finalInstruction,
  }) async* {
    try {
      final response = await _client.post<ResponseBody>(
        '/ara/sessions/$sessionId/generate-itinerary/stream',
        data: finalInstruction == null || finalInstruction.trim().isEmpty
            ? null
            : {'final_instruction': finalInstruction.trim()},
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw const ApiException(message: 'Ara no inició el streaming.');
      }

      String? eventName;
      final dataLines = <String>[];

      AraGenerationStreamEvent? flushEvent() {
        if (eventName == null && dataLines.isEmpty) return null;
        final currentEvent = eventName ?? 'message';
        final rawData = dataLines.join('\n');
        eventName = null;
        dataLines.clear();
        if (rawData.trim().isEmpty) return null;

        final decoded = jsonDecode(rawData);
        final json = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded as Map);

        return switch (currentEvent) {
          'status' => AraGenerationStatusEvent.fromJson(json),
          'result' => AraGenerationResultEvent(
            AraGenerateItineraryResponse.fromJson(json),
          ),
          'warning' => AraGenerationWarningEvent.fromJson(json),
          'error' => AraGenerationErrorEvent(
            (json['message'] ?? 'Ara no pudo generar el itinerario.')
                .toString(),
          ),
          _ => null,
        };
      }

      await for (final line
          in body.stream
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.isEmpty) {
          final event = flushEvent();
          if (event != null) yield event;
          continue;
        }
        if (line.startsWith(':')) continue;
        if (line.startsWith('event:')) {
          eventName = line.substring('event:'.length).trim();
        } else if (line.startsWith('data:')) {
          dataLines.add(line.substring('data:'.length).trimLeft());
        }
      }

      final event = flushEvent();
      if (event != null) yield event;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
