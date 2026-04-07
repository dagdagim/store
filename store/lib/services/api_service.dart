import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';
import '../core/constants/app_constants.dart';
import '../core/data/models/cart_model.dart';
import '../core/data/models/order_model.dart';
import '../core/data/models/product_model.dart';
import '../core/data/models/review_model.dart';
import '../core/data/models/user_model.dart';
import 'local_storage_service.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: AppConstants.apiBaseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  static ApiService create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.runtimeApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = LocalStorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle token expiration
          }
          return handler.next(e);
        },
      ),
    );

    return _ApiService(dio, baseUrl: AppConstants.runtimeApiBaseUrl);
  }

  // Auth
  @POST('/auth/register')
  Future<HttpResponse<LoginResponse>> register(
    @Body() Map<String, dynamic> data,
  );

  @POST('/auth/login')
  Future<HttpResponse<LoginResponse>> login(@Body() Map<String, dynamic> data);

  @GET('/auth/me')
  Future<HttpResponse<UserModel>> getMe();

  @PUT('/auth/updatedetails')
  Future<HttpResponse<UserModel>> updateProfile(
    @Body() Map<String, dynamic> data,
  );

  // Products
  @GET('/products')
  Future<HttpResponse<ProductListResponse>> getProducts({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('category') String? category,
    @Query('search') String? search,
    @Query('isFeatured') bool? isFeatured,
    @Query('sort') String? sort,
    @Query('minPrice') double? minPrice,
    @Query('maxPrice') double? maxPrice,
    @Query('rating') double? rating,
  });

  @GET('/products/featured')
  Future<HttpResponse<FeaturedProductsResponse>> getFeaturedProducts();

  @GET('/products/{id}')
  Future<HttpResponse<ProductDetailResponse>> getProductById(
    @Path('id') String id,
  );

  @POST('/products')
  Future<HttpResponse<ProductDetailResponse>> createProduct(
    @Body() Map<String, dynamic> data,
  );

  @PUT('/products/{id}')
  Future<HttpResponse<ProductDetailResponse>> updateProduct(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/products/{id}')
  Future<HttpResponse<void>> deleteProduct(@Path('id') String id);

  // Cart
  @GET('/cart')
  Future<HttpResponse<CartResponse>> getCart();

  @POST('/cart/items')
  Future<HttpResponse<CartResponse>> addToCart(
    @Body() Map<String, dynamic> data,
  );

  @PUT('/cart/items/{itemId}')
  Future<HttpResponse<CartResponse>> updateCartItem(
    @Path('itemId') String itemId,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/cart/items/{itemId}')
  Future<HttpResponse<void>> removeFromCart(@Path('itemId') String itemId);

  @DELETE('/cart')
  Future<HttpResponse<void>> clearCart();

  // Orders
  @POST('/orders')
  Future<HttpResponse<OrderResponse>> createOrder(
    @Body() Map<String, dynamic> data,
  );

  @GET('/orders/myorders')
  Future<HttpResponse<OrderListResponse>> getMyOrders();

  @GET('/orders')
  Future<HttpResponse<AdminOrderListResponse>> getAllOrders({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('status') String? status,
  });

  @GET('/orders/{id}')
  Future<HttpResponse<OrderResponse>> getOrderById(@Path('id') String id);

  @PUT('/orders/{id}/status')
  Future<HttpResponse<OrderResponse>> updateOrderStatus(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/orders/create-payment-intent')
  Future<HttpResponse<PaymentIntentResponse>> createPaymentIntent(
    @Body() Map<String, dynamic> data,
  );

  // Wishlist
  @GET('/wishlist')
  Future<HttpResponse<List<ProductModel>>> getWishlist();

  @POST('/wishlist')
  Future<HttpResponse<void>> addToWishlist(@Body() Map<String, dynamic> data);

  @DELETE('/wishlist/{productId}')
  Future<HttpResponse<void>> removeFromWishlist(
    @Path('productId') String productId,
  );

  // Reviews
  @POST('/reviews/product/{productId}')
  Future<HttpResponse<ReviewModel>> addReview(
    @Path('productId') String productId,
    @Body() Map<String, dynamic> data,
  );

  @GET('/reviews/product/{productId}')
  Future<HttpResponse<List<ReviewModel>>> getProductReviews(
    @Path('productId') String productId,
  );
}

@JsonSerializable()
class LoginResponse {
  final bool success;
  final String token;
  final UserModel user;

  LoginResponse({
    required this.success,
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@JsonSerializable()
class ProductListResponse {
  final bool success;
  final int count;
  final int total;
  final Pagination pagination;
  final List<ProductModel> data;

  ProductListResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.pagination,
    required this.data,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseFromJson(json);
}

@JsonSerializable()
class FeaturedProductsResponse {
  final bool success;
  final List<ProductModel> data;

  FeaturedProductsResponse({required this.success, required this.data});

  factory FeaturedProductsResponse.fromJson(Map<String, dynamic> json) =>
      _$FeaturedProductsResponseFromJson(json);
}

@JsonSerializable()
class ProductDetailResponse {
  final bool success;
  final ProductModel data;

  ProductDetailResponse({required this.success, required this.data});

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailResponseFromJson(json);
}

@JsonSerializable()
class CartResponse {
  final bool success;
  final CartModel data;

  CartResponse({required this.success, required this.data});

  factory CartResponse.fromJson(Map<String, dynamic> json) =>
      _$CartResponseFromJson(json);
}

@JsonSerializable()
class OrderResponse {
  final bool success;
  final OrderModel data;

  OrderResponse({required this.success, required this.data});

  factory OrderResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseFromJson(json);
}

@JsonSerializable()
class OrderListResponse {
  final bool success;
  final int count;
  final List<OrderModel> data;

  OrderListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderListResponseFromJson(json);
}

@JsonSerializable()
class AdminOrderListResponse {
  final bool success;
  final int count;
  final int total;
  final Pagination pagination;
  final List<OrderModel> data;

  AdminOrderListResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.pagination,
    required this.data,
  });

  factory AdminOrderListResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminOrderListResponseFromJson(json);
}

@JsonSerializable()
class Pagination {
  final int page;
  final int pages;
  final bool hasNext;

  Pagination({required this.page, required this.pages, required this.hasNext});

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
}

@JsonSerializable()
class PaymentIntentResponse {
  final bool success;
  final String clientSecret;

  PaymentIntentResponse({required this.success, required this.clientSecret});

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentResponseFromJson(json);
}
