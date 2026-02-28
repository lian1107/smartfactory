// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quality_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QualityRecord _$QualityRecordFromJson(Map<String, dynamic> json) =>
    QualityRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      inspectionType: json['inspection_type'] as String,
      productId: json['product_id'] as String?,
      totalQty: (json['total_qty'] as num).toInt(),
      defectQty: (json['defect_qty'] as num).toInt(),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$QualityRecordToJson(QualityRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'inspection_type': instance.inspectionType,
      'product_id': instance.productId,
      'total_qty': instance.totalQty,
      'defect_qty': instance.defectQty,
      'notes': instance.notes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
