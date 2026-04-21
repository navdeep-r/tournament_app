// ═══════════════════════════════════════════════════════════
// auth_event.dart
// ═══════════════════════════════════════════════════════════
part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthDummySignInRequested extends AuthEvent {
  final String role;
  AuthDummySignInRequested(this.role);
}
