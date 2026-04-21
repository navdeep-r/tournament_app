import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRoleKey = 'user_role';
  static const _userIdKey = 'user_id';

  // Access token
  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  // Refresh token
  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  // User role: "user" | "admin"
  static Future<void> saveUserRole(String role) =>
      _storage.write(key: _userRoleKey, value: role);

  static Future<String?> getUserRole() =>
      _storage.read(key: _userRoleKey);

  // User id
  static Future<void> saveUserId(String id) =>
      _storage.write(key: _userIdKey, value: id);

  static Future<String?> getUserId() =>
      _storage.read(key: _userIdKey);

  // Clear all — called on logout
  static Future<void> clearAll() => _storage.deleteAll();

  static Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
