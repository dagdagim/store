class OrderModel {
  final bool success;
  final String id;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final String? customerEmail;

  OrderModel({
    this.success = true,
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.customerEmail,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawItems = data['items'] as List<dynamic>? ?? const [];

    return OrderModel(
      success: (json['success'] ?? true) == true,
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      items: rawItems
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt:
          DateTime.tryParse((data['createdAt'] ?? '').toString()) ?? DateTime.now(),
        customerName: data['user'] is Map<String, dynamic>
          ? (data['user']['name']?.toString())
          : null,
        customerEmail: data['user'] is Map<String, dynamic>
          ? (data['user']['email']?.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    '_id': id,
    'items': items.map((item) => item.toJson()).toList(),
    'totalPrice': totalPrice,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'customerName': customerName,
    'customerEmail': customerEmail,
  };
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? size;
  final String? color;
  final String? image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.size,
    this.color,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'];
    final parsedProductId = rawProduct is Map<String, dynamic>
        ? (rawProduct['_id'] ?? rawProduct['id'] ?? '').toString()
        : (json['productId'] ?? rawProduct ?? '').toString();

    return OrderItem(
      productId: parsedProductId,
      name: (json['name'] ?? 'Product').toString(),
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1) is int
          ? (json['quantity'] ?? 1) as int
          : ((json['quantity'] ?? 1) as num).toInt(),
      size: json['size']?.toString(),
      color: json['color']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'size': size,
    'color': color,
    'image': image,
  };
}
