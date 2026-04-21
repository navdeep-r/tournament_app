abstract class ApiConstants {
  static const String baseUrl = 'https://api.tournamenthub.com/v1';

  // Auth
  static const String authGoogle = '/auth/google';
  static const String authRefresh = '/auth/refresh';
  static const String authPhoneSendOtp = '/auth/phone/send-otp';
  static const String authPhoneVerifyOtp = '/auth/phone/verify-otp';

  // Tournaments
  static const String tournaments = '/tournaments';
  static String tournamentById(String id) => '/tournaments/$id';
  static const String tournamentsTodayActive = '/tournaments/today/active';
  static const String tournamentsUpcoming = '/tournaments/upcoming';
  static const String tournamentsTomorrow = '/tournaments/tomorrow';
  static const String tournamentsHistory = '/tournaments/history';

  // Participants
  static String tournamentParticipants(String id) => '/tournaments/$id/participants';
  static String tournamentRegister(String id) => '/tournaments/$id/register';

  // Liveboard
  static String liveboardWs(String tournamentId) =>
      'wss://api.tournamenthub.com/ws/tournament/$tournamentId/liveboard';

  // Payments
  static const String paymentReferralValidate = '/payments/referral/validate';
  static const String paymentOrderCreate = '/payments/orders/create';
  static const String paymentVerify = '/payments/verify';
  static String paymentOrderStatus(String orderId) =>
      '/payments/orders/$orderId/status';

  // Admin
  static const String adminTournaments = '/admin/tournaments';
  static String adminTournamentById(String id) => '/admin/tournaments/$id';
  static String adminParticipantStatus(String id) =>
      '/admin/participants/$id/status';
  static const String adminParticipantsExport = '/admin/participants/export';
  static String adminPaymentRefund(String paymentId) =>
      '/admin/payments/$paymentId/refund';
  static const String adminStats = '/admin/stats';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
