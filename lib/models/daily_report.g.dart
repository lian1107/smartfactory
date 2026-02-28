// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyReport _$DailyReportFromJson(Map<String, dynamic> json) => DailyReport(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      shift: json['shift'] as String,
      productId: json['product_id'] as String?,
      productionLine: json['production_line'] as String?,
      createdBy: json['created_by'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DailyReportToJson(DailyReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'shift': instance.shift,
      'product_id': instance.productId,
      'production_line': instance.productionLine,
      'created_by': instance.createdBy,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
