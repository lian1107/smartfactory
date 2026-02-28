import 'package:json_annotation/json_annotation.dart';

part 'project.g.dart';

@JsonSerializable()
class Project {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'product_id')
  final String? productId;
  @JsonKey(name: 'template_id')
  final String? templateId;
  final String status;
  final String health;
  @JsonKey(name: 'planned_start_date')
  final DateTime? plannedStartDate;
  @JsonKey(name: 'planned_end_date')
  final DateTime? plannedEndDate;
  @JsonKey(name: 'actual_start_date')
  final DateTime? actualStartDate;
  @JsonKey(name: 'actual_end_date')
  final DateTime? actualEndDate;
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  final int quantity;
  final int priority;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.title,
    this.description,
    this.productId,
    this.templateId,
    required this.status,
    required this.health,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.ownerId,
    required this.quantity,
    required this.priority,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isOverdue =>
      plannedEndDate != null &&
      plannedEndDate!.isBefore(DateTime.now()) &&
      !isCompleted;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? title,
    String? description,
    String? productId,
    String? status,
    String? health,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    String? ownerId,
    int? quantity,
    int? priority,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      productId: productId ?? this.productId,
      templateId: templateId,
      status: status ?? this.status,
      health: health ?? this.health,
      plannedStartDate: plannedStartDate ?? this.plannedStartDate,
      plannedEndDate: plannedEndDate ?? this.plannedEndDate,
      actualStartDate: actualStartDate,
      actualEndDate: actualEndDate,
      ownerId: ownerId ?? this.ownerId,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
