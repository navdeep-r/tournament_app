import 'package:tournament_app/features/home/data/models/tournament_model.dart';
import 'package:tournament_app/features/liveboard/data/models/liveboard_models.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';

/// Synthetic data for development and UI testing.
/// Swap your repositories to return these instead of making real API calls.
abstract class MockData {
  // ── Tournaments ────────────────────────────────────────────────────────────

  static TournamentModel get activeTournament => TournamentModel(
        id: 'tour_active_001',
        name: 'The Grand Summer League',
        description:
            'India\'s biggest live trading tournament. 500 participants battle '
            'through 4 elimination rounds to claim the prize.',
        bannerUrl: null,
        startTime:
            DateTime.now().subtract(const Duration(hours: 1)),
        registrationDeadline: null,
        maxParticipants: 500,
        registeredCount: 378,
        activeCount: 124,
        entryFeePaise: 20000, // ₹200
        status: 'active',
        rules:
            '1. All participants must be present at the designated table.\n'
            '2. Trading rounds last 45 minutes each.\n'
            '3. Participants eliminated in Round 1 receive no refund.\n'
            '4. Mobile phones are not permitted during active rounds.\n'
            '5. Organiser decisions are final.',
        rounds: [
          RoundSummary(
              id: 'r1',
              name: 'Round 1 — Qualifier',
              scheduledAt:
                  DateTime.now().subtract(const Duration(minutes: 50)),
              status: 'completed',
              maxParticipants: 500),
          RoundSummary(
              id: 'r2',
              name: 'Round 2 — Semifinals',
              scheduledAt: DateTime.now().add(const Duration(minutes: 20)),
              status: 'active',
              maxParticipants: 200),
          RoundSummary(
              id: 'r3',
              name: 'Round 3 — Finals',
              scheduledAt: DateTime.now().add(const Duration(hours: 2)),
              status: 'pending',
              maxParticipants: 50),
        ],
        photoUrls: [],
      );

  static TournamentModel get upcomingTournament => TournamentModel(
        id: 'tour_upcoming_001',
        name: 'Evening Traders Cup',
        description:
            'A fast-paced 2-round knockout tournament. Entry limited to 100 '
            'participants. Winner takes all.',
        bannerUrl: null,
        startTime: DateTime.now().add(const Duration(hours: 4)),
        registrationDeadline:
            DateTime.now().add(const Duration(hours: 3)),
        maxParticipants: 100,
        registeredCount: 73,
        activeCount: 0,
        entryFeePaise: 10000, // ₹100
        status: 'upcoming',
        rules:
            '1. Two rounds: Qualifier and Final.\n'
            '2. Top 10 from Round 1 advance to the Final.\n'
            '3. Registration closes 1 hour before start.',
        rounds: [
          RoundSummary(
              id: 'r1',
              name: 'Round 1',
              scheduledAt: DateTime.now().add(const Duration(hours: 4)),
              status: 'pending',
              maxParticipants: 100),
          RoundSummary(
              id: 'r2',
              name: 'Finals',
              scheduledAt: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
              status: 'pending',
              maxParticipants: 10),
        ],
        photoUrls: [],
      );

  static List<TournamentModel> get tournamentList => [
        activeTournament,
        upcomingTournament,
        _tomorrowTournament,
      ];

  static TournamentModel get _tomorrowTournament => TournamentModel(
        id: 'tour_tomorrow_001',
        name: 'Weekend Warriors',
        description: 'Open to all. 4 rounds, 250 participants.',
        bannerUrl: null,
        startTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
        registrationDeadline:
            DateTime.now().add(const Duration(hours: 20)),
        maxParticipants: 250,
        registeredCount: 140,
        activeCount: 0,
        entryFeePaise: 15000, // ₹150
        status: 'upcoming',
        rules: 'Standard rules apply.',
        rounds: [],
        photoUrls: [],
      );

  static List<ParticipationModel> get participationHistory => [
        ParticipationModel(
          id: 'part_001',
          tournamentId: 'tour_old_001',
          tournamentName: 'Spring League 2024',
          queueNumber: 12,
          status: 'winner',
          amountPaidPaise: 20000,
          paymentId: 'pay_SpringLeague2024',
          registeredAt: DateTime.now()
              .subtract(const Duration(days: 30)),
        ),
        ParticipationModel(
          id: 'part_002',
          tournamentId: 'tour_old_002',
          tournamentName: 'Monsoon Cup',
          queueNumber: 87,
          status: 'eliminated',
          amountPaidPaise: 10000,
          paymentId: 'pay_MonsoonCup',
          registeredAt: DateTime.now()
              .subtract(const Duration(days: 15)),
        ),
      ];

  // ── Liveboard ──────────────────────────────────────────────────────────────

  static List<RoundModel> get liveboardRounds => [
        RoundModel(
          roundNumber: 1,
          name: 'Round 1 — Qualifier',
          status: 'completed',
          participants: _generateParticipants(20, round: 1),
        ),
        RoundModel(
          roundNumber: 2,
          name: 'Round 2 — Semifinals',
          status: 'active',
          participants: _generateParticipants(10, round: 2),
        ),
      ];

  static List<ParticipantModel> _generateParticipants(int count,
      {required int round}) {
    return List.generate(count, (i) {
      final status = round == 1
          ? (i < count ~/ 2
              ? ParticipantStatus.advancing
              : ParticipantStatus.eliminated)
          : (i < 3
              ? ParticipantStatus.active
              : ParticipantStatus.eliminated);
      return ParticipantModel(
        id: 'p_r${round}_$i',
        queueNumber: i + 1,
        name: _names[i % _names.length],
        status: status,
        roundNumber: round,
      );
    });
  }

  // ── Payment ────────────────────────────────────────────────────────────────

  static PaymentOrder get paymentOrder => PaymentOrder(
        orderId: 'order_MockXXXXXXXXX',
        tournamentId: 'tour_upcoming_001',
        tournamentName: 'Evening Traders Cup',
        amountPaise: 10000,
        originalAmountPaise: 10000,
        discountPaise: 0,
        currency: 'INR',
        receipt: 'rcpt_mock_001',
        userPhone: '+919876543210',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        status: 'created',
      );

  static PaymentOrder get discountedOrder => PaymentOrder(
        orderId: 'order_MockDiscount',
        tournamentId: 'tour_upcoming_001',
        tournamentName: 'Evening Traders Cup',
        amountPaise: 8000,
        originalAmountPaise: 10000,
        discountPaise: 2000,
        currency: 'INR',
        receipt: 'rcpt_mock_002',
        userPhone: '+919876543210',
        referralCode: 'FRIEND20',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        status: 'created',
      );

  static ReferralCode get validReferral => const ReferralCode(
        code: 'FRIEND20',
        discountType: 'percent',
        discountValue: 20,
        maxUses: 100,
        usedCount: 42,
        isValid: true,
      );

  static ReferralCode get invalidReferral => const ReferralCode(
        code: 'EXPIRED',
        discountType: 'percent',
        discountValue: 10,
        maxUses: 50,
        usedCount: 50,
        isValid: false,
        errorMessage: 'This referral code has expired.',
      );

  // ── Names sample data ──────────────────────────────────────────────────────
  static const _names = [
    'Arjun Sharma', 'Priya Patel', 'Rohan Gupta', 'Ananya Singh',
    'Vikram Nair', 'Sneha Reddy', 'Karan Mehta', 'Divya Iyer',
    'Rahul Kumar', 'Pooja Joshi', 'Aditya Verma', 'Kavya Menon',
    'Siddharth Das', 'Riya Chatterjee', 'Amit Yadav', 'Nisha Kapoor',
    'Dhruv Malhotra', 'Simran Bhatt', 'Raj Pillai', 'Meera Agarwal',
  ];
}
