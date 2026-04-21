// ═══ participant_model.dart ════════════════════════════════════════════════════
enum ParticipantStatus { active, eliminated, advancing, winner }

class ParticipantModel {
  final String id;
  final int queueNumber;
  final String name;
  final String? photoUrl;
  final ParticipantStatus status;
  final int roundNumber;
  final DateTime? updatedAt;

  const ParticipantModel({
    required this.id,
    required this.queueNumber,
    required this.name,
    this.photoUrl,
    required this.status,
    required this.roundNumber,
    this.updatedAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'active';
    final status = switch (statusStr) {
      'eliminated' => ParticipantStatus.eliminated,
      'advanced' => ParticipantStatus.advancing,
      'advancing' => ParticipantStatus.advancing,
      'winner' => ParticipantStatus.winner,
      'registered' => ParticipantStatus.active,
      _ => ParticipantStatus.active,
    };
    return ParticipantModel(
      id: json['id'] as String,
      queueNumber: (json['queue_number'] as num).toInt(),
      name: json['name'] as String? ?? 'Participant',
      photoUrl: json['photo_url'] as String? ?? json['profile_image'] as String?,
      status: status,
      roundNumber: json['round_number'] as int? ?? 1,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  ParticipantModel copyWith({ParticipantStatus? status, int? roundNumber}) =>
      ParticipantModel(
        id: id,
        queueNumber: queueNumber,
        name: name,
        photoUrl: photoUrl,
        status: status ?? this.status,
        roundNumber: roundNumber ?? this.roundNumber,
        updatedAt: DateTime.now(),
      );
}

// ═══ round_model.dart ══════════════════════════════════════════════════════════
class RoundModel {
  final int roundNumber;
  final String name;
  final String status;
  final List<ParticipantModel> participants;

  const RoundModel({
    required this.roundNumber,
    required this.name,
    required this.status,
    required this.participants,
  });

  factory RoundModel.fromJson(Map<String, dynamic> json) => RoundModel(
        roundNumber: json['round_number'] as int,
        name: json['name'] as String,
        status: json['status'] as String,
        participants: (json['participants'] as List<dynamic>? ?? [])
            .map((p) => ParticipantModel.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
