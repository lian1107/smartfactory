import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final String role;
  final String? department;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    this.department,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => fullName ?? email.split('@').first;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? role,
    String? department,
    bool? isActive,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
