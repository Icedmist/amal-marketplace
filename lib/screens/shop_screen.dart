import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/catalog_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  final String? initialCategoryId;
  final String? initialCategoryName;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _pageSize = 24;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  String _sort = 'recommended';
  String? _categoryId;
  String? _categoryName;
  List<CategoryItem> _categories = const [];

  final List<Product> _items = [];
  int _total = 0;
  int _nextPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;
  int _requestId = 0;

  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  bool _inStockOnly = false;

  int get _activeFilterCount =>
      (_minPrice != null ? 1 : 0) +
      (_maxPrice != null ? 1 : 0) +
      (_minRating != null ? 1 : 0) +
      (_inStockOnly ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _categoryName = widget.initialCategoryName;
    _scrollController.addListener(_onScroll);
    _reload();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await context.read<CatalogService>().fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats.where((c) => c.parentId == null).toList();
      });
    } catch (_) {
      // Categories are optional; the product grid still works.
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _error = null;
      _items.clear();
      _total = 0;
      _nextPage = 1;
    });
    await _fetchPage(reset: true, requestId: requestId);
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _fetchPage(reset: false, requestId: _requestId);
  }

  Future<void> _fetchPage({required bool reset, required int requestId}) async {
    try {
      final page = await context.read<CatalogService>().fetchProducts(
        query: _searchController.text.trim(),
        categoryId: _categoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        inStock: _inStockOnly,
        sort: _sort,
        page: _nextPage,
        limit: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _total = page.count;
        _nextPage++;
        _hasMore = _items.length < _total && page.items.length == _pageSize;
        _error = null;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _error = error);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _reload);
  }

  void _selectCategory(CategoryItem? category) {
    setState(() {
      _categoryId = category?.id;
      _categoryName = category?.name;
    });
    _reload();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_ShopFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(
        initial: _ShopFilters(
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          minRating: _minRating,
          inStock: _inStockOnly,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _minPrice = result.minPrice;
      _maxPrice = result.maxPrice;
      _minRating = result.minRating;
      _inStockOnly = result.inStock;
    });
    _reload();
  }

  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _inStockOnly = false;
    });
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_categoryName ?? 'All products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                _debounce?.cancel();
                _reload();
              },
              decoration: InputDecoration(
                hintText: 'Search phones, fashion, groceries…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _reload();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () {
                        _debounce?.cancel();
                        _reload();
                      },
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _categoryId == null,
                    onSelected: (_) => _selectCategory(null),
                  ),
                ),
                ..._categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: _categoryId == category.id,
                      onSelected: (_) => _selectCategory(category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                const Text(
                  'Sort',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AmalColors.muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'recommended',
                        child: Text('Recommended'),
                      ),
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Newest first'),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Price: low to high'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Price: high to low'),
                      ),
                      DropdownMenuItem(
                        value: 'rating',
                        child: Text('Top rated'),
                      ),
                      DropdownMenuItem(
                        value: 'popular',
                        child: Text('Best selling'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sort = value);
                      _reload();
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                  icon: Badge(
                    isLabelVisible: _activeFilterCount > 0,
                    label: Text('$_activeFilterCount'),
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Shop unavailable',
        message: '$_error',
        actionLabel: 'Retry',
        onAction: _reload,
      );
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: '0 products found',
        message: _activeFilterCount > 0
            ? 'Try clearing the filters or using another search.'
            : 'Try another search or clear category filters.',
        actionLabel: _activeFilterCount > 0 ? 'Clear filters' : null,
        onAction: _activeFilterCount > 0 ? _clearFilters : null,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$_total products · prices in ₦',
              style: const TextStyle(color: AmalColors.muted),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: _items.length + (_hasMore || _loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return Center(
                    child: _error != null
                        ? TextButton(
                            onPressed: _loadMore,
                            child: const Text('Retry loading more'),
                          )
                        : const CircularProgressIndicator(),
                  );
                }
                final product = _items[index];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                  ),
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            slug: product.slug,
                            preview: product,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopFilters {
  const _ShopFilters({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStock = false,
  });

  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool inStock;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final _ShopFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late double? _minRating;
  late bool _inStock;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.initial.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '',
    );
    _minRating = widget.initial.minRating;
    _inStock = widget.initial.inStock;
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final min = _parsePrice(_minController.text);
    final max = _parsePrice(_maxController.text);
    if (min != null && max != null && min > max) {
      setState(() => _errorText = 'Minimum price cannot be above maximum.');
      return;
    }
    Navigator.of(context).pop(
      _ShopFilters(
        minPrice: min,
        maxPrice: max,
        minRating: _minRating,
        inStock: _inStock,
      ),
    );
  }

  void _reset() {
    _minController.clear();
    _maxController.clear();
    setState(() {
      _minRating = null;
      _inStock = false;
      _errorText = null;
    });
  }

  static double? _parsePrice(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter products',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min price (₦)',
                    prefixText: '₦ ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max price (₦)',
                    prefixText: '₦ ',
                  ),
                ),
              ),
            ],
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: const TextStyle(color: AmalColors.danger)),
          ],
          const SizedBox(height: 14),
          DropdownButtonFormField<double>(
            initialValue: _minRating,
            decoration: const InputDecoration(labelText: 'Minimum rating'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any rating')),
              DropdownMenuItem(value: 3, child: Text('3 stars & up')),
              DropdownMenuItem(value: 4, child: Text('4 stars & up')),
              DropdownMenuItem(value: 4.5, child: Text('4.5 stars & up')),
            ],
            onChanged: (value) => setState(() => _minRating = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('In stock only'),
            value: _inStock,
            onChanged: (value) => setState(() => _inStock = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: _reset, child: const Text('Reset')),
              const Spacer(),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
