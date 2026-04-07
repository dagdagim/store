import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart' as model;
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../../services/local_storage_service.dart';

class _BulkRestockSnapshot {
  final String productId;
  final Map<String, int> previousStocks;

  _BulkRestockSnapshot({
    required this.productId,
    required this.previousStocks,
  });
}

class AdminProductsScreen extends StatefulWidget {
  final bool initialLowStockOnly;
  final String? initialCategoryFocus;

  const AdminProductsScreen({
    super.key,
    this.initialLowStockOnly = false,
    this.initialCategoryFocus,
  });

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductRepository _repository = ProductRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  final List<String> _defaultCategories = ['men', 'women', 'kids', 'shoes', 'accessories'];
  List<String> _categories = ['men', 'women', 'kids', 'shoes', 'accessories'];

  List<model.ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  String _stockFilter = 'all';
  String? _categoryFocus;
  List<_BulkRestockSnapshot> _lastBulkRestockSnapshots = [];

  List<model.ProductModel> get _lowStockProducts => _products
      .where((item) => item.isAvailable && item.totalStock > 0 && item.totalStock <= 5)
      .toList();

  List<model.ProductModel> get _outOfStockProducts => _products
      .where((item) => !item.isAvailable || item.totalStock <= 0)
      .toList();

  List<model.ProductModel> get _visibleProducts {
    final categoryFiltered = _categoryFocus == null
        ? _products
        : _products
            .where((item) => item.category.toLowerCase() == _categoryFocus)
            .toList();

    switch (_stockFilter) {
      case 'low':
        return categoryFiltered
            .where((item) => item.isAvailable && item.totalStock > 0 && item.totalStock <= 5)
            .toList();
      case 'out':
        return categoryFiltered
            .where((item) => !item.isAvailable || item.totalStock <= 0)
            .toList();
      default:
        return categoryFiltered;
    }
  }

  @override
  void initState() {
    super.initState();
    _stockFilter = widget.initialLowStockOnly ? 'low' : 'all';
    _categoryFocus = widget.initialCategoryFocus?.trim().toLowerCase();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.getProducts(page: 1, limit: 100);
      final categories = await _categoryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _products = response.data;
        final dynamicCategories = categories
            .where((item) => item.isActive)
            .map((item) => item.name.trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        _categories = {
          ..._defaultCategories,
          ...dynamicCategories,
        }.toList()
          ..sort();

        if (_categoryFocus != null &&
            !_products.any((item) => item.category.toLowerCase() == _categoryFocus)) {
          _categoryFocus = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Admin Products'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2F6BFF),
        foregroundColor: Colors.white,
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 44,
              ),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F6BFF).withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF2F6BFF),
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No products yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your first product to start selling.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openProductForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6BFF), Color(0xFF6E9BFF)],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_products.length} products • ${_lowStockProducts.length} low stock • ${_outOfStockProducts.length} out of stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _stockFilter == 'all',
                onSelected: (_) {
                  setState(() {
                    _stockFilter = 'all';
                  });
                },
              ),
              FilterChip(
                label: Text('Low Stock (${_lowStockProducts.length})'),
                selected: _stockFilter == 'low',
                onSelected: (_) {
                  setState(() {
                    _stockFilter = 'low';
                  });
                },
              ),
              FilterChip(
                label: Text('Out of Stock (${_outOfStockProducts.length})'),
                selected: _stockFilter == 'out',
                onSelected: (_) {
                  setState(() {
                    _stockFilter = 'out';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final categoryOptions = _products
                  .map((item) => item.category.toLowerCase())
                  .toSet()
                  .toList()
                ..sort();

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All Categories'),
                    selected: _categoryFocus == null,
                    onSelected: (_) {
                      setState(() {
                        _categoryFocus = null;
                      });
                    },
                  ),
                  ...categoryOptions.map((entry) {
                    return FilterChip(
                      label: Text(entry.toUpperCase()),
                      selected: _categoryFocus == entry,
                      onSelected: (_) {
                        setState(() {
                          _categoryFocus = entry;
                        });
                      },
                    );
                  }),
                ],
              );
            },
          ),
          if (_categoryFocus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _visibleProducts.isEmpty
                          ? null
                          : () => _openBulkCategoryRestockDialog(),
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: Text(
                        'Bulk Restock ${_categoryFocus!.toUpperCase()} (${_visibleProducts.length})',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _lastBulkRestockSnapshots.isEmpty
                          ? null
                          : () => _undoLastBulkRestock(),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo Last Bulk Restock'),
                    ),
                  ],
                ),
              ),
            ),
          if (_visibleProducts.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No products in this stock bucket.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ..._visibleProducts.map((product) {
            final isOut = !product.isAvailable || product.totalStock <= 0;
            final isLow = !isOut && product.totalStock <= 5;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                leading: _thumbnail(product),
                title: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${product.category.toUpperCase()} • ${product.formattedPrice}'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOut
                            ? Colors.red.withAlpha(20)
                            : isLow
                                ? Colors.orange.withAlpha(20)
                                : Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isOut ? 'OUT' : isLow ? 'LOW: ${product.totalStock}' : 'STOCK: ${product.totalStock}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOut
                              ? Colors.red
                              : isLow
                                  ? Colors.orange.shade900
                                  : Colors.blue,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? Colors.green.withAlpha(20)
                            : Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product.isAvailable ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: product.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Restock',
                      onPressed: () => _openRestockDialog(product),
                      icon: const Icon(Icons.add_box_outlined),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _openProductForm(existing: product),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteProduct(product),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _thumbnail(model.ProductModel product) {
    final imageUrl = product.colors.isNotEmpty && product.colors.first.images.isNotEmpty
        ? product.colors.first.images.first
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: Colors.grey.shade200,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
              )
            : const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }

  Future<void> _openProductForm({model.ProductModel? existing}) async {
    if (_categories.isEmpty) {
      try {
        final categories = await _categoryRepository.getCategories();
        final mapped = categories
            .where((item) => item.isActive)
            .map((CategoryModel item) => item.name.trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        _categories = {
          ..._defaultCategories,
          ...mapped,
        }.toList()
          ..sort();
      } catch (_) {}
    }

    if (_categories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one category first')),
        );
      }
      return;
    }

    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final priceController = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(2) : '',
    );
    final brandController = TextEditingController(text: existing?.brand ?? '');
    final sizesController = TextEditingController(
      text: existing == null
          ? ''
          : existing.sizes.map((item) => '${item.size}:${item.stock}').join(', '),
    );
    final imagesController = TextEditingController(
      text: existing == null
          ? ''
          : existing.colors
              .expand((item) => item.images)
              .where((url) => url.trim().isNotEmpty)
              .toSet()
              .join('\n'),
    );

    String category = existing?.category.toLowerCase() ?? _categories.first;
    if (!_categories.contains(category)) {
      category = _categories.first;
    }
    bool isFeatured = existing?.isFeatured ?? false;
    bool isAvailable = existing?.isAvailable ?? true;
    final pickedFiles = <XFile>[];
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Product' : 'Edit Product'),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Description'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Required';
                            if (value.trim().length < 10) return 'Min 10 chars';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Price'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Required';
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed < 0) return 'Invalid price';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: brandController,
                          decoration: const InputDecoration(labelText: 'Brand'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: sizesController,
                          decoration: const InputDecoration(
                            labelText: 'Sizes',
                            hintText: 'Example: S:20, M:35, L:18',
                          ),
                          validator: (value) {
                            final parsed = _parseSizes(value ?? '');
                            if (parsed.isEmpty) {
                              return 'Add at least one size (e.g. M:20)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: imagesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Image URLs',
                            hintText: 'One URL per line (or comma separated)',
                          ),
                          validator: (value) {
                            final parsed = _parseImageUrls(value ?? '');
                            if (parsed.isEmpty && pickedFiles.isEmpty) {
                              return 'Add image URL or browse image files';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final images = await ImagePicker().pickMultiImage(
                                imageQuality: 85,
                              );
                              if (images.isEmpty) return;

                              setDialogState(() {
                                pickedFiles
                                  ..clear()
                                  ..addAll(images);
                              });
                            },
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Browse from files'),
                          ),
                        ),
                        if (pickedFiles.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${pickedFiles.length} file(s) selected',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2F6BFF),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: _categories
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                category = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          value: isFeatured,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Featured Product'),
                          onChanged: (value) {
                            setDialogState(() {
                              isFeatured = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          value: isAvailable,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Available'),
                          onChanged: (value) {
                            setDialogState(() {
                              isAvailable = value;
                            });
                          },
                        ),
                      ],
                    ),
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
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final payload = {
                      'slug': _slugify(nameController.text.trim()),
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'price': double.parse(priceController.text.trim()),
                      'brand': brandController.text.trim(),
                      'category': category,
                      'sizes': _parseSizes(sizesController.text.trim()),
                      'colors': _buildColorsFromImages(
                        _parseImageUrls(imagesController.text.trim()),
                        _parseSizes(sizesController.text.trim()),
                      ),
                      'isFeatured': isFeatured,
                      'isAvailable': isAvailable,
                    };

                    try {
                      late model.ProductModel savedProduct;
                      if (existing == null) {
                        savedProduct = await _repository.createProduct(payload);
                      } else {
                        savedProduct = await _repository.updateProduct(
                          productId: existing.id,
                          data: payload,
                        );
                      }

                      if (pickedFiles.isNotEmpty) {
                        await _repository.uploadProductImages(
                          productId: savedProduct.id,
                          files: pickedFiles,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    brandController.dispose();
    sizesController.dispose();
    imagesController.dispose();

    if (saved == true) {
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Product created successfully'
                : 'Product updated successfully',
          ),
        ),
      );
    }
  }

  Future<void> _deleteProduct(model.ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete product'),
          content: Text('Delete "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteProduct(product.id);
      if (!mounted) return;
      setState(() {
        _products = _products.where((item) => item.id != product.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openRestockDialog(
    model.ProductModel product, {
    int? suggestedQty,
  }) async {
    if (product.sizes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sizes configured for this product')),
      );
      return;
    }

    final stocks = <String, int>{
      for (final size in product.sizes) size.size: size.stock,
    };
    int quickAdd = suggestedQty != null && suggestedQty > 0 ? suggestedQty : 5;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sizeRows = product.sizes.map((sizeEntry) {
              final size = sizeEntry.size;
              final currentStock = stocks[size] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      child: Text(
                        size,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: currentStock > 0
                          ? () {
                              setDialogState(() {
                                stocks[size] = currentStock - 1;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$currentStock',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          stocks[size] = currentStock + 1;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              );
            }).toList();

            return AlertDialog(
              title: const Text('Quick Restock'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (suggestedQty != null && suggestedQty > 0 && suggestedQty != 5 && suggestedQty != 10)
                            ChoiceChip(
                              label: Text('+$suggestedQty all'),
                              selected: quickAdd == suggestedQty,
                              onSelected: (_) {
                                setDialogState(() {
                                  quickAdd = suggestedQty;
                                });
                              },
                            ),
                          ChoiceChip(
                            label: const Text('+5 all'),
                            selected: quickAdd == 5,
                            onSelected: (_) {
                              setDialogState(() {
                                quickAdd = 5;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('+10 all'),
                            selected: quickAdd == 10,
                            onSelected: (_) {
                              setDialogState(() {
                                quickAdd = 10;
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Apply to all sizes'),
                            onPressed: () {
                              setDialogState(() {
                                for (final item in product.sizes) {
                                  final current = stocks[item.size] ?? 0;
                                  stocks[item.size] = current + quickAdd;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Adjust size stock',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...sizeRows,
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
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save Stock'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      return;
    }

    final updateSuccess = await _applyRestockToProduct(
      product,
      stocks,
      successMessage: 'Stock updated successfully',
    );

    if (!updateSuccess) {
      return;
    }

    await LocalStorageService.addInventoryAuditLog(
      action: 'single_restock',
      category: product.category,
      productName: product.name,
      successCount: 1,
      failedCount: 0,
      affectedProducts: 1,
    );

    await _loadProducts();
  }

  int _suggestedReorderQty(model.ProductModel product) {
    final threshold = 5;
    final stock = product.totalStock;
    final demandGap = ((product.sold * 0.15).ceil() - stock);
    final thresholdGap = (threshold * 2) - stock;
    return [1, thresholdGap, demandGap].reduce((a, b) => a > b ? a : b);
  }

  Future<void> _openBulkCategoryRestockDialog() async {
    if (_categoryFocus == null) {
      return;
    }

    final targets = _visibleProducts.where((item) => item.sizes.isNotEmpty).toList();
    if (targets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No size-based products in this filtered list')),
      );
      return;
    }

    final totalSuggested = targets.fold<int>(0, (sum, item) => sum + _suggestedReorderQty(item));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bulk Category Restock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${_categoryFocus!.toUpperCase()}'),
              const SizedBox(height: 6),
              Text('Products to update: ${targets.length}'),
              const SizedBox(height: 6),
              Text('Total suggested reorder: +$totalSuggested units'),
              const SizedBox(height: 10),
              const Text(
                'This will distribute each product\'s suggested reorder quantity across its sizes.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    int successCount = 0;
    int failedCount = 0;
    final successfulSnapshots = <_BulkRestockSnapshot>[];

    for (final product in targets) {
      final suggested = _suggestedReorderQty(product);
      final sizeCount = product.sizes.length;
      final perSize = suggested ~/ sizeCount;
      final remainder = suggested % sizeCount;

      final stocks = <String, int>{};
      final previousStocks = <String, int>{
        for (final size in product.sizes) size.size: size.stock,
      };
      for (var i = 0; i < product.sizes.length; i++) {
        final size = product.sizes[i];
        final increment = perSize + (i < remainder ? 1 : 0);
        stocks[size.size] = size.stock + increment;
      }

      final updated = await _applyRestockToProduct(
        product,
        stocks,
        successMessage: null,
      );
      if (updated) {
        successCount += 1;
        successfulSnapshots.add(
          _BulkRestockSnapshot(
            productId: product.id,
            previousStocks: previousStocks,
          ),
        );
      } else {
        failedCount += 1;
      }
    }

    if (mounted) {
      setState(() {
        _lastBulkRestockSnapshots = successfulSnapshots;
      });
    }

    await LocalStorageService.addInventoryAuditLog(
      action: 'bulk_restock',
      category: _categoryFocus,
      successCount: successCount,
      failedCount: failedCount,
      affectedProducts: targets.length,
    );

    await _loadProducts();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failedCount == 0
              ? 'Bulk restock applied to $successCount product(s)'
              : 'Bulk restock: $successCount updated, $failedCount failed',
        ),
      ),
    );
  }

  Future<void> _undoLastBulkRestock() async {
    if (_lastBulkRestockSnapshots.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Undo Bulk Restock'),
          content: Text(
            'Revert stock changes for ${_lastBulkRestockSnapshots.length} product(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Undo'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    int successCount = 0;
    int failedCount = 0;
    final remainingSnapshots = <_BulkRestockSnapshot>[];

    for (final snapshot in _lastBulkRestockSnapshots) {
      final current = _products
          .where((item) => item.id == snapshot.productId)
          .toList();
      if (current.isEmpty) {
        failedCount += 1;
        remainingSnapshots.add(snapshot);
        continue;
      }

      final updated = await _applyRestockToProduct(
        current.first,
        snapshot.previousStocks,
        successMessage: null,
      );

      if (updated) {
        successCount += 1;
      } else {
        failedCount += 1;
        remainingSnapshots.add(snapshot);
      }
    }

    if (mounted) {
      setState(() {
        _lastBulkRestockSnapshots = remainingSnapshots;
      });
    }

    await LocalStorageService.addInventoryAuditLog(
      action: 'undo_bulk_restock',
      category: _categoryFocus,
      successCount: successCount,
      failedCount: failedCount,
      affectedProducts: _lastBulkRestockSnapshots.length + successCount,
    );

    await _loadProducts();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failedCount == 0
              ? 'Undo completed for $successCount product(s)'
              : 'Undo: $successCount reverted, $failedCount failed',
        ),
      ),
    );
  }

  Future<bool> _applyRestockToProduct(
    model.ProductModel product,
    Map<String, int> stocks, {
    String? successMessage,
  }) async {

    final updatedSizes = product.sizes.map((item) {
      return {
        'size': item.size,
        'stock': stocks[item.size] ?? 0,
        'sku': item.sku,
      };
    }).toList();

    final totalStock = updatedSizes.fold<int>(
      0,
      (sum, item) => sum + ((item['stock'] as int?) ?? 0),
    );

    final updatedColors = product.colors.map((color) {
      return {
        'name': color.name,
        'hex': color.hex,
        'images': color.images,
        'stock': totalStock,
      };
    }).toList();

    try {
      await _repository.updateProduct(
        productId: product.id,
        data: {
          'sizes': updatedSizes,
          'colors': updatedColors,
          'isAvailable': totalStock > 0,
        },
      );

      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
      return true;
    } catch (e) {
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return false;
    }
  }

  List<Map<String, dynamic>> _parseSizes(String input) {
    const allowedSizes = {'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'};
    final tokens = input
        .split(RegExp(r'[,\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final parsed = <Map<String, dynamic>>[];
    for (final token in tokens) {
      final parts = token.split(':');
      if (parts.isEmpty) {
        continue;
      }

      final size = parts.first.trim().toUpperCase();
      if (!allowedSizes.contains(size)) {
        continue;
      }

      final stock = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
      parsed.add({
        'size': size,
        'stock': stock < 0 ? 0 : stock,
        'sku': 'SKU-$size-${DateTime.now().millisecondsSinceEpoch}',
      });
    }

    return parsed;
  }

  List<String> _parseImageUrls(String input) {
    return input
        .split(RegExp(r'[,\n]+'))
        .map((item) => item.trim())
        .where((item) => item.startsWith('http://') || item.startsWith('https://'))
        .toList();
  }

  List<Map<String, dynamic>> _buildColorsFromImages(
    List<String> images,
    List<Map<String, dynamic>> sizes,
  ) {
    final totalStock = sizes.fold<int>(
      0,
      (sum, item) => sum + ((item['stock'] as int?) ?? 0),
    );

    return [
      {
        'name': 'Default',
        'hex': '#1F2937',
        'images': images,
        'stock': totalStock,
      },
    ];
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }
}
