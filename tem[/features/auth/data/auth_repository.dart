import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/user_model.dart';

class AuthRepository {
  // ignore: unused_field
  final ApiClient _api;

  AuthRepository(this._api);

  Future<UserModel> signInWithGoogle() async {
    // 1. Dummy Sign-In (Skipping Google Sign-In and API for now)
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    final user = UserModel(
      id: 'dummy_user_1',
      name: 'Dummy Player',
      email: 'player@dummy.com',
      role: 'user',
      createdAt: DateTime.now(),
    );

    await SecureStorage.saveAccessToken('dummy_access_token');
    await SecureStorage.saveRefreshToken('dummy_refresh_token');
    await SecureStorage.saveUserRole(user.role);
    await SecureStorage.saveUserId(user.id);

    return user;
  }

  Future<void> signOut() async {
    await SecureStorage.clearAll();
  }

  Future<bool> hasValidSession() => SecureStorage.hasValidSession();

  Future<String?> getUserRole() => SecureStorage.getUserRole();
}
