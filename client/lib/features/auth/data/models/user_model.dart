// ─── user_model.dart ──────────────────────────────────────────────────────────
// lib/features/auth/data/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // "user" | "admin"
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Player',
        email: json['email'] as String? ?? '',
        photoUrl: json['photo_url'] as String? ?? json['profile_image'] as String?,
        role: json['role'] as String? ?? 'user',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };
}
