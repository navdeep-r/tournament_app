import 'package:flutter/foundation.dart';

abstract class ApiConstants {
  // Base URL - Update this based on your deployment
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api'; // Default for mobile (Android emulator)
  }

  // Auth
  static const String authGoogle = '/auth/google';
  static const String authRefresh = '/auth/refresh';
  static const String authPhoneSendOtp = '/auth/phone/send-otp';
  static const String authPhoneVerifyOtp = '/auth/phone/verify-otp';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  // Tournaments
  static const String tournaments = '/tournaments';
  static String tournamentById(String id) => '/tournaments/$id';
  static String tournamentRounds(String id) => '/tournaments/$id/rounds';
  static String tournamentParticipants(String id) => '/tournaments/$id/participants';
  static String tournamentMyRegistration(String id) => '/tournaments/$id/my-registration';
  static String tournamentReferralValidate(String id) =>
      '/tournaments/$id/referral/validate';

  // Participants
  static const String participantsMy = '/participants/my';
  static String tournamentRegister(String id) => '/tournaments/$id/register';

  // Liveboard
  static String liveboardByTournament(String tournamentId) =>
      '/liveboard/$tournamentId';
  static String liveboardByRound(String tournamentId, String roundId) =>
      '/liveboard/$tournamentId/round/$roundId';
  static String liveboardWs(String tournamentId) {
    final host = kIsWeb ? 'localhost:3000' : '10.0.2.2:3000';
    return 'ws://$host/ws/tournament/$tournamentId';
  }

  // Admin
  static const String adminTournaments = '/admin/tournaments';
  static String adminTournamentById(String id) => '/admin/tournaments/$id';
  static String adminTournamentStatus(String id) => '/admin/tournaments/$id/status';
  static const String adminStats = '/admin/stats';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
