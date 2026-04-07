import 'package:flutter/material.dart';
import '../../data/models/cart_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../constants/app_constants.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository = CartRepository();
  
  CartModel? _cart;
  CartPromotionPreview? _promotionPreview;
  bool _isLoading = false;
  String? _error;
  bool _isApplyingPromotion = false;
  
  CartModel? get cart => _cart;
  List<CartItem> get items => _cart?.items ?? [];
  bool get isLoading => _isLoading;
  bool get isApplyingPromotion => _isApplyingPromotion;
  int get itemCount => _cart?.items.length ?? 0;
  String? get error => _error;
  CartPromotionPreview? get promotionPreview => _promotionPreview;
  String? get appliedPromotionCode => _cart?.promotionCode;
  
  double get subtotal {
    if (_cart != null) {
      return _cart!.subtotalPrice;
    }
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get discount {
    return _cart?.discountAmount ?? 0;
  }

  double get discountedSubtotal {
    final value = subtotal - discount;
    return value > 0 ? value : 0;
  }
  
  double get tax {
    return discountedSubtotal * AppConstants.taxRate;
  }
  
  double get shipping {
    return discountedSubtotal > AppConstants.freeShippingThreshold 
        ? 0 
        : AppConstants.shippingCost;
  }
  
  double get total {
    return discountedSubtotal + tax + shipping;
  }
  
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _cart = await _cartRepository.getCart();
      _promotionPreview = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addToCart({
    required String productId,
    required int quantity,
    required String size,
    required String color,
  }) async {
    try {
      await _cartRepository.addToCart(
        productId: productId,
        quantity: quantity,
        size: size,
        color: color,
      );
      await loadCart();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      await _cartRepository.updateQuantity(itemId, quantity);
      await loadCart();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<void> removeItem(String itemId) async {
    try {
      await _cartRepository.removeFromCart(itemId);
      await loadCart();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<void> clearCart() async {
    try {
      await _cartRepository.clearCart();
      _cart = null;
      _promotionPreview = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> previewPromotionCode(String code) async {
    _isApplyingPromotion = true;
    notifyListeners();
    try {
      _promotionPreview = await _cartRepository.previewPromotionCode(code);
      _error = null;
    } catch (e) {
      _promotionPreview = null;
      _error = e.toString();
      rethrow;
    } finally {
      _isApplyingPromotion = false;
      notifyListeners();
    }
  }

  Future<void> applyPromotionCode(String code) async {
    _isApplyingPromotion = true;
    notifyListeners();
    try {
      _cart = await _cartRepository.applyPromotionCode(code);
      _promotionPreview = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isApplyingPromotion = false;
      notifyListeners();
    }
  }

  Future<void> removePromotionCode() async {
    _isApplyingPromotion = true;
    notifyListeners();
    try {
      _cart = await _cartRepository.removePromotionCode();
      _promotionPreview = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isApplyingPromotion = false;
      notifyListeners();
    }
  }
}