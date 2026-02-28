import 'package:json_annotation/json_annotation.dart';

part 'daily_report.g.dart';

@JsonSerializable()
class DailyReport {
  final String id;
  final DateTime date;
  final String shift; // 'early' | 'mid' | 'late'
  @JsonKey(name: 'product_id')
  final String? productId;
  @JsonKey(name: 'production_line')
  final String? productionLine;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  final String status; // 'draft' | 'submitted'
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DailyReport({
    required this.id,
    required this.date,
    required this.shift,
    this.productId,
    this.productionLine,
    this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) =>
      _$DailyReportFromJson(json);
  Map<String, dynamic> toJson() => _$DailyReportToJson(this);

  DailyReport copyWith({
    String? id,
    DateTime? date,
    String? shift,
    String? productId,
    String? productionLine,
    String? createdBy,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DailyReport(
        id: id ?? this.id,
        date: date ?? this.date,
        shift: shift ?? this.shift,
        productId: productId ?? this.productId,
        productionLine: productionLine ?? this.productionLine,
        createdBy: createdBy ?? this.createdBy,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
