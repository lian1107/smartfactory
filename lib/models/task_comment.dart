import 'package:json_annotation/json_annotation.dart';

part 'task_comment.g.dart';

@JsonSerializable()
class TaskComment {
  final String id;
  @JsonKey(name: 'task_id')
  final String taskId;
  @JsonKey(name: 'author_id')
  final String authorId;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) =>
      _$TaskCommentFromJson(json);
  Map<String, dynamic> toJson() => _$TaskCommentToJson(this);
}
