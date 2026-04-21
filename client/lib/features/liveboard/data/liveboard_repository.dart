import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'models/liveboard_models.dart';

class LiveboardRepository {
  final ApiClient _api;
  LiveboardRepository(this._api);

  /// Fetch initial snapshot of all rounds + participants for a tournament.
  /// Called once on screen load; WebSocket then streams deltas.
  Future<List<RoundModel>> getRounds(String tournamentId) async {
    final roundsResponse = await _api.get(ApiConstants.tournamentRounds(tournamentId));
    final boardResponse = await _api.get(ApiConstants.liveboardByTournament(tournamentId));

    final roundRows =
        (roundsResponse.data['data'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();
    final participants =
        (boardResponse.data['data'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    if (roundRows.isEmpty) {
      final singleRoundParticipants = participants
          .map((p) => ParticipantModel.fromJson({
                ...p,
                'round_number': 1,
              }))
          .toList();
      return [
        RoundModel(
          roundNumber: 1,
          name: 'Round 1',
          status: 'active',
          participants: singleRoundParticipants,
        ),
      ];
    }

    final roundIdToNumber = <String, int>{};
    final rounds = roundRows.map((r) {
      final id = r['id'] as String;
      final roundNumber = (r['round_number'] as num).toInt();
      roundIdToNumber[id] = roundNumber;
      return RoundModel(
        roundNumber: roundNumber,
        name: r['name'] as String? ?? 'Round $roundNumber',
        status: r['status'] as String? ?? 'pending',
        participants: const [],
      );
    }).toList();

    final mappedParticipants = participants.map((p) {
      final roundId = p['round_id'] as String?;
      final roundNumber =
          roundId != null ? (roundIdToNumber[roundId] ?? 1) : 1;
      return ParticipantModel.fromJson({
        ...p,
        'round_number': roundNumber,
      });
    }).toList();

    return rounds
        .map((r) => RoundModel(
              roundNumber: r.roundNumber,
              name: r.name,
              status: r.status,
              participants: mappedParticipants
                  .where((p) => p.roundNumber == r.roundNumber)
                  .toList(),
            ))
        .toList();
  }

  /// Fetch a single round's participants (used after reconnect).
  Future<RoundModel> getRound(String tournamentId, int roundNumber) async {
    final rounds = await getRounds(tournamentId);
    return rounds.firstWhere(
      (r) => r.roundNumber == roundNumber,
      orElse: () => rounds.first,
    );
  }

  /// Returns the WebSocket URL for this tournament.
  String wsUrl(String tournamentId) =>
      ApiConstants.liveboardWs(tournamentId);
}
