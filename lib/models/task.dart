import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  @JsonKey(name: 'project_id')
  final String projectId;
  @JsonKey(name: 'phase_id')
  final String phaseId;
  final String title;
  final String? description;
  @JsonKey(name: 'assignee_id')
  final String? assigneeId;
  final String priority;
  final String status;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @JsonKey(name: 'estimated_hours')
  final double? estimatedHours;
  @JsonKey(name: 'actual_hours')
  final double? actualHours;
  final List<String> tags;
  @JsonKey(name: 'order_index')
  final int orderIndex;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.projectId,
    required this.phaseId,
    required this.title,
    this.description,
    this.assigneeId,
    required this.priority,
    required this.status,
    this.dueDate,
    this.startedAt,
    this.completedAt,
    this.estimatedHours,
    this.actualHours,
    required this.tags,
    required this.orderIndex,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != 'done';

  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.year == today.year &&
        dueDate!.month == today.month &&
        dueDate!.day == today.day;
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  Task copyWith({
    String? phaseId,
    String? title,
    String? description,
    String? assigneeId,
    String? priority,
    String? status,
    DateTime? dueDate,
    double? estimatedHours,
    double? actualHours,
    List<String>? tags,
    int? orderIndex,
  }) {
    return Task(
      id: id,
      projectId: projectId,
      phaseId: phaseId ?? this.phaseId,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      startedAt: startedAt,
      completedAt: completedAt,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      tags: tags ?? this.tags,
      orderIndex: orderIndex ?? this.orderIndex,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
