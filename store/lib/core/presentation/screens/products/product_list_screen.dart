import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../../widgets/product_card.dart';
import '../../../../services/local_storage_service.dart';

class ProductListScreen extends StatefulWidget {
  final String? category;
  final bool featured;
  final bool searchMode;

  const ProductListScreen({
    super.key,
    this.category,
    this.featured = false,
    this.searchMode = false,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  List<String> _recentSearches = [];

  String _sort = 'newest';
  double? _selectedRating;
  double? _selectedMinPrice;
  double? _selectedMaxPrice;

  final List<String> _searchHints = const [
    'hoodie',
    'jacket',
    'shoes',
    'dress',
    'kids',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.loadProducts(
      category: widget.category,
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      sort: _sort,
      minPrice: _selectedMinPrice,
      maxPrice: _selectedMaxPrice,
      rating: _selectedRating,
    );
  }

  Future<void> _loadRecentSearches() async {
    setState(() {
      _recentSearches = LocalStorageService.getRecentSearches();
    });
  }

  Future<void> _saveSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await LocalStorageService.saveRecentSearch(trimmed);
    await _loadRecentSearches();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadProducts);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicSuggestions = <String>{
      ..._searchHints,
      ..._recentSearches,
    }.where((item) {
      if (!widget.searchMode) return false;
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        return _recentSearches.contains(item) || _searchHints.contains(item);
      }
      return item.toLowerCase().contains(query);
    }).take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: widget.searchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {});
                  _onSearchChanged(value);
                },
                onSubmitted: (value) {
                  _searchDebounce?.cancel();
                  _searchQuery = value;
                  _loadProducts();
                  _saveSearch(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _loadProducts();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
              )
            : Text(widget.category == null
                ? 'Products'
                : '${widget.category![0].toUpperCase()}${widget.category!.substring(1)}'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    Text(provider.error!, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          if (provider.products.isEmpty) {
            return Column(
              children: [
                _buildFilters(),
                const Spacer(),
                Text(
                  widget.searchMode && _searchQuery.trim().isNotEmpty
                      ? 'No products found for "${_searchQuery.trim()}"'
                      : 'No products found',
                ),
                const Spacer(),
              ],
            );
          }

          return Column(
            children: [
              if (widget.searchMode && dynamicSuggestions.isNotEmpty)
                _buildSuggestions(dynamicSuggestions),
              _buildFilters(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: provider.products[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((item) {
          return ActionChip(
            label: Text(item),
            onPressed: () async {
              _searchController.text = item;
              _searchQuery = item;
              await _loadProducts();
              await _saveSearch(item);
              if (!mounted) return;
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Row(
        children: [
          _chip(
            label: 'Newest',
            selected: _sort == 'newest',
            onTap: () {
              setState(() {
                _sort = 'newest';
              });
              _loadProducts();
            },
          ),
          _chip(
            label: 'Top Rated',
            selected: _sort == 'rating',
            onTap: () {
              setState(() {
                _sort = 'rating';
              });
              _loadProducts();
            },
          ),
          _chip(
            label: 'Price ↑',
            selected: _sort == 'price_asc',
            onTap: () {
              setState(() {
                _sort = 'price_asc';
              });
              _loadProducts();
            },
          ),
          _chip(
            label: 'Price ↓',
            selected: _sort == 'price_desc',
            onTap: () {
              setState(() {
                _sort = 'price_desc';
              });
              _loadProducts();
            },
          ),
          _chip(
            label: '4★+',
            selected: _selectedRating == 4,
            onTap: () {
              setState(() {
                _selectedRating = _selectedRating == 4 ? null : 4;
              });
              _loadProducts();
            },
          ),
          _chip(
            label: '<\$100',
            selected: _selectedMinPrice == null && _selectedMaxPrice == 100,
            onTap: () {
              setState(() {
                final selected = _selectedMinPrice == null && _selectedMaxPrice == 100;
                _selectedMinPrice = selected ? null : null;
                _selectedMaxPrice = selected ? null : 100;
              });
              _loadProducts();
            },
          ),
          _chip(
            label: '\$100-\$250',
            selected: _selectedMinPrice == 100 && _selectedMaxPrice == 250,
            onTap: () {
              setState(() {
                final selected = _selectedMinPrice == 100 && _selectedMaxPrice == 250;
                _selectedMinPrice = selected ? null : 100;
                _selectedMaxPrice = selected ? null : 250;
              });
              _loadProducts();
            },
          ),
          _chip(
            label: 'Clear',
            selected: false,
            onTap: () {
              setState(() {
                _sort = 'newest';
                _selectedRating = null;
                _selectedMinPrice = null;
                _selectedMaxPrice = null;
              });
              _loadProducts();
            },
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
