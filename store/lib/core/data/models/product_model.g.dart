// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['_id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String? ?? '',
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  category: json['category'] as String,
  subCategory: json['subCategory'] as String?,
  brand: json['brand'] as String,
  sizes:
      (json['sizes'] as List<dynamic>?)
          ?.map((e) => Size.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  colors:
      (json['colors'] as List<dynamic>?)
          ?.map((e) => Color.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  rating: (json['rating'] as num).toDouble(),
  numReviews: (json['numReviews'] as num).toInt(),
  isFeatured: json['isFeatured'] as bool,
  isAvailable: json['isAvailable'] as bool,
  discount: (json['discount'] as num).toDouble(),
  specifications: json['specifications'] == null
      ? null
      : Specifications.fromJson(json['specifications'] as Map<String, dynamic>),
  views: (json['views'] as num).toInt(),
  sold: (json['sold'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  finalPrice: (json['finalPrice'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'price': instance.price,
      'category': instance.category,
      'subCategory': instance.subCategory,
      'brand': instance.brand,
      'sizes': instance.sizes,
      'colors': instance.colors,
      'tags': instance.tags,
      'rating': instance.rating,
      'numReviews': instance.numReviews,
      'isFeatured': instance.isFeatured,
      'isAvailable': instance.isAvailable,
      'discount': instance.discount,
      'specifications': instance.specifications,
      'views': instance.views,
      'sold': instance.sold,
      'createdAt': instance.createdAt.toIso8601String(),
      'finalPrice': instance.finalPrice,
    };

Size _$SizeFromJson(Map<String, dynamic> json) => Size(
  size: json['size'] as String,
  stock: (json['stock'] as num).toInt(),
  sku: json['sku'] as String,
);

Map<String, dynamic> _$SizeToJson(Size instance) => <String, dynamic>{
  'size': instance.size,
  'stock': instance.stock,
  'sku': instance.sku,
};

Color _$ColorFromJson(Map<String, dynamic> json) => Color(
  name: json['name'] as String,
  hex: json['hex'] as String?,
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  stock: (json['stock'] as num).toInt(),
);

Map<String, dynamic> _$ColorToJson(Color instance) => <String, dynamic>{
  'name': instance.name,
  'hex': instance.hex,
  'images': instance.images,
  'stock': instance.stock,
};

Specifications _$SpecificationsFromJson(Map<String, dynamic> json) =>
    Specifications(
      material: json['material'] as String?,
      care: json['care'] as String?,
      weight: json['weight'] as String?,
      origin: json['origin'] as String?,
      fit: json['fit'] as String?,
      length: json['length'] as String?,
    );

Map<String, dynamic> _$SpecificationsToJson(Specifications instance) =>
    <String, dynamic>{
      'material': instance.material,
      'care': instance.care,
      'weight': instance.weight,
      'origin': instance.origin,
      'fit': instance.fit,
      'length': instance.length,
    };
