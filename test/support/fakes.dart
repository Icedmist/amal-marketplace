import 'package:amal_marketplace/models/product.dart';
import 'package:amal_marketplace/models/review.dart';
import 'package:amal_marketplace/services/catalog_service.dart';

Product buildProduct({
  String id = 'p1',
  String name = 'Test phone',
  String slug = 'test-phone',
  String? imageUrl,
  double price = 1000,
  double? salePrice,
  int stock = 5,
  List<String> colors = const [],
  List<String> sizes = const [],
  Map<String, dynamic>? specifications,
  String? categoryId,
  bool isFeatured = false,
  bool isBestSeller = false,
  bool isFlashSale = false,
  DateTime? flashEndsAt,
}) {
  return Product(
    id: id,
    name: name,
    slug: slug,
    imageUrl: imageUrl,
    price: price,
    salePrice: salePrice,
    stock: stock,
    colors: colors,
    sizes: sizes,
    specifications: specifications,
    categoryId: categoryId,
    isFeatured: isFeatured,
    isBestSeller: isBestSeller,
    isFlashSale: isFlashSale,
    flashEndsAt: flashEndsAt,
  );
}

class FakeCatalogService implements CatalogService {
  FakeCatalogService({
    List<Product>? products,
    List<CategoryItem>? categories,
    List<ProductReview>? reviews,
  }) : _products = products ?? [buildProduct()],
       _categories = categories ?? const [],
       _reviews = reviews ?? const [];

  final List<Product> _products;
  final List<CategoryItem> _categories;
  final List<ProductReview> _reviews;

  @override
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
    var items = _products;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      items = items
          .where(
            (product) =>
                product.name.toLowerCase().contains(q) ||
                (product.brand ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    if (categoryId != null) {
      items = items.where((p) => p.categoryId == categoryId).toList();
    }
    if (inStock) items = items.where((p) => p.inStock).toList();
    final start = (page - 1) * limit;
    if (start >= items.length) {
      return ProductPage(items: const [], count: items.length);
    }
    final end = (start + limit).clamp(0, items.length);
    return ProductPage(items: items.sublist(start, end), count: items.length);
  }

  @override
  Future<List<Product>> fetchHomeFeed({int limit = 120}) async {
    return _products.take(limit).toList();
  }

  @override
  Future<List<CategoryItem>> fetchCategories() async => _categories;

  @override
  Future<Product?> fetchProductBySlug(String slug) async {
    for (final product in _products) {
      if (product.slug == slug) return product;
    }
    return null;
  }

  @override
  Future<List<Product>> fetchRelated({
    String? categoryId,
    String? excludeId,
  }) async {
    return _products
        .where((p) => p.id != excludeId && p.categoryId == categoryId)
        .toList();
  }

  @override
  Future<List<ProductReview>> fetchReviews(
    String productId, {
    int limit = 20,
  }) async {
    return _reviews.where((r) => r.productId == productId).take(limit).toList();
  }
}
