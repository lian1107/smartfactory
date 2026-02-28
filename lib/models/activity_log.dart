import 'package:json_annotation/json_annotation.dart';

part 'activity_log.g.dart';

@JsonSerializable()
class ActivityLog {
  final String id;
  @JsonKey(name: 'entity_type')
  final String entityType;
  @JsonKey(name: 'entity_id')
  final String entityId;
  final String action;
  @JsonKey(name: 'actor_id')
  final String? actorId;
  @JsonKey(name: 'old_value')
  final Map<String, dynamic>? oldValue;
  @JsonKey(name: 'new_value')
  final Map<String, dynamic>? newValue;
  final Map<String, dynamic> metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.actorId,
    this.oldValue,
    this.newValue,
    required this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityLogToJson(this);
}
