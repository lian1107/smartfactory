import 'package:json_annotation/json_annotation.dart';

part 'quality_record.g.dart';

@JsonSerializable()
class QualityRecord {
  final String id;
  final DateTime date;
  @JsonKey(name: 'inspection_type')
  final String inspectionType; // 'full' | 'sample'
  @JsonKey(name: 'product_id')
  final String? productId;
  @JsonKey(name: 'total_qty')
  final int totalQty;
  @JsonKey(name: 'defect_qty')
  final int defectQty;
  final String? notes;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const QualityRecord({
    required this.id,
    required this.date,
    required this.inspectionType,
    this.productId,
    required this.totalQty,
    required this.defectQty,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory QualityRecord.fromJson(Map<String, dynamic> json) =>
      _$QualityRecordFromJson(json);
  Map<String, dynamic> toJson() => _$QualityRecordToJson(this);
}
