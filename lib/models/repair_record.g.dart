// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_record.dart';

RepairRecord _$RepairRecordFromJson(Map<String, dynamic> json) => RepairRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      productId: json['product_id'] as String?,
      faultTypes: (json['fault_types'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      repairAction: json['repair_action'] as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$RepairRecordToJson(RepairRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'product_id': instance.productId,
      'fault_types': instance.faultTypes,
      'repair_action': instance.repairAction,
      'duration_minutes': instance.durationMinutes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
