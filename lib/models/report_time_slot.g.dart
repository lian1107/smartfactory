// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_time_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportTimeSlot _$ReportTimeSlotFromJson(Map<String, dynamic> json) =>
    ReportTimeSlot(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      slotStart: (json['slot_start'] as num).toInt(),
      slotEnd: (json['slot_end'] as num).toInt(),
      plannedQty: (json['planned_qty'] as num).toInt(),
      actualQty: (json['actual_qty'] as num).toInt(),
      defectQty: (json['defect_qty'] as num).toInt(),
      downtimeReason: json['downtime_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ReportTimeSlotToJson(ReportTimeSlot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'report_id': instance.reportId,
      'slot_start': instance.slotStart,
      'slot_end': instance.slotEnd,
      'planned_qty': instance.plannedQty,
      'actual_qty': instance.actualQty,
      'defect_qty': instance.defectQty,
      'downtime_reason': instance.downtimeReason,
      'created_at': instance.createdAt.toIso8601String(),
    };
