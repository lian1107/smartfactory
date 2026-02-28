import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? category;
  final String? specification;
  final String unit;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.category,
    this.specification,
    required this.unit,
    this.thumbnailUrl,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    String? code,
    String? name,
    String? description,
    String? category,
    String? specification,
    String? unit,
    String? thumbnailUrl,
    bool? isActive,
  }) {
    return Product(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      specification: specification ?? this.specification,
      unit: unit ?? this.unit,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
