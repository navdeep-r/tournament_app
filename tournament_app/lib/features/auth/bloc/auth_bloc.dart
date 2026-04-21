import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tournament_app/features/auth/data/auth_repository.dart';
import 'package:tournament_app/features/auth/data/models/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthDummySignInRequested>(_onDummySignIn);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final hasSession = await _repo.hasValidSession();
      if (!hasSession) {
        emit(AuthUnauthenticated());
        return;
      }
      final role = await _repo.getUserRole();
      // Minimal user from stored role for routing
      emit(AuthAuthenticated(UserModel(
        id: '',
        name: '',
        email: '',
        role: role ?? 'user',
        createdAt: DateTime.now(),
      )));
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(
      AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDummySignIn(
      AuthDummySignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.signInDummy(event.role);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _repo.signOut();
    emit(AuthUnauthenticated());
  }
}
