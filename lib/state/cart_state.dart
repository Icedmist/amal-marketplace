import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class CartLine {
  CartLine({required this.product, this.quantity = 1, this.color, this.size});

  final Product product;
  int quantity;
  final String? color;
  final String? size;

  /// Two lines of the same product with different variants stay separate.
  String get key => '${product.id}|${color ?? ''}|${size ?? ''}';

  String get variantLabel => [
    color,
    size,
  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

  int get maxQuantity => product.inStock ? product.stock : 0;

  double get lineTotal => product.effectivePrice * quantity;

  Map<String, dynamic> toJson() => {
    'product': {
      'id': product.id,
      'name': product.name,
      'slug': product.slug,
      'image_url': product.imageUrl,
      'price': product.price,
      'sale_price': product.salePrice,
      'stock': product.stock,
      'brand': product.brand,
    },
    'quantity': quantity,
    'color': color,
    'size': size,
  };

  factory CartLine.fromJson(Map<String, dynamic> json) {
    final productJson = Map<String, dynamic>.from(json['product'] as Map);
    return CartLine(
      product: Product.fromJson({
        ...productJson,
        'status': 'published',
        'rating': 0,
        'review_count': 0,
        'sold_count': 0,
      }),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      color: json['color'] as String?,
      size: json['size'] as String?,
    );
  }
}

class CartState extends ChangeNotifier {
  CartState(this._prefs) {
    _restore();
  }

  final SharedPreferences _prefs;
  static const _key = 'amal_cart_v1';

  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList(growable: false);

  int get itemCount =>
      _lines.values.fold<int>(0, (sum, line) => sum + line.quantity);

  double get subtotal =>
      _lines.values.fold<double>(0, (sum, line) => sum + line.lineTotal);

  /// Adds a product, respecting available stock and keeping variants apart.
  void add(Product product, {int quantity = 1, String? color, String? size}) {
    if (!product.inStock || quantity <= 0) return;
    final line = CartLine(product: product, color: color, size: size);
    final existing = _lines[line.key];
    if (existing != null) {
      existing.quantity = math.min(
        existing.maxQuantity,
        existing.quantity + quantity,
      );
    } else {
      line.quantity = math.min(product.stock, quantity);
      _lines[line.key] = line;
    }
    _persist();
    notifyListeners();
  }

  void setQuantity(String lineKey, int quantity) {
    final line = _lines[lineKey];
    if (line == null) return;
    if (quantity <= 0) {
      _lines.remove(lineKey);
    } else {
      final capped = line.maxQuantity > 0
          ? math.min(quantity, line.maxQuantity)
          : quantity;
      line.quantity = capped;
    }
    _persist();
    notifyListeners();
  }

  void remove(String lineKey) {
    _lines.remove(lineKey);
    _persist();
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _persist();
    notifyListeners();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final line = CartLine.fromJson(Map<String, dynamic>.from(item as Map));
        _lines[line.key] = line;
      }
    } catch (_) {
      // Ignore corrupt cache.
    }
  }

  Future<void> _persist() async {
    final payload = jsonEncode(lines.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, payload);
  }
}
