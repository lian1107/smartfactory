import 'package:json_annotation/json_annotation.dart';

part 'phase_template.g.dart';

@JsonSerializable()
class PhaseTemplate {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'default_order')
  final int defaultOrder;
  final String color;
  final String? icon;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const PhaseTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.defaultOrder,
    required this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PhaseTemplate.fromJson(Map<String, dynamic> json) =>
      _$PhaseTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$PhaseTemplateToJson(this);
}
