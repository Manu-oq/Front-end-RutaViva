import 'package:latlong2/latlong.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/public_text_sanitizer.dart';
import '../../domain/entities/map_point.dart';

class VisitRulesModel {
  final bool? isPrimaryExperience;
  final bool? requiresDaylight;
  final bool? nightSuitable;
  final String? latestRecommendedStartTime;
  final String? accessNotes;
  final String? confidence;

  const VisitRulesModel({
    this.isPrimaryExperience,
    this.requiresDaylight,
    this.nightSuitable,
    this.latestRecommendedStartTime,
    this.accessNotes,
    this.confidence,
  });

  factory VisitRulesModel.fromJson(Map<String, dynamic> json) {
    return VisitRulesModel(
      isPrimaryExperience: json['is_primary_experience'] as bool?,
      requiresDaylight: json['requires_daylight'] as bool?,
      nightSuitable: json['night_suitable'] as bool?,
      latestRecommendedStartTime:
          json['latest_recommended_start_time'] as String?,
      accessNotes: json['access_notes'] as String?,
      confidence: json['confidence'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_primary_experience': isPrimaryExperience,
      'requires_daylight': requiresDaylight,
      'night_suitable': nightSuitable,
      'latest_recommended_start_time': latestRecommendedStartTime,
      'access_notes': accessNotes,
      'confidence': confidence,
    };
  }
}

class PoiModel {
  final String id;
  final String name;
  final String description;
  final String accessType;
  final String? contactPhone;
  final String? contactEmail;
  final dynamic multimediaUrls;
  final String? imageUrl;
  final String? openingHoursText;
  final VisitRulesModel? visitRules;
  final List<int> categoryIds;
  final double latitude;
  final double longitude;
  final double? distanceMeters;
  final String? verificationStatus;
  final double? confidenceScore;
  final DateTime? createdAt;
  final String? createdByUserName;
  final String? createdByUserId;
  final String? creatorType;

  const PoiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.accessType,
    this.contactPhone,
    this.contactEmail,
    this.multimediaUrls,
    this.imageUrl,
    this.openingHoursText,
    this.visitRules,
    required this.categoryIds,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
    this.verificationStatus,
    this.confidenceScore,
    this.createdAt,
    this.createdByUserName,
    this.createdByUserId,
    this.creatorType,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    final rawVisitRules = json['visit_rules'];
    return PoiModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] ?? '').toString(),
      accessType: json['access_type'] as String,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      multimediaUrls: json['multimedia_urls'],
      imageUrl: json['image_url'] as String?,
      openingHoursText: json['opening_hours_text'] as String?,
      visitRules: rawVisitRules is Map<String, dynamic>
          ? VisitRulesModel.fromJson(rawVisitRules)
          : null,
      categoryIds: (json['category_ids'] as List<dynamic>? ?? [])
          .map((item) => (item as num).toInt())
          .toList(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      verificationStatus: json['verification_status'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      createdAt: _parseDateTime(json['created_at']),
      createdByUserName: _readCreatedByUserName(json),
      createdByUserId: json['created_by_user_id'] as String?,
      creatorType: json['creator_type'] as String?,
    );
  }

  MapPoint toMapPoint() {
    return MapPoint(
      id: id,
      name: name,
      description: PublicTextSanitizer.cleanOptional(description),
      phone: contactPhone,
      email: contactEmail,
      categoryIds: categoryIds,
      coordinates: LatLng(latitude, longitude),
      imageUrl: ApiConstants.resolveBackendUrl(
        _firstMediaUrl(imageUrl) ?? _firstMediaUrl(multimediaUrls),
      ),
      distanceMeters: distanceMeters,
      openingHoursText: openingHoursText,
      visitRules: visitRules?.toMapPointVisitRules(),
      verificationStatus: verificationStatus,
      confidenceScore: confidenceScore,
      createdAt: createdAt,
      createdByUserName: createdByUserName,
      createdByUserId: createdByUserId,
      creatorType: creatorType,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String? _readCreatedByUserName(Map<String, dynamic> json) {
    final direct =
        json['created_by_user_name'] ??
        json['creator_name'] ??
        json['created_by_name'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }
    final createdBy = json['created_by'] ?? json['creator'] ?? json['user'];
    if (createdBy is Map<String, dynamic>) {
      final nested = createdBy['name'] ?? createdBy['full_name'];
      if (nested != null && nested.toString().trim().isNotEmpty) {
        return nested.toString().trim();
      }
    }
    return null;
  }

  static String? _firstMediaUrl(dynamic media) {
    if (media is String && media.isNotEmpty) {
      return media;
    }

    if (media is List) {
      for (final item in media) {
        if (item is String && item.isNotEmpty) return item;
        if (item is Map) {
          final value = _firstMediaUrl(item);
          if (value != null) return value;
        }
      }
    }

    if (media is Map) {
      final preferredKeys = ['cover', 'image', 'url', 'principal', 'gallery'];
      for (final key in preferredKeys) {
        final value = media[key];
        if (value is String && value.isNotEmpty) return value;
        if (value is List && value.isNotEmpty) {
          final nested = _firstMediaUrl(value);
          if (nested != null) return nested;
        }
      }
    }

    return null;
  }
}

extension VisitRulesModelX on VisitRulesModel {
  MapPointVisitRules toMapPointVisitRules() {
    return MapPointVisitRules(
      isPrimaryExperience: isPrimaryExperience,
      requiresDaylight: requiresDaylight,
      nightSuitable: nightSuitable,
      latestRecommendedStartTime: latestRecommendedStartTime,
      accessNotes: accessNotes,
      confidence: confidence,
    );
  }
}
