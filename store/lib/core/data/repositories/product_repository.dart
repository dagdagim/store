import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/api_service.dart';
import '../models/product_model.dart';

class InventoryAlertItem {
  final String id;
  final String name;
  final String category;
  final int totalStock;
  final bool isAvailable;
  final int suggestedReorderQty;

  InventoryAlertItem({
    required this.id,
    required this.name,
    required this.category,
    required this.totalStock,
    required this.isAvailable,
    required this.suggestedReorderQty,
  });

  factory InventoryAlertItem.fromJson(Map<String, dynamic> json) {
    return InventoryAlertItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Product').toString(),
      category: (json['category'] ?? 'uncategorized').toString(),
      totalStock: (json['totalStock'] ?? 0) is int
          ? (json['totalStock'] ?? 0) as int
          : ((json['totalStock'] ?? 0) as num).toInt(),
      isAvailable: json['isAvailable'] != false,
      suggestedReorderQty: (json['suggestedReorderQty'] ?? 0) is int
          ? (json['suggestedReorderQty'] ?? 0) as int
          : ((json['suggestedReorderQty'] ?? 0) as num).toInt(),
    );
  }
}

class CategoryStockRisk {
  final String category;
  final int lowStock;
  final int outOfStock;
  final int suggestedReorderTotal;

  CategoryStockRisk({
    required this.category,
    required this.lowStock,
    required this.outOfStock,
    required this.suggestedReorderTotal,
  });

  factory CategoryStockRisk.fromJson(Map<String, dynamic> json) {
    return CategoryStockRisk(
      category: (json['category'] ?? 'uncategorized').toString(),
      lowStock: (json['lowStock'] ?? 0) is int
          ? (json['lowStock'] ?? 0) as int
          : ((json['lowStock'] ?? 0) as num).toInt(),
      outOfStock: (json['outOfStock'] ?? 0) is int
          ? (json['outOfStock'] ?? 0) as int
          : ((json['outOfStock'] ?? 0) as num).toInt(),
        suggestedReorderTotal: (json['suggestedReorderTotal'] ?? 0) is int
          ? (json['suggestedReorderTotal'] ?? 0) as int
          : ((json['suggestedReorderTotal'] ?? 0) as num).toInt(),
    );
  }
}

class InventoryInsights {
  final int threshold;
  final int totalProducts;
  final int activeProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final int inventoryUnits;
  final List<CategoryStockRisk> categoryBreakdown;
  final List<InventoryAlertItem> urgentProducts;

  InventoryInsights({
    required this.threshold,
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.inventoryUnits,
    required this.categoryBreakdown,
    required this.urgentProducts,
  });

  factory InventoryInsights.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final categoryBreakdown = (json['categoryBreakdown'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryStockRisk.fromJson)
        .toList();
    final urgentProducts = (json['urgentProducts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(InventoryAlertItem.fromJson)
        .toList();

    return InventoryInsights(
      threshold: (json['threshold'] ?? 5) is int
          ? (json['threshold'] ?? 5) as int
          : ((json['threshold'] ?? 5) as num).toInt(),
      totalProducts: (totals['totalProducts'] ?? 0) is int
          ? (totals['totalProducts'] ?? 0) as int
          : ((totals['totalProducts'] ?? 0) as num).toInt(),
      activeProducts: (totals['activeProducts'] ?? 0) is int
          ? (totals['activeProducts'] ?? 0) as int
          : ((totals['activeProducts'] ?? 0) as num).toInt(),
      lowStockCount: (totals['lowStockCount'] ?? 0) is int
          ? (totals['lowStockCount'] ?? 0) as int
          : ((totals['lowStockCount'] ?? 0) as num).toInt(),
      outOfStockCount: (totals['outOfStockCount'] ?? 0) is int
          ? (totals['outOfStockCount'] ?? 0) as int
          : ((totals['outOfStockCount'] ?? 0) as num).toInt(),
      inventoryUnits: (totals['inventoryUnits'] ?? 0) is int
          ? (totals['inventoryUnits'] ?? 0) as int
          : ((totals['inventoryUnits'] ?? 0) as num).toInt(),
      categoryBreakdown: categoryBreakdown,
      urgentProducts: urgentProducts,
    );
  }
}

class ProductRepository {
  final ApiService _api = ApiService.create();

  Dio _authorizedDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.runtimeApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final token = LocalStorageService.getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    return dio;
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final response = await _api.getFeaturedProducts();
    return response.data.data;
  }

  Future<ProductListResponse> getProducts({
    int? page,
    int? limit,
    String? category,
    String? search,
    bool? featured,
    String? sort,
    double? minPrice,
    double? maxPrice,
    double? rating,
  }) async {
    final response = await _api.getProducts(
      page: page,
      limit: limit,
      category: category,
      search: search,
      isFeatured: featured,
      sort: sort,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rating: rating,
    );
    return response.data;
  }

  Future<ProductModel> getProductById(String productId) async {
    final response = await _api.getProductById(productId);
    return response.data.data;
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response = await _api.createProduct(data);
    return response.data.data;
  }

  Future<ProductModel> updateProduct({
    required String productId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _api.updateProduct(productId, data);
    return response.data.data;
  }

  Future<void> deleteProduct(String productId) async {
    await _api.deleteProduct(productId);
  }

  Future<List<String>> uploadProductImages({
    required String productId,
    required List<XFile> files,
  }) async {
    final dio = _authorizedDio();
    dio.options.headers['Content-Type'] = 'multipart/form-data';

    final multipartFiles = <MultipartFile>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      multipartFiles.add(
        MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      );
    }

    final formData = FormData.fromMap({
      'images': multipartFiles,
    });

    final response = await dio.post('/products/$productId/images', data: formData);
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final raw = data['data'];
      if (raw is List) {
        return raw.map((item) => item.toString()).toList();
      }
    }

    return [];
  }

  Future<InventoryInsights> getInventoryInsights({int threshold = 5}) async {
    final response = await _authorizedDio().get(
      '/products/admin/inventory-insights',
      queryParameters: {'threshold': threshold},
    );

    final payload = response.data;
    if (payload is Map<String, dynamic> && payload['data'] is Map<String, dynamic>) {
      return InventoryInsights.fromJson(payload['data'] as Map<String, dynamic>);
    }

    throw Exception('Invalid inventory insights response');
  }
}
