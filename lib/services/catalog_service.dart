import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/review.dart';

class CatalogService {
  CatalogService(this._client);

  final SupabaseClient _client;

  static const _productSelect =
      'id,name,slug,description,brand,sku,image_url,video_url,price,sale_price,stock,colors,sizes,specifications,status,rating,review_count,sold_count,category_id,subcategory_id,is_featured,is_trending,is_new_arrival,is_best_seller,is_flash_sale,is_daily_deal,flash_ends_at,weight_kg,created_at';

  Future<ProductPage> fetchProducts({
    String? query,
    String? categoryId,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool inStock = false,
    String sort = 'recommended',
    int page = 1,
    int limit = 24,
  }) async {
    // Filters stay on a PostgrestFilterBuilder; ordering / range hand over to a
    // PostgrestTransformBuilder, so they are applied on a separate expression.
    var builder = _client
        .from('products')
        .select(_productSelect)
        .eq('status', 'published');

    final q = _safeSearchTerm(query);
    if (q.isNotEmpty) {
      builder = builder.or(
        'name.ilike.%$q%,brand.ilike.%$q%,description.ilike.%$q%',
      );
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      builder = builder.eq('category_id', categoryId);
    }
    if (brand != null && brand.isNotEmpty) {
      builder = builder.eq('brand', brand);
    }
    if (minPrice != null) builder = builder.gte('price', minPrice);
    if (maxPrice != null) builder = builder.lte('price', maxPrice);
    if (minRating != null) builder = builder.gte('rating', minRating);
    if (inStock) builder = builder.gt('stock', 0);

    final ordered = switch (sort) {
      'newest' => builder.order('created_at', ascending: false),
      'price_asc' => builder.order('price'),
      'price_desc' => builder.order('price', ascending: false),
      'rating' => builder.order('rating', ascending: false),
      'popular' => builder.order('sold_count', ascending: false),
      _ =>
        builder
            .order('is_featured', ascending: false)
            .order('sold_count', ascending: false),
    };

    final from = (page - 1) * limit;
    final to = from + limit - 1;
    final response = await ordered
        .order('id')
        .range(from, to)
        .count(CountOption.exact);

    final items = (response.data as List<dynamic>)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();

    return ProductPage(items: items, count: response.count);
  }

  Future<List<Product>> fetchHomeFeed({int limit = 120}) async {
    final rows = await _client
        .from('products')
        .select(_productSelect)
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<CategoryItem>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select('*')
        .eq('is_active', true)
        .order('sort_order');

    return (rows as List<dynamic>)
        .map(
          (row) => CategoryItem.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<Product?> fetchProductBySlug(String slug) async {
    final row = await _client
        .from('products')
        .select(_productSelect)
        .eq('slug', slug)
        .maybeSingle();

    if (row == null) return null;
    return Product.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<Product>> fetchRelated({
    String? categoryId,
    String? excludeId,
  }) async {
    var builder = _client
        .from('products')
        .select(_productSelect)
        .eq('status', 'published');

    if (categoryId != null) builder = builder.eq('category_id', categoryId);
    if (excludeId != null) builder = builder.neq('id', excludeId);

    final rows = await builder.order('sold_count', ascending: false).limit(12);
    return (rows as List<dynamic>)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<ProductReview>> fetchReviews(
    String productId, {
    int limit = 20,
  }) async {
    final rows = await _client
        .from('reviews')
        .select(
          'id,product_id,rating,comment,author_name,photo_url,is_verified,created_at',
        )
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .map(
          (row) =>
              ProductReview.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  /// PostgREST filter grammar uses commas/parentheses/quotes as control
  /// characters. Neutralise them so a search like "phones, cases" cannot break
  /// the generated `or(...)` filter.
  static String _safeSearchTerm(String? value) {
    if (value == null) return '';
    return value
        .trim()
        .replaceAll(RegExp(r'''[,()"\\]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
