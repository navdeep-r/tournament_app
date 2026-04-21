import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  // Tournaments CRUD
  Future<List<dynamic>> getTournaments() async {
    final res = await _api.get(ApiConstants.adminTournaments);
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTournament(
      Map<String, dynamic> data) async {
    final res = await _api.post(ApiConstants.adminTournaments, data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTournament(
      String id, Map<String, dynamic> data) async {
    final res = await _api.put(ApiConstants.adminTournamentById(id), data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteTournament(String id) async {
    await _api.delete(ApiConstants.adminTournamentById(id));
  }

  // Participant management
  Future<void> updateParticipantStatus(
      String participantId, String status) async {
    await _api.patch(
      ApiConstants.adminParticipantStatus(participantId),
      data: {'status': status},
    );
  }

  // Refund
  Future<void> issueRefund(String paymentId) async {
    await _api.patch(ApiConstants.adminPaymentRefund(paymentId));
  }

  // Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _api.get(ApiConstants.adminStats);
    return res.data as Map<String, dynamic>;
  }

  // Export CSV
  Future<String> exportParticipantsCSV() async {
    final res = await _api.get(ApiConstants.adminParticipantsExport);
    return res.data as String;
  }
}
