import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/presentation/providers/auth_provider.dart';
import 'core/presentation/providers/cart_provider.dart';
import 'core/presentation/providers/product_provider.dart';
import 'core/presentation/providers/theme_provider.dart';
import 'core/presentation/providers/order_provider.dart';
import 'core/presentation/providers/wishlist_provider.dart';
import 'core/presentation/screens/splash/splash_screen.dart';
import 'core/presentation/screens/auth/login_screen.dart';
import 'core/presentation/screens/home/home_screen.dart';
import 'core/presentation/screens/onboarding/onboarding_screen.dart';
import 'core/presentation/screens/orders/orders_screen.dart';
import 'core/presentation/screens/admin/admin_orders_screen.dart';
import 'core/presentation/screens/admin/admin_products_screen.dart';
import 'core/presentation/screens/admin/admin_dashboard_screen.dart';
import 'core/presentation/screens/admin/admin_users_screen.dart';
import 'core/presentation/screens/admin/admin_categories_screen.dart';
import 'core/presentation/screens/admin/admin_promotions_screen.dart';
import 'core/presentation/screens/admin/admin_reviews_screen.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await LocalStorageService.init();
  
  // Initialize Stripe (skip on web)
  if (!kIsWeb) {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Clothing Store',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/admin/dashboard': (context) => const AdminDashboardScreen(),
              '/admin/orders': (context) => const AdminOrdersScreen(),
              '/admin/products': (context) => const AdminProductsScreen(),
              '/admin/users': (context) => const AdminUsersScreen(),
              '/admin/categories': (context) => const AdminCategoriesScreen(),
              '/admin/promotions': (context) => const AdminPromotionsScreen(),
              '/admin/reviews': (context) => const AdminReviewsScreen(),
            },
          );
        },
      ),
    );
  }
}