class Product {
  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.brand,
    this.sku,
    this.imageUrl,
    this.videoUrl,
    required this.price,
    this.salePrice,
    required this.stock,
    this.colors = const [],
    this.sizes = const [],
    this.specifications,
    this.status = 'published',
    this.rating = 0,
    this.reviewCount = 0,
    this.soldCount = 0,
    this.categoryId,
    this.subcategoryId,
    this.isFeatured = false,
    this.isTrending = false,
    this.isNewArrival = false,
    this.isBestSeller = false,
    this.isFlashSale = false,
    this.isDailyDeal = false,
    this.flashEndsAt,
    this.weightKg,
    this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? brand;
  final String? sku;
  final String? imageUrl;
  final String? videoUrl;
  final double price;
  final double? salePrice;
  final int stock;
  final List<String> colors;
  final List<String> sizes;
  final Map<String, dynamic>? specifications;
  final String status;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final String? categoryId;
  final String? subcategoryId;
  final bool isFeatured;
  final bool isTrending;
  final bool isNewArrival;
  final bool isBestSeller;
  final bool isFlashSale;
  final bool isDailyDeal;
  final DateTime? flashEndsAt;
  final double? weightKg;
  final DateTime? createdAt;

  bool get inStock => stock > 0;

  double get effectivePrice => salePrice ?? price;

  bool get hasDiscount => salePrice != null && salePrice! < price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((price - salePrice!) / price) * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return Product(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Untitled',
      slug: (json['slug'] as String?) ?? (json['id'] as String),
      description: json['description'] as String?,
      brand: json['brand'] as String?,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      colors: asStringList(json['colors']),
      sizes: asStringList(json['sizes']),
      specifications: json['specifications'] is Map<String, dynamic>
          ? json['specifications'] as Map<String, dynamic>
          : null,
      status: (json['status'] as String?) ?? 'published',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
      categoryId: json['category_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      isFeatured: json['is_featured'] == true,
      isTrending: json['is_trending'] == true,
      isNewArrival: json['is_new_arrival'] == true,
      isBestSeller: json['is_best_seller'] == true,
      isFlashSale: json['is_flash_sale'] == true,
      isDailyDeal: json['is_daily_deal'] == true,
      flashEndsAt: json['flash_ends_at'] != null
          ? DateTime.tryParse(json['flash_ends_at'].toString())
          : null,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.imageUrl,
    this.parentId,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? imageUrl;
  final String? parentId;
  final int sortOrder;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Category',
      slug: (json['slug'] as String?) ?? '',
      icon: json['icon'] as String?,
      imageUrl: json['image_url'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductPage {
  const ProductPage({required this.items, required this.count});

  final List<Product> items;
  final int count;
}
