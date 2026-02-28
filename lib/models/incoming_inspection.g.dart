// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_inspection.dart';

IncomingInspection _$IncomingInspectionFromJson(Map<String, dynamic> json) =>
    IncomingInspection(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      materialName: json['material_name'] as String,
      supplier: json['supplier'] as String?,
      totalQty: (json['total_qty'] as num).toInt(),
      defectQty: (json['defect_qty'] as num).toInt(),
      defectDescription: json['defect_description'] as String?,
      result: json['result'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$IncomingInspectionToJson(
        IncomingInspection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'material_name': instance.materialName,
      'supplier': instance.supplier,
      'total_qty': instance.totalQty,
      'defect_qty': instance.defectQty,
      'defect_description': instance.defectDescription,
      'result': instance.result,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
