import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'models/tournament_model.dart';

class TournamentRepository {
  final ApiClient _api;
  TournamentRepository(this._api);

  Future<List<TournamentModel>> getTodayActive() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      TournamentModel(
        id: 't1',
        name: 'Daily Rumble',
        description: 'A fun daily tournament',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        maxParticipants: 100,
        registeredCount: 80,
        activeCount: 80,
        entryFeePaise: 5000, // ₹50
        status: 'active',
        rules: 'Standard Rules',
        rounds: [],
        photoUrls: [],
      )
    ];
  }

  Future<List<TournamentModel>> getUpcoming() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      TournamentModel(
        id: 't2',
        name: 'Evening Clash',
        description: 'Competitive evening action',
        startTime: DateTime.now().add(const Duration(hours: 4)),
        maxParticipants: 50,
        registeredCount: 20,
        activeCount: 0,
        entryFeePaise: 10000, // ₹100
        status: 'upcoming',
        rules: 'Standard Rules',
        rounds: [],
        photoUrls: [],
      )
    ];
  }

  Future<List<TournamentModel>> getTomorrow() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      TournamentModel(
        id: 't3',
        name: 'Tomorrow Showdown',
        description: 'Big prize pool for tomorrow',
        startTime: DateTime.now().add(const Duration(days: 1)),
        maxParticipants: 200,
        registeredCount: 15,
        activeCount: 0,
        entryFeePaise: 25000, // ₹250
        status: 'upcoming',
        rules: 'Standard Rules',
        rounds: [],
        photoUrls: [],
      )
    ];
  }

  Future<List<ParticipationModel>> getUserHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ParticipationModel(
        id: 'p1',
        tournamentId: 't0',
        tournamentName: 'Past Glory Tourney',
        queueNumber: 42,
        status: 'winner',
        amountPaidPaise: 5000,
        paymentId: 'pay123',
        registeredAt: DateTime.now().subtract(const Duration(days: 2)),
      )
    ];
  }

  Future<TournamentModel> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return TournamentModel(
      id: id,
      name: 'Details for Tournament $id',
      description: 'Dummy detailed view',
      startTime: DateTime.now(),
      maxParticipants: 100,
      registeredCount: 50,
      activeCount: 0,
      entryFeePaise: 5000,
      status: 'upcoming',
      rules: 'Some rules here',
      rounds: [],
      photoUrls: [],
    );
  }
}
