import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_RetryRequest> _queue = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      final completer = Completer<Response>();
      _queue.add(_RetryRequest(err.requestOptions, completer));
      try {
        handler.resolve(await completer.future);
      } catch (e) {
        handler.next(err);
      }
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken == null) throw Exception('No refresh token');

      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {}),
      );

      final newAccessToken = response.data['access_token'] as String;
      await SecureStorageService.saveAccessToken(newAccessToken);

      // Kuyruktaki tüm istekleri yeni tokenla tekrarla
      for (final r in _queue) {
        r.options.headers['Authorization'] = 'Bearer $newAccessToken';
        try {
          r.completer.complete(await _dio.fetch(r.options));
        } catch (e) {
          r.completer.completeError(e);
        }
      }
      _queue.clear();

      // Orijinal isteği tekrarla
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      handler.resolve(await _dio.fetch(err.requestOptions));
    } catch (e) {
      await SecureStorageService.clearTokens();
      for (final r in _queue) {
        r.completer.completeError(e);
      }
      _queue.clear();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

class _RetryRequest {
  final RequestOptions options;
  final Completer<Response> completer;
  _RetryRequest(this.options, this.completer);
}
