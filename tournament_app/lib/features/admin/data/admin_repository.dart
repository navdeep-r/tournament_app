import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  // Tournaments CRUD
  Future<List<dynamic>> getTournaments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'id': 't_1', 'name': 'BGMI Pro League Season 4', 'status': 'upcoming'},
      {'id': 't_2', 'name': 'Free Fire Clash Squad', 'status': 'active'}
    ];
  }

  Future<Map<String, dynamic>> createTournament(
      Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'id': 't_new', ...data, 'status': 'upcoming'};
  }

  Future<Map<String, dynamic>> updateTournament(
      String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'id': id, ...data};
  }

  Future<void> deleteTournament(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Participant management
  Future<void> updateParticipantStatus(
      String participantId, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Refund
  Future<void> issueRefund(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'active_tournaments': 5,
      'total_participants': 1250,
      'total_revenue': 500000,
    };
  }

  // Export CSV
  Future<String> exportParticipantsCSV() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return "id,name,status\n1,Player One,active";
  }
}
