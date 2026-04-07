class PromotionModel {
  final String id;
  final String title;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;

  PromotionModel({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      description: json['description']?.toString(),
      discountType: (json['discountType'] ?? 'percent').toString(),
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
      startsAt: DateTime.tryParse((json['startsAt'] ?? '').toString()) ?? DateTime.now(),
      endsAt: DateTime.tryParse((json['endsAt'] ?? '').toString()) ?? DateTime.now(),
      isActive: json['isActive'] == true,
    );
  }
}
