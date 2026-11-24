import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class WishlistState extends ChangeNotifier {
  WishlistState(this._prefs) {
    _restore();
  }

  final SharedPreferences _prefs;
  static const _key = 'amal_wishlist_v1';

  final Map<String, Product> _items = {};

  List<Product> get items => _items.values.toList(growable: false);

  int get count => _items.length;

  bool contains(String productId) => _items.containsKey(productId);

  void toggle(Product product) {
    if (_items.containsKey(product.id)) {
      _items.remove(product.id);
    } else {
      _items[product.id] = product;
    }
    _persist();
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    _persist();
    notifyListeners();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final product = Product.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        _items[product.id] = product;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final payload = jsonEncode(
      items
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'slug': p.slug,
              'image_url': p.imageUrl,
              'price': p.price,
              'sale_price': p.salePrice,
              'stock': p.stock,
              'brand': p.brand,
              'status': 'published',
            },
          )
          .toList(),
    );
    await _prefs.setString(_key, payload);
  }
}
