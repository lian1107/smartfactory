import 'package:json_annotation/json_annotation.dart';

part 'project_template.g.dart';

@JsonSerializable()
class ProjectTemplate {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'phase_ids')
  final List<String> phaseIds;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const ProjectTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.phaseIds,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectTemplate.fromJson(Map<String, dynamic> json) =>
      _$ProjectTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectTemplateToJson(this);
}
