import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  Exception _buildDioException(DioException e, String fallbackMessage) {
    final payload = e.response?.data;
    if (payload is Map<String, dynamic>) {
      final error = payload['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message']?.toString();
        final details = error['details'];
        if (details is List) {
          final detailText = details
              .whereType<Map<String, dynamic>>()
              .map((d) => d['message']?.toString())
              .whereType<String>()
              .where((m) => m.trim().isNotEmpty)
              .join(', ');
          if (detailText.isNotEmpty) {
            return Exception(message != null && message.isNotEmpty
                ? '$message: $detailText'
                : detailText);
          }
        }
        if (message != null && message.isNotEmpty) {
          return Exception(message);
        }
      }
      final rootMessage = payload['message']?.toString();
      if (rootMessage != null && rootMessage.isNotEmpty) {
        return Exception(rootMessage);
      }
    }
    return Exception(fallbackMessage);
  }

  // Tournaments CRUD
  Future<List<dynamic>> getTournaments() async {
    final response = await _api.get(ApiConstants.adminTournaments);
    return response.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTournamentById(String id) async {
    final response = await _api.get(ApiConstants.tournamentById(id));
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTournament(
      Map<String, dynamic> data) async {
    final payload = {...data, 'status': 'upcoming'};
    try {
      final response = await _api.post(ApiConstants.tournaments, data: payload);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _buildDioException(e, 'Failed to create tournament');
    }
  }

  Future<Map<String, dynamic>> updateTournament(
      String id, Map<String, dynamic> data) async {
    debugPrint('UPDATE URL: ${ApiConstants.tournamentById(id)}');
    debugPrint('UPDATE PAYLOAD: $data');
    try {
      final response = await _api.put(ApiConstants.tournamentById(id), data: data);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _buildDioException(e, 'Failed to update tournament');
    }
  }

  Future<void> deleteTournament(String id) async {
    await _api.delete(ApiConstants.tournamentById(id));
  }

  // Participant management
  Future<void> updateParticipantStatus(
      String participantId, String status) async {
    await _api.patch('/admin/participants/$participantId/status', data: {'status': status});
  }

  // Refund
  Future<void> issueRefund(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('/admin/dashboard');
    return response.data['data'] as Map<String, dynamic>;
  }

  // Export CSV
  Future<String> exportParticipantsCSV() async {
    final response = await _api.get('/admin/participants/export');
    return response.data.toString();
  }
}
