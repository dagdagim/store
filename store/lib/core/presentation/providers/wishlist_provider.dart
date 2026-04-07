import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/wishlist_repository.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistRepository _repository = WishlistRepository();

  List<ProductModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFavorite(String productId) {
    return _items.any((item) => item.id == productId);
  }

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getWishlist();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToWishlist(ProductModel product) async {
    final alreadyFavorite = isFavorite(product.id);
    if (alreadyFavorite) {
      return true;
    }

    try {
      _items = [product, ..._items];
      _error = null;
      notifyListeners();

      await _repository.addToWishlist(product.id);
      return true;
    } catch (e) {
      _items = _items.where((item) => item.id != product.id).toList();
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromWishlist(String productId) async {
    final previousItems = List<ProductModel>.from(_items);

    try {
      _items = _items.where((item) => item.id != productId).toList();
      _error = null;
      notifyListeners();

      await _repository.removeFromWishlist(productId);
      return true;
    } catch (e) {
      _items = previousItems;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleWishlist(ProductModel product) async {
    if (isFavorite(product.id)) {
      return removeFromWishlist(product.id);
    }

    return addToWishlist(product);
  }
}
