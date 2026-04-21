// ═══════════════════════════════════════════════════════
// tournament_model.dart
// ═══════════════════════════════════════════════════════
class TournamentModel {
  final String id;
  final String name;
  final String description;
  final String? bannerUrl;
  final DateTime startTime;
  final DateTime? registrationDeadline;
  final int maxParticipants;
  final int registeredCount;
  final int activeCount;
  final int entryFeePaise;
  final String status; // 'upcoming' | 'active' | 'completed'
  final String rules;
  final List<RoundSummary> rounds;
  final List<String> photoUrls;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.description,
    this.bannerUrl,
    required this.startTime,
    this.registrationDeadline,
    required this.maxParticipants,
    required this.registeredCount,
    required this.activeCount,
    required this.entryFeePaise,
    required this.status,
    required this.rules,
    required this.rounds,
    required this.photoUrls,
  });

  bool get isLive => status == 'active';
  bool get isUpcoming => status == 'upcoming' || status == 'registration_open';
  bool get isCompleted => status == 'completed' || status == 'cancelled';
  int get spotsLeft => maxParticipants - registeredCount;
  double get entryFeeRupees => entryFeePaise / 100;
  String get entryFeeFormatted => '₹${entryFeeRupees.toStringAsFixed(0)}';

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      TournamentModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        bannerUrl:
            json['banner_url'] as String? ?? json['banner_image_url'] as String?,
        startTime: DateTime.parse(
            (json['start_time'] ?? json['starts_at']) as String),
        registrationDeadline: json['registration_deadline'] != null
            ? DateTime.parse(json['registration_deadline'] as String)
            : json['registration_closes_at'] != null
                ? DateTime.parse(json['registration_closes_at'] as String)
            : null,
        maxParticipants: (json['max_participants'] as num).toInt(),
        registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
        activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
        entryFeePaise: (json['entry_fee_paise'] as num).toInt(),
        status: (json['status'] as String? ?? 'upcoming') == 'live'
            ? 'active'
            : (json['status'] as String? ?? 'upcoming'),
        rules: json['rules'] as String? ?? '',
        rounds: (json['rounds'] as List<dynamic>?)
                ?.map((r) =>
                    RoundSummary.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        photoUrls: (json['photo_urls'] as List<dynamic>?)
                ?.map((u) => u as String)
                .toList() ??
            [],
      );
}

class RoundSummary {
  final String id;
  final String name;
  final DateTime? scheduledAt;
  final String status; // 'pending' | 'active' | 'completed'
  final int maxParticipants;

  const RoundSummary({
    required this.id,
    required this.name,
    this.scheduledAt,
    required this.status,
    required this.maxParticipants,
  });

  factory RoundSummary.fromJson(Map<String, dynamic> json) => RoundSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.parse(json['scheduled_at'] as String)
            : null,
        status: json['status'] as String,
        maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 0,
      );
}

// ═══════════════════════════════════════════════════════
// participation_model.dart
// ═══════════════════════════════════════════════════════
class ParticipationModel {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final int queueNumber;
  final String status; // 'active' | 'eliminated' | 'winner'
  final int amountPaidPaise;
  final String paymentId;
  final DateTime registeredAt;

  const ParticipationModel({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.queueNumber,
    required this.status,
    required this.amountPaidPaise,
    required this.paymentId,
    required this.registeredAt,
  });

  bool get isActive => status == 'active';
  bool get isWinner => status == 'winner';

  factory ParticipationModel.fromJson(Map<String, dynamic> json) =>
      ParticipationModel(
        id: json['id'] as String,
        tournamentId: json['tournament_id'] as String,
        tournamentName: json['tournament_name'] as String,
        queueNumber: (json['queue_number'] as num).toInt(),
        status: json['status'] as String,
        amountPaidPaise:
            (json['amount_paid_paise'] as num?)?.toInt() ??
                (json['entry_fee_paise'] as num?)?.toInt() ??
                0,
        paymentId: json['payment_id'] as String? ?? '',
        registeredAt: DateTime.parse(json['registered_at'] as String),
      );
}
