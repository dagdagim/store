import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/category_card.dart';
import '../products/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();

  final List<String> _banners = [
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=1200&q=80',
  ];

  final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Men', 'icon': '👔', 'color': 0xFF2E5BFF, 'category': 'men'},
    {'name': 'Women', 'icon': '👗', 'color': 0xFFFF6B6B, 'category': 'women'},
    {'name': 'Kids', 'icon': '🧸', 'color': 0xFF4ECDC4, 'category': 'kids'},
    {'name': 'Shoes', 'icon': '👟', 'color': 0xFF7C3AED, 'category': 'shoes'},
    {
      'name': 'Accessories',
      'icon': '🕶️',
      'color': 0xFFFFE66D,
      'category': 'accessories',
    },
  ];

  List<Map<String, dynamic>> _shopCategories = [];

  final List<Map<String, String>> _quickActions = [
    {'title': 'New In', 'subtitle': 'Latest arrivals', 'emoji': '🆕'},
    {'title': 'Sale', 'subtitle': 'Up to 50% off', 'emoji': '🔥'},
    {'title': 'Trending', 'subtitle': 'Most loved picks', 'emoji': '⭐'},
  ];

  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      productProvider.loadProducts(),
      productProvider.loadFeaturedProducts(),
      _loadShopCategories(),
    ]);
  }

  Future<void> _loadShopCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      final mapped = categories
          .where((CategoryModel item) => item.isActive)
          .map((CategoryModel item) {
            final key = item.name.trim().toLowerCase();
            return {
              'name': _titleCase(item.name.trim()),
              'icon': _categoryIcon(key),
              'color': _categoryColor(key).value,
              'category': key,
            };
          })
          .toList();

      final mergedByKey = <String, Map<String, dynamic>>{
        for (final item in _defaultCategories)
          item['category'].toString().toLowerCase(): item,
      };

      for (final item in mapped) {
        mergedByKey[item['category'].toString().toLowerCase()] = item;
      }

      final merged = mergedByKey.values.toList();
      merged.sort((a, b) {
        final aKey = a['category'].toString().toLowerCase();
        final bKey = b['category'].toString().toLowerCase();
        final aDefault = _defaultCategories.any(
          (item) => item['category'].toString().toLowerCase() == aKey,
        );
        final bDefault = _defaultCategories.any(
          (item) => item['category'].toString().toLowerCase() == bKey,
        );

        if (aDefault && !bDefault) return -1;
        if (!aDefault && bDefault) return 1;
        return a['name'].toString().compareTo(b['name'].toString());
      });

      if (!mounted) return;
      setState(() {
        _shopCategories = merged;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shopCategories = List.from(_defaultCategories);
      });
    }
  }

  String _titleCase(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;

    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String _categoryIcon(String category) {
    switch (category) {
      case 'men':
        return '👔';
      case 'women':
        return '👗';
      case 'kids':
        return '🧸';
      case 'accessories':
        return '🕶️';
      case 'shoes':
        return '👟';
      case 'bags':
        return '👜';
      default:
        return '🛍️';
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'men':
        return const Color(0xFF2E5BFF);
      case 'women':
        return const Color(0xFFFF6B6B);
      case 'kids':
        return const Color(0xFF4ECDC4);
      case 'accessories':
        return const Color(0xFFFFE66D);
      case 'shoes':
        return const Color(0xFF7C3AED);
      default:
        final palette = [
          const Color(0xFF8E7CFF),
          const Color(0xFF00B894),
          const Color(0xFFFF8C42),
          const Color(0xFF3D7EFF),
        ];
        final index = category.hashCode.abs() % palette.length;
        return palette[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildHomeContent(productProvider, authProvider),
          const CartScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(
    ProductProvider productProvider,
    AuthProvider authProvider,
  ) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withAlpha(179),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          authProvider.user?.name ?? 'Guest',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'My Orders',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrdersScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProductListScreen(searchMode: true),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.black54),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search styles, brands, categories',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickActions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = _quickActions[index];
                        return Container(
                          width: 170,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withAlpha(26),
                                Theme.of(context).primaryColor.withAlpha(10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha(28),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item['emoji']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['subtitle']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shop by Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Curated for you',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _shopCategories.length,
                      itemBuilder: (context, index) {
                        return CategoryCard(
                          name: _shopCategories[index]['name'],
                          icon: _shopCategories[index]['icon'],
                          color: Color(_shopCategories[index]['color']),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                  category: _shopCategories[index]['category'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Banner Carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                      onPageChanged: (index, reason) {},
                    ),
                    items: _banners.map((url) {
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, _) =>
                                  Container(color: Colors.grey.shade200),
                              errorWidget: (context, _, __) => Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Featured Products Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Products',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProductListScreen(featured: true),
                            ),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Products Grid
                  if (productProvider.featuredProducts.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount: productProvider.featuredProducts.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: productProvider.featuredProducts[index],
                        );
                      },
                    )
                  else if (productProvider.isLoading)
                    Container(
                      height: 160,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const CircularProgressIndicator(),
                    )
                  else
                    Container(
                      height: 160,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        productProvider.error ??
                            'No featured products available right now.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
