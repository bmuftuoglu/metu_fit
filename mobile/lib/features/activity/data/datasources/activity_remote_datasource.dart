import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/activity_model.dart';

class ActivityRemoteDatasource {
  final Dio _dio = DioClient.instance;

  Future<List<ActivityModel>> getActivities({int limit = 20, int offset = 0}) async {
    final response = await _dio.get(
      ApiEndpoints.activities,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return (response.data as List)
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ActivityModel> getActivity(String id) async {
    final response = await _dio.get(ApiEndpoints.activity(id));
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> createActivity({
    required String activityType,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    double? distanceMeters,
    double? caloriesBurned,
    double? avgSpeedKmh,
    List<Map<String, dynamic>>? routePoints,
  }) async {
    final response = await _dio.post(ApiEndpoints.activities, data: {
      'activity_type': activityType,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'duration_seconds': durationSeconds,
      'distance_meters': distanceMeters,
      'calories_burned': caloriesBurned,
      'avg_speed_kmh': avgSpeedKmh,
      'route_points': routePoints,
    }..removeWhere((_, v) => v == null));
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteActivity(String id) async {
    await _dio.delete(ApiEndpoints.activity(id));
  }
}
