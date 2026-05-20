class ActivityRouteModel {
  final List<dynamic> routePoints;
  final double? bboxNorth;
  final double? bboxSouth;
  final double? bboxEast;
  final double? bboxWest;

  const ActivityRouteModel({
    required this.routePoints,
    this.bboxNorth,
    this.bboxSouth,
    this.bboxEast,
    this.bboxWest,
  });

  factory ActivityRouteModel.fromJson(Map<String, dynamic> json) => ActivityRouteModel(
        routePoints: json['route_points'] as List? ?? [],
        bboxNorth: (json['bbox_north'] as num?)?.toDouble(),
        bboxSouth: (json['bbox_south'] as num?)?.toDouble(),
        bboxEast: (json['bbox_east'] as num?)?.toDouble(),
        bboxWest: (json['bbox_west'] as num?)?.toDouble(),
      );
}

class ActivityModel {
  final String id;
  final String activityType;
  final String startedAt;
  final String endedAt;
  final int durationSeconds;
  final double? distanceMeters;
  final double? caloriesBurned;
  final double? avgSpeedKmh;
  final ActivityRouteModel? route;
  final String createdAt;

  const ActivityModel({
    required this.id,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    this.distanceMeters,
    this.caloriesBurned,
    this.avgSpeedKmh,
    this.route,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        id: json['id'] as String,
        activityType: json['activity_type'] as String,
        startedAt: json['started_at'] as String,
        endedAt: json['ended_at'] as String,
        durationSeconds: json['duration_seconds'] as int,
        distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
        caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
        avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble(),
        route: json['route'] != null
            ? ActivityRouteModel.fromJson(json['route'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] as String,
      );
}
