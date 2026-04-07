import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  bool _isLoading = false;
  String? _error;
  String? _lastCategory;
  String? _lastSearch;
  String? _lastSort;
  double? _lastMinPrice;
  double? _lastMaxPrice;
  double? _lastRating;

  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts({
    String? category,
    String? search,
    String? sort,
    double? minPrice,
    double? maxPrice,
    double? rating,
  }) async {
    _isLoading = true;
    notifyListeners();

    _lastCategory = category;
    _lastSearch = search;
    _lastSort = sort;
    _lastMinPrice = minPrice;
    _lastMaxPrice = maxPrice;
    _lastRating = rating;

    try {
      final response = await _repository.getProducts(
        category: category,
        search: search,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        rating: rating,
      );
      _products = response.data;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts(
      category: _lastCategory,
      search: _lastSearch,
      sort: _lastSort,
      minPrice: _lastMinPrice,
      maxPrice: _lastMaxPrice,
      rating: _lastRating,
    );
  }

  Future<void> loadFeaturedProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _featuredProducts = await _repository.getFeaturedProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
