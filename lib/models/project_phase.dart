import 'package:json_annotation/json_annotation.dart';

part 'project_phase.g.dart';

@JsonSerializable()
class ProjectPhase {
  final String id;
  @JsonKey(name: 'project_id')
  final String projectId;
  @JsonKey(name: 'template_id')
  final String? templateId;
  final String name;
  final String? description;
  @JsonKey(name: 'order_index')
  final int orderIndex;
  final String color;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const ProjectPhase({
    required this.id,
    required this.projectId,
    this.templateId,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.color,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectPhase.fromJson(Map<String, dynamic> json) =>
      _$ProjectPhaseFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectPhaseToJson(this);

  ProjectPhase copyWith({
    String? name,
    int? orderIndex,
    String? color,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ProjectPhase(
      id: id,
      projectId: projectId,
      templateId: templateId,
      name: name ?? this.name,
      description: description,
      orderIndex: orderIndex ?? this.orderIndex,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
