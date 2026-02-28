import 'package:json_annotation/json_annotation.dart';

part 'document_link.g.dart';

@JsonSerializable()
class DocumentLink {
  final String id;
  @JsonKey(name: 'entity_type')
  final String entityType;
  @JsonKey(name: 'entity_id')
  final String entityId;
  final String title;
  final String url;
  @JsonKey(name: 'doc_type')
  final String docType;
  @JsonKey(name: 'uploaded_by')
  final String? uploadedBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const DocumentLink({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.url,
    required this.docType,
    this.uploadedBy,
    required this.createdAt,
  });

  factory DocumentLink.fromJson(Map<String, dynamic> json) =>
      _$DocumentLinkFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentLinkToJson(this);
}
