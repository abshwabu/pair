import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'auth_token';

/// Persists the Sanctum bearer token.
abstract class TokenStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clearToken();
  Future<bool> hasToken();
}

/// Platform secure storage implementation.
class SecureTokenStorage implements TokenStore {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  @override
  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}

/// In-memory implementation for tests.
class InMemoryTokenStorage implements TokenStore {
  String? _token;

  @override
  Future<void> clearToken() async => _token = null;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;
}

/// Backwards-compatible alias used by [tokenStorageProvider].
typedef TokenStorage = SecureTokenStorage;

final tokenStorageProvider = Provider<TokenStore>(
  (ref) => SecureTokenStorage(),
);
