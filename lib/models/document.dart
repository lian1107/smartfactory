import 'package:json_annotation/json_annotation.dart';

part 'document.g.dart';

@JsonSerializable()
class Document {
  final String id;
  final String title;
  final String? description;
  final String type; // 'feishu' | 'file' | 'note'
  final String? url;
  @JsonKey(name: 'file_path')
  final String? filePath;
  final String? content;
  final String? category;
  final List<String>? tags;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.url,
    this.filePath,
    this.content,
    this.category,
    this.tags,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);
}
