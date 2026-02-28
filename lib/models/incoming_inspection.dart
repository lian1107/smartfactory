import 'package:json_annotation/json_annotation.dart';

part 'incoming_inspection.g.dart';

@JsonSerializable()
class IncomingInspection {
  final String id;
  final DateTime date;
  @JsonKey(name: 'material_name')
  final String materialName;
  final String? supplier;
  @JsonKey(name: 'total_qty')
  final int totalQty;
  @JsonKey(name: 'defect_qty')
  final int defectQty;
  @JsonKey(name: 'defect_description')
  final String? defectDescription;
  final String result; // 'pass' | 'conditional' | 'fail'
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const IncomingInspection({
    required this.id,
    required this.date,
    required this.materialName,
    this.supplier,
    required this.totalQty,
    required this.defectQty,
    this.defectDescription,
    required this.result,
    this.createdBy,
    required this.createdAt,
  });

  factory IncomingInspection.fromJson(Map<String, dynamic> json) =>
      _$IncomingInspectionFromJson(json);
  Map<String, dynamic> toJson() => _$IncomingInspectionToJson(this);
}
