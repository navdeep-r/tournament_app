import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'models/liveboard_models.dart';

class LiveboardRepository {
  final ApiClient _api;
  LiveboardRepository(this._api);

  final _dummyRounds = const [
    RoundModel(
      roundNumber: 1,
      name: 'Qualifiers',
      status: 'active',
      participants: [
        ParticipantModel(id: 'u1', queueNumber: 1, name: 'Player One', photoUrl: null, status: ParticipantStatus.active, roundNumber: 1),
        ParticipantModel(id: 'u2', queueNumber: 2, name: 'Player Two', photoUrl: null, status: ParticipantStatus.eliminated, roundNumber: 1),
        ParticipantModel(id: 'u3', queueNumber: 3, name: 'Player Three', photoUrl: null, status: ParticipantStatus.advancing, roundNumber: 1),
      ],
    ),
    RoundModel(
      roundNumber: 2,
      name: 'Semi-Finals',
      status: 'pending',
      participants: [],
    ),
  ];

  /// Fetch initial snapshot of all rounds + participants for a tournament.
  /// Called once on screen load; WebSocket then streams deltas.
  Future<List<RoundModel>> getRounds(String tournamentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _dummyRounds;
  }

  /// Fetch a single round's participants (used after reconnect).
  Future<RoundModel> getRound(String tournamentId, int roundNumber) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dummyRounds.firstWhere((r) => r.roundNumber == roundNumber, orElse: () => _dummyRounds.first);
  }

  /// Returns the WebSocket URL for this tournament.
  String wsUrl(String tournamentId) =>
      ApiConstants.liveboardWs(tournamentId);
}
