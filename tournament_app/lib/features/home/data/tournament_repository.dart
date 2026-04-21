import 'package:tournament_app/core/network/api_client.dart';
import 'package:tournament_app/core/constants/api_constants.dart';
import 'package:tournament_app/features/home/data/models/tournament_model.dart';

class TournamentRepository {
  final ApiClient _api;
  TournamentRepository(this._api);

  /// Fetch list of tournaments (with optional filtering)
  Future<List<TournamentModel>> getTournaments({
    String? status, // 'active', 'upcoming', etc.
    List<String>? statuses,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.tournaments,
        queryParameters: statuses != null && statuses.isNotEmpty
            ? {'status': statuses}
            : status != null
                ? {'status': status}
                : null,
      );

      final payload = response.data['data'] as List<dynamic>;
      final tournaments = payload
          .map((t) => TournamentModel.fromJson(t))
          .toList();
      return tournaments;
    } catch (e) {
      throw Exception('Failed to fetch tournaments: $e');
    }
  }

  /// Fetch today's active tournaments
  Future<List<TournamentModel>> getTodayActive() async {
    return getTournaments(status: 'live');
  }

  /// Fetch upcoming tournaments
  Future<List<TournamentModel>> getUpcoming() async {
    final tournaments = await getTournaments();
    return tournaments
        .where((t) => t.status == 'upcoming' || t.status == 'registration_open')
        .toList();
  }

  /// Fetch tomorrow's tournaments (optional - backend may not support this)
  Future<List<TournamentModel>> getTomorrow() async {
    try {
      final response = await _api.get(
        ApiConstants.tournaments,
      );
      final payload = response.data['data'] as List<dynamic>;
      final tournaments = payload
          .map((t) => TournamentModel.fromJson(t))
          .where((t) => t.status == 'upcoming' || t.status == 'registration_open')
          .toList();
      
      // Filter for tomorrow's start times if needed
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      return tournaments.where((t) => 
        t.startTime.year == tomorrow.year &&
        t.startTime.month == tomorrow.month &&
        t.startTime.day == tomorrow.day
      ).toList();
    } catch (e) {
      return getTournaments(); // Fallback to all tournaments
    }
  }

  /// Fetch user's participation history
  Future<List<ParticipationModel>> getUserHistory() async {
    try {
      final response = await _api.get(ApiConstants.participantsMy);

      final payload = response.data['data'] as List<dynamic>;
      final participations = payload
          .map((p) => ParticipationModel.fromJson(p))
          .toList();
      return participations;
    } catch (e) {
      throw Exception('Failed to fetch participation history: $e');
    }
  }

  /// Fetch single tournament by ID
  Future<TournamentModel> getById(String id) async {
    try {
      final response = await _api.get(ApiConstants.tournamentById(id));
      final payload = response.data['data'] as Map<String, dynamic>;
      return TournamentModel.fromJson(payload);
    } catch (e) {
      throw Exception('Failed to fetch tournament: $e');
    }
  }

  /// Fetch rounds for a tournament
  Future<List<RoundSummary>> getRounds(String tournamentId) async {
    try {
      final response = await _api.get(
        ApiConstants.tournamentRounds(tournamentId),
      );

      final payload = response.data['data'] as List<dynamic>;
      final rounds = payload
          .map((r) => RoundSummary.fromJson(r))
          .toList();
      return rounds;
    } catch (e) {
      throw Exception('Failed to fetch rounds: $e');
    }
  }
}
