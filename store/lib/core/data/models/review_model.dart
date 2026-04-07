class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String productId;
  final String? productName;
  final int rating;
  final String title;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    this.productName,
    required this.rating,
    required this.title,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final rawProduct = json['product'];

    String parsedUserId = '';
    String parsedUserName = 'Anonymous';
    if (rawUser is Map<String, dynamic>) {
      parsedUserId = (rawUser['_id'] ?? '').toString();
      parsedUserName = (rawUser['name'] ?? 'Anonymous').toString();
    } else {
      parsedUserId = (rawUser ?? json['userId'] ?? '').toString();
      parsedUserName = (json['userName'] ?? 'Anonymous').toString();
    }

    String parsedProductId = '';
    String? parsedProductName;
    if (rawProduct is Map<String, dynamic>) {
      parsedProductId = (rawProduct['_id'] ?? '').toString();
      parsedProductName = rawProduct['name']?.toString();
    } else {
      parsedProductId = (rawProduct ?? json['productId'] ?? '').toString();
      parsedProductName = json['productName']?.toString();
    }

    return ReviewModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: parsedUserId,
      userName: parsedUserName,
      productId: parsedProductId,
      productName: parsedProductName,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'userName': userName,
      'productId': productId,
      'productName': productName,
      'rating': rating,
      'title': title,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
