import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/core/storage/token_storage.dart';
import 'package:pair/features/auth/models/auth_response.dart';
import 'package:pair/features/auth/models/user_model.dart';

class AuthService {
  AuthService(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStore _tokenStorage;

  Future<UserModel> me() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/auth/me',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return UserModel.fromJson(response.data!);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String timezone,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'timezone': timezone,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<void> persistToken(String token) => _tokenStorage.writeToken(token);

  Future<void> clearToken() => _tokenStorage.clearToken();

  Future<bool> hasToken() => _tokenStorage.hasToken();

  /// Validates the session and returns the next route.
  Future<String> resolvePostAuthRoute() async {
    try {
      await me();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await clearToken();
        return AppRoutes.login;
      }
      rethrow;
    }

    final hasActivePod = await _hasActivePod();
    return hasActivePod ? AppRoutes.podHome : AppRoutes.goalCategory;
  }

  Future<String> resolveSplashRoute() async {
    if (!await hasToken()) {
      return AppRoutes.login;
    }
    return resolvePostAuthRoute();
  }

  Future<bool> _hasActivePod() async {
    final response = await _api.get<List<dynamic>>(
      '/pods',
      fromJsonT: (json) => (json as List).toList(),
    );

    final pods = response.data ?? [];
    return pods.any((pod) {
      if (pod is Map<String, dynamic>) {
        return pod['status'] == 'active';
      }
      return false;
    });
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
