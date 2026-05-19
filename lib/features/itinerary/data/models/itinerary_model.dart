class ItineraryModel {
  final String id;
  final String touristId;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final List<ItineraryStepModel> steps;

  const ItineraryModel({
    required this.id,
    required this.touristId,
    required this.title,
    this.startDate,
    this.endDate,
    required this.status,
    required this.steps,
  });

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    return ItineraryModel(
      id: json['id'] as String,
      touristId: json['tourist_id'] as String,
      title: json['title'] as String,
      startDate: _parseDate(json['start_date'] as String?),
      endDate: _parseDate(json['end_date'] as String?),
      status: json['status'] as String,
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
  final String poiId;
  final String? poiNombre;
  final String? poiDescripcion;
  final int stepOrder;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final int? dayIndex;
  final DateTime? dayDate;
  final String? dayLabel;
  final Map<String, dynamic>? aiContext;

  const ItineraryStepModel({
    required this.id,
    required this.itineraryId,
    required this.poiId,
    this.poiNombre,
    this.poiDescripcion,
    required this.stepOrder,
    this.arrivalTime,
    this.departureTime,
    this.dayIndex,
    this.dayDate,
    this.dayLabel,
    this.aiContext,
  });

  factory ItineraryStepModel.fromJson(Map<String, dynamic> json) {
    return ItineraryStepModel(
      id: json['id'] as String,
      itineraryId: json['itinerary_id'] as String,
      poiId: json['poi_id'] as String,
      poiNombre: json['poi_nombre'] as String?,
      poiDescripcion: json['poi_descripcion'] as String?,
      stepOrder: (json['step_order'] as num).toInt(),
      arrivalTime: _parseDateTime(json['arrival_time'] as String?),
      departureTime: _parseDateTime(json['departure_time'] as String?),
      dayIndex: (json['day_index'] as num?)?.toInt(),
      dayDate: ItineraryModel._parseDate(json['day_date'] as String?),
      dayLabel: json['day_label'] as String?,
      aiContext: json['ai_context'] as Map<String, dynamic>?,
    );
  }

  String get title =>
      aiContext?['title']?.toString() ?? poiNombre ?? 'Parada $stepOrder';

  String get reason =>
      aiContext?['reason']?.toString() ??
      poiDescripcion ??
      'Lugar seleccionado por Ara para este recorrido.';

  String get tips => aiContext?['tips']?.toString() ?? '';

  String get recommendedDuration =>
      aiContext?['recommended_duration']?.toString() ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itinerary_id': itineraryId,
      'poi_id': poiId,
      'poi_nombre': poiNombre,
      'poi_descripcion': poiDescripcion,
      'step_order': stepOrder,
      'arrival_time': arrivalTime?.toLocal().toIso8601String(),
      'departure_time': departureTime?.toLocal().toIso8601String(),
      'day_index': dayIndex,
      'day_date': dayDate == null ? null : ItineraryModel._dateOnly(dayDate!),
      'day_label': dayLabel,
      'ai_context': aiContext,
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
}
