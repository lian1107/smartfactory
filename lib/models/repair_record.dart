import 'package:json_annotation/json_annotation.dart';

part 'repair_record.g.dart';

@JsonSerializable()
class RepairRecord {
  final String id;
  final DateTime date;
  @JsonKey(name: 'product_id')
  final String? productId;
  @JsonKey(name: 'fault_types')
  final List<String> faultTypes;
  @JsonKey(name: 'repair_action')
  final String repairAction;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const RepairRecord({
    required this.id,
    required this.date,
    this.productId,
    required this.faultTypes,
    required this.repairAction,
    this.durationMinutes,
    this.createdBy,
    required this.createdAt,
  });

  factory RepairRecord.fromJson(Map<String, dynamic> json) =>
      _$RepairRecordFromJson(json);
  Map<String, dynamic> toJson() => _$RepairRecordToJson(this);
}
