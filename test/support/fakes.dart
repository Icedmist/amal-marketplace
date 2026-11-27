import 'package:amal_marketplace/models/order.dart';
import 'package:amal_marketplace/models/product.dart';
import 'package:amal_marketplace/models/review.dart';
import 'package:amal_marketplace/services/catalog_service.dart';
import 'package:amal_marketplace/services/order_api.dart';
import 'package:amal_marketplace/state/auth_state.dart';

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

class FakeAuthController extends AuthController {
  FakeAuthController({
    bool signedIn = false,
    String? name,
    String? email,
  }) : _userId = signedIn ? 'user-1' : null,
       _name = name ?? (signedIn ? 'Test Buyer' : null),
       _email = email ?? (signedIn ? 'buyer@example.com' : null);

  String? _userId;
  String? _name;
  String? _email;

  @override
  String? get userId => _userId;

  @override
  String? get email => _email;

  @override
  String? get displayName => _name;

  @override
  String? get phone => _userId == null ? null : '08012345678';

  @override
  Future<void> signIn({required String email, required String password}) async {
    _userId = 'user-1';
    _email = email;
    notifyListeners();
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _userId = 'user-1';
    _email = email;
    _name = fullName;
    notifyListeners();
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    _name = fullName;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    notifyListeners();
  }
}

class FakeOrderApi implements OrderApi {
  FakeOrderApi({this.paymentStatus = 'pending'});

  final String paymentStatus;
  PlaceOrderRequest? lastRequest;

  @override
  Future<PlacedOrder> placeOrder(PlaceOrderRequest request) async {
    lastRequest = request;
    const subtotal = 0.0;
    return PlacedOrder(
      reference: 'AMAL-TEST-1',
      subtotal: subtotal,
      discount: 0,
      deliveryFee: 0,
      total: subtotal,
      lines: request.items
          .map(
            (item) => PlacedOrderLine(
              name: item.productId,
              quantity: item.quantity,
              unitPrice: 0,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<List<OrderSummary>> listOrders() async => const [];

  @override
  Future<OrderDetail> fetchOrder(String reference) async {
    return OrderDetail(
      id: 'order-1',
      reference: reference,
      customerName: 'Test Buyer',
      customerPhone: '08012345678',
      customerEmail: 'buyer@example.com',
      deliveryAddress: '1 Test Street',
      deliveryCity: 'Jimeta',
      deliveryState: 'Adamawa',
      deliveryMethod: 'standard',
      deliveryFee: 0,
      deliveryNote: null,
      estimatedDelivery: '2 - 5 business days',
      subtotal: 1000,
      discount: 0,
      couponCode: null,
      total: 1000,
      status: 'pending',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: paymentStatus,
      createdAt: DateTime(2026, 1, 1),
      items: const [
        OrderLine(productName: 'Test phone', quantity: 1, unitPrice: 1000),
      ],
    );
  }

  @override
  Future<String?> startPaystack(String reference) async => null;

  @override
  Future<String> confirmPaystack(String reference) async => paymentStatus;
}
