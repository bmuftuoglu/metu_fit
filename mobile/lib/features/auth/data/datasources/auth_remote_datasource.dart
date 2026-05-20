import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/token_model.dart';

class AuthRemoteDatasource {
  final Dio _dio = DioClient.instance;

  Future<TokenModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {'email': email, 'password': password, 'full_name': fullName},
    );
    return TokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TokenModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return TokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiEndpoints.logout, data: {'refresh_token': refreshToken});
  }
}
