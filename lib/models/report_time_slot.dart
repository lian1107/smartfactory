import 'package:json_annotation/json_annotation.dart';

part 'report_time_slot.g.dart';

@JsonSerializable()
class ReportTimeSlot {
  final String id;
  @JsonKey(name: 'report_id')
  final String reportId;
  @JsonKey(name: 'slot_start')
  final int slotStart; // 小时数，如 8 = 08:00
  @JsonKey(name: 'slot_end')
  final int slotEnd; // 如 9 = 09:00
  @JsonKey(name: 'planned_qty')
  final int plannedQty;
  @JsonKey(name: 'actual_qty')
  final int actualQty;
  @JsonKey(name: 'defect_qty')
  final int defectQty;
  @JsonKey(name: 'downtime_reason')
  final String? downtimeReason;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ReportTimeSlot({
    required this.id,
    required this.reportId,
    required this.slotStart,
    required this.slotEnd,
    required this.plannedQty,
    required this.actualQty,
    required this.defectQty,
    this.downtimeReason,
    required this.createdAt,
  });

  factory ReportTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$ReportTimeSlotFromJson(json);
  Map<String, dynamic> toJson() => _$ReportTimeSlotToJson(this);
}
