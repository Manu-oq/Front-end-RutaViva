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
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  static DateTime? _parseDate(String? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
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
      'arrival_time': arrivalTime?.toIso8601String(),
      'departure_time': departureTime?.toIso8601String(),
      'ai_context': aiContext,
    };
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
