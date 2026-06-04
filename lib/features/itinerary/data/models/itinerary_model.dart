import '../../../../core/utils/public_text_sanitizer.dart';

class ItineraryModel {
  final String id;
  final String touristId;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final bool isPast;
  final bool isEditable;
  final List<ItineraryStepModel> steps;

  const ItineraryModel({
    required this.id,
    required this.touristId,
    required this.title,
    this.startDate,
    this.endDate,
    required this.status,
    this.isPast = false,
    bool? isEditable,
    required this.steps,
  }) : isEditable =
           isEditable ??
           !(isPast || status == 'completed' || status == 'cancelled');

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;
    final isPast = json['is_past'] as bool? ?? false;
    return ItineraryModel(
      id: json['id'] as String,
      touristId: json['tourist_id'] as String,
      title: json['title'] as String,
      startDate: _parseDate(json['start_date'] as String?),
      endDate: _parseDate(json['end_date'] as String?),
      status: status,
      isPast: isPast,
      isEditable:
          json['is_editable'] as bool? ??
          !(isPast || status == 'completed' || status == 'cancelled'),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map(
            (item) => ItineraryStepModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourist_id': touristId,
      'title': title,
      'start_date': startDate == null ? null : _dateOnly(startDate!),
      'end_date': endDate == null ? null : _dateOnly(endDate!),
      'status': status,
      'is_past': isPast,
      'is_editable': isEditable,
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  static DateTime? _parseDate(String? value) {
    if (value == null) {
      return null;
    }
    final dateOnlyMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (dateOnlyMatch != null) {
      return DateTime(
        int.parse(dateOnlyMatch.group(1)!),
        int.parse(dateOnlyMatch.group(2)!),
        int.parse(dateOnlyMatch.group(3)!),
      );
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  static String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}

class ItineraryStepModel {
  final String id;
  final String itineraryId;
  final String? poiId;
  final String? poiName;
  final String? poiDescription;
  final int stepOrder;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final int? dayIndex;
  final DateTime? dayDate;
  final String? dayLabel;
  final Map<String, dynamic>? aiContext;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItineraryStepModel({
    required this.id,
    required this.itineraryId,
    required this.poiId,
    this.poiName,
    this.poiDescription,
    required this.stepOrder,
    this.arrivalTime,
    this.departureTime,
    this.dayIndex,
    this.dayDate,
    this.dayLabel,
    this.aiContext,
    this.createdAt,
    this.updatedAt,
  });

  factory ItineraryStepModel.fromJson(Map<String, dynamic> json) {
    return ItineraryStepModel(
      id: json['id'] as String,
      itineraryId: json['itinerary_id'] as String,
      poiId: json['poi_id'] as String?,
      poiName: json['poi_name'] as String?,
      poiDescription: PublicTextSanitizer.cleanOptional(
        json['poi_description'] as String?,
      ),
      stepOrder: (json['step_order'] as num).toInt(),
      arrivalTime: _parseDateTime(json['arrival_time'] as String?),
      departureTime: _parseDateTime(json['departure_time'] as String?),
      dayIndex: (json['day_index'] as num?)?.toInt(),
      dayDate: ItineraryModel._parseDate(json['day_date'] as String?),
      dayLabel: json['day_label'] as String?,
      aiContext: json['ai_context'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(json['created_at'] as String?),
      updatedAt: _parseDateTime(json['updated_at'] as String?),
    );
  }

  String get title =>
      aiContext?['title']?.toString() ?? poiName ?? 'Parada $stepOrder';

  String get reason {
    final reasonRaw =
        PublicTextSanitizer.cleanOptional(aiContext?['reason']?.toString()) ??
        '';
    if (reasonRaw.isEmpty ||
        reasonRaw.contains('reemplazado') ||
        reasonRaw.contains('placeholder') ||
        reasonRaw == 'null') {
      return poiDescription ??
          'Lugar seleccionado por Ara para este recorrido.';
    }
    return reasonRaw;
  }

  String get tips =>
      PublicTextSanitizer.cleanOptional(aiContext?['tips']?.toString()) ?? '';

  String get recommendedDuration =>
      aiContext?['recommended_duration']?.toString() ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itinerary_id': itineraryId,
      'poi_id': poiId,
      'poi_name': poiName,
      'poi_description': poiDescription,
      'step_order': stepOrder,
      'arrival_time': arrivalTime?.toLocal().toIso8601String(),
      'departure_time': departureTime?.toLocal().toIso8601String(),
      'day_index': dayIndex,
      'day_date': dayDate == null ? null : ItineraryModel._dateOnly(dayDate!),
      'day_label': dayLabel,
      'ai_context': aiContext,
      'created_at': createdAt?.toLocal().toIso8601String(),
      'updated_at': updatedAt?.toLocal().toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(value);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
        int.parse(match.group(6) ?? '0'),
      );
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  ItineraryStepModel copyWith({
    int? stepOrder,
    DateTime? arrivalTime,
    DateTime? departureTime,
    int? dayIndex,
    DateTime? dayDate,
    String? dayLabel,
    Map<String, dynamic>? aiContext,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItineraryStepModel(
      id: id,
      itineraryId: itineraryId,
      poiId: poiId,
      poiName: poiName,
      poiDescription: poiDescription,
      stepOrder: stepOrder ?? this.stepOrder,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      dayIndex: dayIndex ?? this.dayIndex,
      dayDate: dayDate ?? this.dayDate,
      dayLabel: dayLabel ?? this.dayLabel,
      aiContext: aiContext ?? this.aiContext,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PaginatedItinerariesModel {
  final List<ItineraryModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedItinerariesModel({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedItinerariesModel.fromJson(Map<String, dynamic> json) {
    return PaginatedItinerariesModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => ItineraryModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      total: (json['total'] as num? ?? 0).toInt(),
      page: (json['page'] as num? ?? 1).toInt(),
      pageSize: (json['page_size'] as num? ?? 20).toInt(),
      totalPages: (json['total_pages'] as num? ?? 1).toInt(),
    );
  }
}

class StepVisitModel {
  final String id;
  final String stepId;
  final String? poiId;
  final DateTime? visitedAt;
  final String source;
  final String? note;

  const StepVisitModel({
    required this.id,
    required this.stepId,
    required this.poiId,
    this.visitedAt,
    required this.source,
    this.note,
  });

  factory StepVisitModel.fromJson(Map<String, dynamic> json) {
    return StepVisitModel(
      id: json['id'].toString(),
      stepId: json['step_id'].toString(),
      poiId: json['poi_id']?.toString(),
      visitedAt: ItineraryStepModel._parseDateTime(
        json['visited_at'] as String?,
      ),
      source: (json['source'] ?? 'itinerary').toString(),
      note: json['note']?.toString(),
    );
  }
}

class ItineraryStepWeatherModel {
  final String stepId;
  final String? poiId;
  final String? poiName;
  final DateTime? dayDate;
  final bool weatherAvailable;
  final String weatherStatus;
  final String? weatherMessage;
  final ItineraryWeatherModel? weather;

  const ItineraryStepWeatherModel({
    required this.stepId,
    required this.poiId,
    this.poiName,
    this.dayDate,
    required this.weatherAvailable,
    required this.weatherStatus,
    this.weatherMessage,
    this.weather,
  });

  factory ItineraryStepWeatherModel.fromJson(Map<String, dynamic> json) {
    return ItineraryStepWeatherModel(
      stepId: json['step_id'].toString(),
      poiId: json['poi_id']?.toString(),
      poiName: json['poi_name']?.toString(),
      dayDate: ItineraryModel._parseDate(json['day_date'] as String?),
      weatherAvailable: json['weather_available'] as bool? ?? false,
      weatherStatus: (json['weather_status'] ?? 'unavailable').toString(),
      weatherMessage: json['weather_message']?.toString(),
      weather: json['weather'] is Map
          ? ItineraryWeatherModel.fromJson(
              Map<String, dynamic>.from(json['weather'] as Map),
            )
          : null,
    );
  }
}

class ItineraryWeatherModel {
  final String? description;
  final double? temperatureC;
  final int? precipitationProbability;

  const ItineraryWeatherModel({
    this.description,
    this.temperatureC,
    this.precipitationProbability,
  });

  factory ItineraryWeatherModel.fromJson(Map<String, dynamic> json) {
    final temperature = json['temperature_c'];
    final rain = json['precipitation_probability'];
    return ItineraryWeatherModel(
      description: json['description']?.toString(),
      temperatureC: temperature is num
          ? temperature.toDouble()
          : double.tryParse(temperature?.toString() ?? ''),
      precipitationProbability: rain is num
          ? rain.round()
          : int.tryParse(rain?.toString() ?? ''),
    );
  }
}

class ItineraryExportStepModel {
  final int day;
  final DateTime? date;
  final int order;
  final String poiName;
  final String? poiDescription;
  final String? poiAddress;
  final String? arrivalTime;
  final String? departureTime;
  final String? tips;
  final Map<String, dynamic>? weather;
  final double? latitude;
  final double? longitude;

  const ItineraryExportStepModel({
    required this.day,
    this.date,
    required this.order,
    required this.poiName,
    this.poiDescription,
    this.poiAddress,
    this.arrivalTime,
    this.departureTime,
    this.tips,
    this.weather,
    this.latitude,
    this.longitude,
  });

  factory ItineraryExportStepModel.fromJson(Map<String, dynamic> json) {
    return ItineraryExportStepModel(
      day: (json['day'] as num? ?? 0).toInt(),
      date: ItineraryModel._parseDate(json['date'] as String?),
      order: (json['order'] as num? ?? 0).toInt(),
      poiName: (json['poi_name'] ?? '').toString(),
      poiDescription: json['poi_description']?.toString(),
      poiAddress: json['poi_address']?.toString(),
      arrivalTime: json['arrival_time']?.toString(),
      departureTime: json['departure_time']?.toString(),
      tips: json['tips']?.toString(),
      weather: json['weather'] as Map<String, dynamic>?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class ItineraryExportModel {
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ItineraryExportStepModel> steps;
  final int totalDays;
  final int totalSteps;
  final DateTime? generatedAt;

  const ItineraryExportModel({
    required this.title,
    this.startDate,
    this.endDate,
    this.steps = const [],
    required this.totalDays,
    required this.totalSteps,
    this.generatedAt,
  });

  factory ItineraryExportModel.fromJson(Map<String, dynamic> json) {
    return ItineraryExportModel(
      title: (json['title'] ?? '').toString(),
      startDate: ItineraryModel._parseDate(json['start_date'] as String?),
      endDate: ItineraryModel._parseDate(json['end_date'] as String?),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ItineraryExportStepModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      totalDays: (json['total_days'] as num? ?? 0).toInt(),
      totalSteps: (json['total_steps'] as num? ?? 0).toInt(),
      generatedAt: ItineraryStepModel._parseDateTime(
        json['generated_at'] as String?,
      ),
    );
  }
}

class ItineraryShareModel {
  final String shareUrl;
  final String publicId;

  const ItineraryShareModel({required this.shareUrl, required this.publicId});

  factory ItineraryShareModel.fromJson(Map<String, dynamic> json) {
    return ItineraryShareModel(
      shareUrl: (json['share_url'] ?? '').toString(),
      publicId: (json['public_id'] ?? '').toString(),
    );
  }
}
