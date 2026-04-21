import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'models/liveboard_models.dart';

class LiveboardRepository {
  final ApiClient _api;
  LiveboardRepository(this._api);

  /// Fetch initial snapshot of all rounds + participants for a tournament.
  /// Called once on screen load; WebSocket then streams deltas.
  Future<List<RoundModel>> getRounds(String tournamentId) async {
    final res = await _api.get(
        '${ApiConstants.tournamentById(tournamentId)}/liveboard');
    final data = res.data as Map<String, dynamic>;
    final rounds = (data['rounds'] as List<dynamic>? ?? [])
        .map((r) => RoundModel.fromJson(r as Map<String, dynamic>))
        .toList();
    return rounds;
  }

  /// Fetch a single round's participants (used after reconnect).
  Future<RoundModel> getRound(String tournamentId, int roundNumber) async {
    final res = await _api.get(
        '${ApiConstants.tournamentById(tournamentId)}/liveboard/rounds/$roundNumber');
    return RoundModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Returns the WebSocket URL for this tournament.
  String wsUrl(String tournamentId) =>
      ApiConstants.liveboardWs(tournamentId);
}
