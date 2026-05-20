import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

class ProfileRemoteDatasource {
  final Dio _dio = DioClient.instance;

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile({
    String? fullName,
    double? heightCm,
    double? weightKg,
    int? age,
    int? goalCalories,
  }) async {
    final response = await _dio.patch(ApiEndpoints.me, data: {
      'full_name': fullName,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'age': age,
      'goal_calories': goalCalories,
    }..removeWhere((_, v) => v == null));
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
