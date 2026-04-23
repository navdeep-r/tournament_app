import 'package:google_sign_in/google_sign_in.dart';
import 'package:tournament_app/core/network/api_client.dart';
import 'package:tournament_app/core/storage/secure_storage.dart';
import 'package:tournament_app/core/constants/api_constants.dart';
import 'package:tournament_app/features/auth/data/models/user_model.dart';

class AuthRepository {
  final ApiClient _api;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthRepository(this._api);

  Future<UserModel> signInWithGoogle() async {
    // 1. Google Sign-In to get ID token
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    final idToken = await googleUser.authentication.then((auth) => auth.idToken);
    if (idToken == null) throw Exception('Failed to get Google ID token');

    // 2. Send to backend for verification and JWT generation
    try {
      final response = await _api.post(
        ApiConstants.authGoogle,
        data: {'id_token': idToken},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel(
        id: userJson['id'] as String,
        name: userJson['name'] as String? ?? 'Player',
        email: userJson['email'] as String? ?? '',
        photoUrl: userJson['profile_image'] as String? ?? userJson['photoUrl'] as String?,
        role: userJson['role'] as String? ?? 'user',
        createdAt: userJson['created_at'] != null
            ? DateTime.parse(userJson['created_at'] as String)
            : DateTime.now(),
      );

      // 3. Store JWT tokens
      await SecureStorage.saveAccessToken(data['access_token'] as String);
      await SecureStorage.saveRefreshToken(data['refresh_token'] as String);
      await SecureStorage.saveUserRole(user.role);
      await SecureStorage.saveUserId(user.id);

      return user;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<UserModel> signInDummy(String role) async {
    // For development/testing without backend
    return _createDummyUser(role, role == 'admin' ? 'Dummy Admin' : 'Dummy User');
  }

  Future<UserModel> _createDummyUser(String role, String name) async {
    final dummyUser = UserModel(
      id: role == 'admin' ? 'a_123' : 'u_123',
      name: name,
      email: 'dummy@example.com',
      photoUrl: null,
      role: role,
      createdAt: DateTime.now(),
    );

    // Store dummy tokens
    await SecureStorage.saveAccessToken('dummy_access_token_${role}_${DateTime.now().millisecondsSinceEpoch}');
    await SecureStorage.saveRefreshToken('dummy_refresh_token_${role}_${DateTime.now().millisecondsSinceEpoch}');
    await SecureStorage.saveUserRole(dummyUser.role);
    await SecureStorage.saveUserId(dummyUser.id);

    return dummyUser;
  }

  Future<void> signOut() async {
    try {
      // Call backend logout endpoint
      await _api.post(ApiConstants.authLogout);
    } catch (_) {
      // Continue with local cleanup even if API call fails
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore google sign out errors
    }
    
    await SecureStorage.clearAll();
  }

  Future<bool> hasValidSession() => SecureStorage.hasValidSession();

  Future<String?> getUserRole() => SecureStorage.getUserRole();
}
