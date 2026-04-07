import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  @JsonKey(defaultValue: '')
  final String slug;
  final String description;
  final double price;
  final String category;
  final String? subCategory;
  final String brand;
  @JsonKey(defaultValue: <Size>[])
  final List<Size> sizes;
  @JsonKey(defaultValue: <Color>[])
  final List<Color> colors;
  @JsonKey(defaultValue: <String>[])
  final List<String> tags;
  final double rating;
  final int numReviews;
  final bool isFeatured;
  final bool isAvailable;
  final double discount;
  final Specifications? specifications;
  final int views;
  final int sold;
  final DateTime createdAt;

  @JsonKey(name: 'finalPrice')
  final double? finalPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.category,
    this.subCategory,
    required this.brand,
    required this.sizes,
    required this.colors,
    required this.tags,
    required this.rating,
    required this.numReviews,
    required this.isFeatured,
    required this.isAvailable,
    required this.discount,
    this.specifications,
    required this.views,
    required this.sold,
    required this.createdAt,
    this.finalPrice,
  });

  double get actualPrice => discount > 0 ? finalPrice ?? price : price;
  String get formattedPrice => '\$${actualPrice.toStringAsFixed(2)}';
  String get originalPrice =>
      discount > 0 ? '\$${price.toStringAsFixed(2)}' : '';
  int get totalStock => sizes.fold(0, (sum, size) => sum + size.stock);

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class Size {
  final String size;
  final int stock;
  final String sku;

  Size({required this.size, required this.stock, required this.sku});

  factory Size.fromJson(Map<String, dynamic> json) => _$SizeFromJson(json);
  Map<String, dynamic> toJson() => _$SizeToJson(this);
}

@JsonSerializable()
class Color {
  final String name;
  final String? hex;
  final List<String> images;
  final int stock;

  Color({
    required this.name,
    this.hex,
    required this.images,
    required this.stock,
  });

  factory Color.fromJson(Map<String, dynamic> json) => _$ColorFromJson(json);
  Map<String, dynamic> toJson() => _$ColorToJson(this);
}

@JsonSerializable()
class Specifications {
  final String? material;
  final String? care;
  final String? weight;
  final String? origin;
  final String? fit;
  final String? length;

  Specifications({
    this.material,
    this.care,
    this.weight,
    this.origin,
    this.fit,
    this.length,
  });

  factory Specifications.fromJson(Map<String, dynamic> json) =>
      _$SpecificationsFromJson(json);
  Map<String, dynamic> toJson() => _$SpecificationsToJson(this);
}
