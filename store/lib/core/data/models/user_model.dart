import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final Measurements? measurements;
  final PreferredSizes? preferredSizes;
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.measurements,
    this.preferredSizes,
    required this.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class Measurements {
  final double? height;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoeSize;
  
  Measurements({
    this.height,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.shoeSize,
  });
  
  factory Measurements.fromJson(Map<String, dynamic> json) => _$MeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$MeasurementsToJson(this);
}

@JsonSerializable()
class PreferredSizes {
  final String? top;
  final String? bottom;
  final String? shoes;
  
  PreferredSizes({this.top, this.bottom, this.shoes});
  
  factory PreferredSizes.fromJson(Map<String, dynamic> json) => _$PreferredSizesFromJson(json);
  Map<String, dynamic> toJson() => _$PreferredSizesToJson(this);
}