import 'package:google_sign_in/google_sign_in.dart';
import 'package:tournament_app/core/network/api_client.dart';
import 'package:tournament_app/core/storage/secure_storage.dart';
import 'package:tournament_app/features/auth/data/models/user_model.dart';

class AuthRepository {
  final ApiClient _api;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthRepository(this._api);

  Future<UserModel> signInWithGoogle() async {
    // 1. Google Sign-In
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    // 2. Mock Backend Response
    await Future.delayed(const Duration(milliseconds: 500));
    final dummyUser = UserModel(
      id: 'u_123',
      name: googleUser.displayName ?? 'Dummy User',
      email: googleUser.email,
      photoUrl: googleUser.photoUrl,
      role: 'user', // You can change this to 'admin' to test admin mode
      createdAt: DateTime.now(),
    );

    // 3. Store tokens
    await SecureStorage.saveAccessToken('dummy_access_token');
    await SecureStorage.saveRefreshToken('dummy_refresh_token');

    await SecureStorage.saveUserRole(dummyUser.role);
    await SecureStorage.saveUserId(dummyUser.id);

    return dummyUser;
  }

  Future<UserModel> signInDummy(String role) async {
    // 1. Mock dummy user
    final dummyUser = UserModel(
      id: role == 'admin' ? 'a_123' : 'u_123',
      name: role == 'admin' ? 'Dummy Admin' : 'Dummy User',
      email: 'dummy@example.com',
      photoUrl: null,
      role: role,
      createdAt: DateTime.now(),
    );

    // 2. Store dummy tokens and data
    await SecureStorage.saveAccessToken('dummy_access_token');
    await SecureStorage.saveRefreshToken('dummy_refresh_token');
    await SecureStorage.saveUserRole(dummyUser.role);
    await SecureStorage.saveUserId(dummyUser.id);

    return dummyUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await SecureStorage.clearAll();
  }

  Future<bool> hasValidSession() => SecureStorage.hasValidSession();

  Future<String?> getUserRole() => SecureStorage.getUserRole();
}
