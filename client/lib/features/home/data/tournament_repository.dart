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

  /// Fetch scheduled tournaments ordered by nearest start time.
  Future<List<TournamentModel>> getScheduled() async {
    final tournaments = await getTournaments();
    final now = DateTime.now();
    final scheduled = tournaments.where((t) {
      return t.startTime.isAfter(now) &&
          (t.status == 'upcoming' ||
              t.status == 'registration_open' ||
              t.status == 'registration_closed');
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return scheduled;
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
