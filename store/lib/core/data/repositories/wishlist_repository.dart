import '../../../services/api_service.dart';
import '../models/product_model.dart';

class WishlistRepository {
  final ApiService _api = ApiService.create();

  Future<List<ProductModel>> getWishlist() async {
    final response = await _api.getWishlist();
    return response.data;
  }

  Future<void> addToWishlist(String productId) async {
    await _api.addToWishlist({
      'productId': productId,
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    await _api.removeFromWishlist(productId);
  }
}
