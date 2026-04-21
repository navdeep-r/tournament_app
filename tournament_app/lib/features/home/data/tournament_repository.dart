import 'package:tournament_app/core/network/api_client.dart';
import 'package:tournament_app/core/constants/api_constants.dart';
import 'package:tournament_app/features/home/data/models/tournament_model.dart';

class TournamentRepository {
  final ApiClient _api;
  TournamentRepository(this._api);

  final _dummyTournaments = <TournamentModel>[
    TournamentModel(
      id: 't_1',
      name: 'BGMI Pro League Season 4',
      description: 'The ultimate showdown for BGMI pro players. Show off your skills and win the prize pool!',
      bannerUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      startTime: DateTime.now().add(const Duration(hours: 2)),
      registrationDeadline: DateTime.now().add(const Duration(hours: 1)),
      maxParticipants: 100,
      registeredCount: 85,
      activeCount: 85,
      entryFeePaise: 5000,
      status: 'upcoming',
      rules: '1. No hacking or third-party apps.\n2. Fair play is strictly monitored.\n3. Disconnects within 5 mins can be appealed.',
      rounds: const [
        RoundSummary(id: 'r1', name: 'Qualifiers', status: 'pending', maxParticipants: 100),
      ],
      photoUrls: const [
        'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=400&q=80',
      ],
    ),
    TournamentModel(
      id: 't_2',
      name: 'Free Fire Clash Squad',
      description: 'Intense 4v4 action. Grab your squad and dominate the battlefield.',
      bannerUrl: 'https://images.unsplash.com/photo-1605901309584-818e25960b8f?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      maxParticipants: 50,
      registeredCount: 50,
      activeCount: 40,
      entryFeePaise: 0,
      status: 'active',
      rules: 'Standard Clash Squad rules. Auto-aim allowed. No emulators.',
      rounds: const [
        RoundSummary(id: 'r1', name: 'Quarter Finals', status: 'active', maxParticipants: 50),
      ],
      photoUrls: const [],
    ),
    TournamentModel(
      id: 't_3',
      name: 'Valorant Community Cup',
      description: '5v5 tactical shooter community tournament.',
      bannerUrl: 'https://images.unsplash.com/photo-1563986768494-4dee2763ff3f?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      startTime: DateTime.now().add(const Duration(days: 1)),
      maxParticipants: 32,
      registeredCount: 15,
      activeCount: 15,
      entryFeePaise: 10000,
      status: 'upcoming',
      rules: 'Current patch. All maps in rotation. BO1 until finals.',
      rounds: const [
        RoundSummary(id: 'r1', name: 'Group Stage', status: 'pending', maxParticipants: 32),
      ],
      photoUrls: const [],
    ),
    TournamentModel(
      id: 't_4',
      name: 'Global Chess Open',
      description: 'Rapid chess tournament open to all ratings.',
      bannerUrl: 'https://images.unsplash.com/photo-1529699211952-734e80c4d42b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      startTime: DateTime.now().add(const Duration(days: 2)),
      maxParticipants: 200,
      registeredCount: 198,
      activeCount: 198,
      entryFeePaise: 2500,
      status: 'upcoming',
      rules: '10+0 Rapid format. Lichess rules apply. No engine assistance.',
      rounds: const [
        RoundSummary(id: 'r1', name: 'Swiss Round 1', status: 'pending', maxParticipants: 200),
      ],
      photoUrls: const [],
    ),
  ];

  Future<List<TournamentModel>> getTodayActive() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _dummyTournaments.where((t) => t.isLive).toList();
  }

  Future<List<TournamentModel>> getUpcoming() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _dummyTournaments.where((t) => t.isUpcoming).toList();
  }

  Future<List<TournamentModel>> getTomorrow() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _dummyTournaments.where((t) => t.startTime.isAfter(DateTime.now().add(const Duration(days: 1)))).toList();
  }

  Future<List<ParticipationModel>> getUserHistory() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      ParticipationModel(
        id: 'p1',
        tournamentId: 't_2',
        tournamentName: 'Free Fire Clash Squad',
        queueNumber: 15,
        status: 'active',
        amountPaidPaise: 0,
        paymentId: 'pay_xyz',
        registeredAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ParticipationModel(
        id: 'p2',
        tournamentId: 't_1',
        tournamentName: 'BGMI Pro League Season 4',
        queueNumber: 42,
        status: 'eliminated',
        amountPaidPaise: 5000,
        paymentId: 'pay_abc',
        registeredAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  Future<TournamentModel> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _dummyTournaments.firstWhere((t) => t.id == id, orElse: () => _dummyTournaments.first);
  }
}
