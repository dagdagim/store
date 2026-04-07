import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Clothing Store';
  static const String apiBaseUrl = 'http://localhost:5000/api/v1';
  static const String stripePublishableKey = 'pk_test_your_stripe_key';

  static String get runtimeApiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/v1';
    }

    return 'http://localhost:5000/api/v1';
  }

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_completed';

  // Pagination
  static const int defaultPageSize = 12;

  // Currency
  static const String currency = '\$';

  // Shipping
  static const double freeShippingThreshold = 50.0;
  static const double shippingCost = 5.99;
  static const double taxRate = 0.08;
}
