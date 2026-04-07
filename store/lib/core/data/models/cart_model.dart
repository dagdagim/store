class CartModel {
  final String id;
  final List<CartItem> items;
  final double total;
  final double subtotalPrice;
  final double discountAmount;
  final String? promotionCode;

  CartModel({
    required this.id,
    required this.items,
    required this.total,
    required this.subtotalPrice,
    required this.discountAmount,
    this.promotionCode,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      items: rawItems
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['totalPrice'] ?? json['total'] ?? 0).toDouble(),
      subtotalPrice: (json['subtotalPrice'] ?? json['totalPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      promotionCode: json['promotionCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
    'subtotalPrice': subtotalPrice,
    'discountAmount': discountAmount,
    'promotionCode': promotionCode,
  };
}

class CartPromotionPreview {
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final bool eligible;
  final double subtotalPrice;
  final double discountAmount;
  final double totalPrice;
  final String? message;

  CartPromotionPreview({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.eligible,
    required this.subtotalPrice,
    required this.discountAmount,
    required this.totalPrice,
    this.message,
  });

  factory CartPromotionPreview.fromJson(Map<String, dynamic> json) {
    return CartPromotionPreview(
      code: (json['code'] ?? '').toString(),
      discountType: (json['discountType'] ?? 'percent').toString(),
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      eligible: json['eligible'] == true,
      subtotalPrice: (json['subtotalPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      message: json['message']?.toString(),
    );
  }
}

class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? size;
  final String? color;
  final String? image;
  final int? availableStock;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.size,
    this.color,
    this.image,
    this.availableStock,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    String parsedProductId = (json['productId'] ?? '').toString();
    String parsedName = (json['name'] ?? 'Product').toString();
    String? parsedImage = json['image']?.toString();
    int? parsedAvailableStock;

    if (product is Map<String, dynamic>) {
      parsedProductId = (product['_id'] ?? product['id'] ?? '').toString();
      parsedName = (product['name'] ?? parsedName).toString();

      final colors = product['colors'];
      if (parsedImage == null && colors is List && colors.isNotEmpty) {
        final firstColor = colors.first;
        if (firstColor is Map<String, dynamic>) {
          final images = firstColor['images'];
          if (images is List && images.isNotEmpty) {
            parsedImage = images.first.toString();
          }
        }
      }

      final sizes = product['sizes'];
      final selectedSize = json['size']?.toString();
      if (sizes is List && selectedSize != null && selectedSize.isNotEmpty) {
        final matchedSize = sizes.cast<dynamic>().whereType<Map<String, dynamic>>().firstWhere(
          (entry) => entry['size']?.toString() == selectedSize,
          orElse: () => const {},
        );

        final dynamic stock = matchedSize['stock'];
        if (stock is int) {
          parsedAvailableStock = stock;
        } else if (stock is num) {
          parsedAvailableStock = stock.toInt();
        }
      }
    } else if (product != null) {
      parsedProductId = product.toString();
    }

    return CartItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      productId: parsedProductId,
      name: parsedName,
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1) is int
          ? (json['quantity'] ?? 1) as int
          : ((json['quantity'] ?? 1) as num).toInt(),
      size: json['size']?.toString(),
      color: json['color']?.toString(),
      image: parsedImage,
      availableStock: parsedAvailableStock,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'size': size,
    'color': color,
    'image': image,
    'availableStock': availableStock,
  };
}
