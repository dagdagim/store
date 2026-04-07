// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  avatar: json['avatar'] as String?,
  measurements: json['measurements'] == null
      ? null
      : Measurements.fromJson(json['measurements'] as Map<String, dynamic>),
  preferredSizes: json['preferredSizes'] == null
      ? null
      : PreferredSizes.fromJson(json['preferredSizes'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'role': instance.role,
  'avatar': instance.avatar,
  'measurements': instance.measurements,
  'preferredSizes': instance.preferredSizes,
  'createdAt': instance.createdAt.toIso8601String(),
};

Measurements _$MeasurementsFromJson(Map<String, dynamic> json) => Measurements(
  height: (json['height'] as num?)?.toDouble(),
  weight: (json['weight'] as num?)?.toDouble(),
  chest: (json['chest'] as num?)?.toDouble(),
  waist: (json['waist'] as num?)?.toDouble(),
  hips: (json['hips'] as num?)?.toDouble(),
  shoeSize: (json['shoeSize'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MeasurementsToJson(Measurements instance) =>
    <String, dynamic>{
      'height': instance.height,
      'weight': instance.weight,
      'chest': instance.chest,
      'waist': instance.waist,
      'hips': instance.hips,
      'shoeSize': instance.shoeSize,
    };

PreferredSizes _$PreferredSizesFromJson(Map<String, dynamic> json) =>
    PreferredSizes(
      top: json['top'] as String?,
      bottom: json['bottom'] as String?,
      shoes: json['shoes'] as String?,
    );

Map<String, dynamic> _$PreferredSizesToJson(PreferredSizes instance) =>
    <String, dynamic>{
      'top': instance.top,
      'bottom': instance.bottom,
      'shoes': instance.shoes,
    };
