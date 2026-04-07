import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/product_model.dart' hide Color;
import '../../../data/models/review_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/review_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductRepository _repository = ProductRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();
  final DateFormat _reviewDateFormat = DateFormat('dd MMM yyyy');
  late Future<ProductModel> _productFuture;
  int _quantity = 1;
  String? _selectedSize;
  String? _selectedColor;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _productFuture = _repository.getProductById(widget.productId);
    _loadReviews();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final wishlistProvider = context.read<WishlistProvider>();
      if (wishlistProvider.items.isEmpty && !wishlistProvider.isLoading) {
        wishlistProvider.loadWishlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ProductModel>(
          future: _productFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load product: ${snapshot.error}'),
              );
            }

            final product = snapshot.data;
            if (product == null) {
              return const Center(child: Text('Product not found'));
            }

            final isFavorite = context.select<WishlistProvider, bool>(
              (provider) => provider.isFavorite(product.id),
            );

            final imageUrls = _resolveImages(product);
            _selectedSize ??= _defaultSizeFor(product);
            _selectedColor ??= product.colors.isNotEmpty
                ? product.colors.first.name
                : null;
            final availableStock = _availableStockFor(product);
            final canAddToCart = product.isAvailable && availableStock > 0;

            if (canAddToCart && _quantity > availableStock) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _quantity = availableStock;
                });
              });
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Product Detail'),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () => _toggleFavorite(product),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(imageUrls),
                    const SizedBox(height: 16),
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.brand,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRating(product.rating),
                        const SizedBox(width: 12),
                        Text(
                          '${product.numReviews} reviews',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPriceRow(context, product),
                    const SizedBox(height: 20),
                    if (product.sizes.isNotEmpty) ...[
                      Text(
                        'Select Size',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: product.sizes
                            .map(
                              (size) => ChoiceChip(
                                label: Text(
                                  size.stock > 0
                                      ? '${size.size} (${size.stock})'
                                      : '${size.size} (Out)',
                                ),
                                selected: _selectedSize == size.size,
                                onSelected: size.stock <= 0
                                    ? null
                                    : (_) {
                                  setState(() {
                                    _selectedSize = size.size;
                                    if (_quantity > size.stock) {
                                      _quantity = size.stock;
                                    }
                                    if (_quantity <= 0) {
                                      _quantity = 1;
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildStockBanner(availableStock, canAddToCart),
                    const SizedBox(height: 16),
                    if (product.colors.isNotEmpty) ...[
                      Text(
                        'Select Color',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: product.colors
                            .map(
                              (color) => ChoiceChip(
                                label: Text(color.name),
                                selected: _selectedColor == color.name,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedColor = color.name;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    _buildReviewSection(product, authProvider),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity -= 1)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$_quantity'),
                            IconButton(
                              onPressed: canAddToCart && _quantity < availableStock
                                  ? () => setState(() => _quantity += 1)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: canAddToCart ? () => _addToCart(product) : null,
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: Text(canAddToCart ? 'Add to Cart' : 'Out of Stock'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<String> _resolveImages(ProductModel product) {
    if (product.colors.isEmpty) {
      return ['https://picsum.photos/seed/product-detail/900/1200'];
    }

    final images = product.colors.expand((color) => color.images).toList();
    if (images.isEmpty) {
      return ['https://picsum.photos/seed/product-detail/900/1200'];
    }

    return images.take(6).toList();
  }

  String? _defaultSizeFor(ProductModel product) {
    if (product.sizes.isEmpty) {
      return null;
    }

    for (final size in product.sizes) {
      if (size.stock > 0) {
        return size.size;
      }
    }

    return product.sizes.first.size;
  }

  int _availableStockFor(ProductModel product) {
    if (product.sizes.isEmpty) {
      return product.totalStock;
    }

    if (_selectedSize == null) {
      return 0;
    }

    final match = product.sizes.where((size) => size.size == _selectedSize);
    if (match.isEmpty) {
      return 0;
    }

    return match.first.stock;
  }

  Widget _buildStockBanner(int availableStock, bool canAddToCart) {
    Color background;
    Color foreground;
    String message;

    if (!canAddToCart) {
      background = Colors.red.shade50;
      foreground = Colors.red.shade900;
      message = 'Out of stock right now';
    } else if (availableStock <= 5) {
      background = Colors.orange.shade50;
      foreground = Colors.orange.shade900;
      message = 'Only $availableStock left';
    } else {
      background = Colors.green.shade50;
      foreground = Colors.green.shade900;
      message = '$availableStock in stock';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return AspectRatio(
      aspectRatio: 0.85,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: PageView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, _) =>
                  Container(color: Colors.grey.shade200),
              errorWidget: (context, _, __) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, ProductModel product) {
    if (product.discount > 0) {
      return Row(
        children: [
          Text(
            product.originalPrice,
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            product.formattedPrice,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      );
    }

    return Text(
      product.formattedPrice,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildReviewSection(ProductModel product, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ratings & Feedback',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: authProvider.isAuthenticated
                  ? () => _showReviewDialog(product)
                  : null,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Write Review'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!authProvider.isAuthenticated)
          Text(
            'Login to submit feedback and ratings.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        if (_isLoadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No feedback yet. Be the first to review this product!'),
          )
        else
          ..._reviews.take(6).map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withAlpha(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.userName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              review.rating.toString(),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(review.comment),
                  const SizedBox(height: 6),
                  Text(
                    _reviewDateFormat.format(review.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final reviews = await _reviewRepository.getProductReviews(widget.productId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _showReviewDialog(ProductModel product) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showSnack('Please login first to submit feedback');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final commentController = TextEditingController();
    int selectedRating = 5;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Feedback & Rating'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your Rating',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedRating = starValue;
                              });
                            },
                            icon: Icon(
                              starValue <= selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                          );
                        }),
                      ),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: commentController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Feedback'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (value.trim().length < 5) return 'Min 5 characters';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await _reviewRepository.createReview(
                        productId: product.id,
                        rating: selectedRating,
                        title: titleController.text.trim(),
                        comment: commentController.text.trim(),
                      );

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    commentController.dispose();

    if (saved == true) {
      _showSnack('Feedback submitted');
      setState(() {
        _productFuture = _repository.getProductById(widget.productId);
      });
      await _loadReviews();
    }
  }

  Future<void> _addToCart(ProductModel product) async {
    if (_selectedSize == null && product.sizes.isNotEmpty) {
      _showSnack('Please select a size');
      return;
    }

    if (_selectedColor == null && product.colors.isNotEmpty) {
      _showSnack('Please select a color');
      return;
    }

    final availableStock = _availableStockFor(product);
    if (!product.isAvailable || availableStock <= 0) {
      _showSnack('This item is currently out of stock');
      return;
    }

    if (_quantity > availableStock) {
      _showSnack('Only $availableStock item(s) available for selected size');
      return;
    }

    try {
      final provider = Provider.of<CartProvider>(context, listen: false);
      await provider.addToCart(
        productId: product.id,
        quantity: _quantity,
        size: _selectedSize ?? '',
        color: _selectedColor ?? '',
      );
      _showSnack('Added to cart');
    } catch (e) {
      _showSnack('Failed to add to cart');
    }
  }

  Future<void> _toggleFavorite(ProductModel product) async {
    final wishlistProvider = context.read<WishlistProvider>();
    final wasFavorite = wishlistProvider.isFavorite(product.id);
    final success = await wishlistProvider.toggleWishlist(product);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnack('Could not update favorites');
      return;
    }

    _showSnack(
      wasFavorite ? 'Removed from favorites' : 'Added to favorites',
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
