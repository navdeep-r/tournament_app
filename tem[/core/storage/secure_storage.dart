class SecureStorage {
  static final Map<String, String> _dummyStorage = {};

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRoleKey = 'user_role';
  static const _userIdKey = 'user_id';

  // Access token
  static Future<void> saveAccessToken(String token) async =>
      _dummyStorage[_accessTokenKey] = token;

  static Future<String?> getAccessToken() async =>
      _dummyStorage[_accessTokenKey];

  // Refresh token
  static Future<void> saveRefreshToken(String token) async =>
      _dummyStorage[_refreshTokenKey] = token;

  static Future<String?> getRefreshToken() async =>
      _dummyStorage[_refreshTokenKey];

  // User role: "user" | "admin"
  static Future<void> saveUserRole(String role) async =>
      _dummyStorage[_userRoleKey] = role;

  static Future<String?> getUserRole() async =>
      _dummyStorage[_userRoleKey];

  // User id
  static Future<void> saveUserId(String id) async =>
      _dummyStorage[_userIdKey] = id;

  static Future<String?> getUserId() async =>
      _dummyStorage[_userIdKey];

  // Clear all — called on logout
  static Future<void> clearAll() async => _dummyStorage.clear();

  static Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
