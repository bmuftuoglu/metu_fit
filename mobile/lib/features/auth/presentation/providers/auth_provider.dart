import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/token_model.dart';
import '../../../../core/storage/secure_storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, bool? isLoading, String? error}) =>
      AuthState(
        status: status ?? this.status,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRemoteDatasource _datasource;

  @override
  AuthState build() {
    _datasource = AuthRemoteDatasource();
    _checkToken();
    return const AuthState();
  }

  Future<void> _checkToken() async {
    final token = await SecureStorageService.getAccessToken();
    state = state.copyWith(
      status: token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokens = await _datasource.login(email: email, password: password);
      await _saveTokens(tokens);
      state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokens = await _datasource.register(email: email, password: password, fullName: fullName);
      await _saveTokens(tokens);
      state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    final refresh = await SecureStorageService.getRefreshToken();
    if (refresh != null) {
      try {
        await _datasource.logout(refresh);
      } catch (_) {}
    }
    await SecureStorageService.clearTokens();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<void> _saveTokens(TokenModel tokens) async {
    await SecureStorageService.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  String _parseError(Object e) {
    if (e.toString().contains('409')) return 'Bu e-posta adresi zaten kayıtlı.';
    if (e.toString().contains('401')) return 'E-posta veya şifre hatalı.';
    if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
      return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
