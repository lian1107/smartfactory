import 'package:json_annotation/json_annotation.dart';

part 'change_request.g.dart';

@JsonSerializable()
class ChangeRequest {
  final String id;
  @JsonKey(name: 'project_id')
  final String? projectId;
  final String title;
  final String? description;
  @JsonKey(name: 'requester_id')
  final String? requesterId;
  final String status;
  final String priority;
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const ChangeRequest({
    required this.id,
    this.projectId,
    required this.title,
    this.description,
    this.requesterId,
    required this.status,
    required this.priority,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChangeRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChangeRequestToJson(this);
}
