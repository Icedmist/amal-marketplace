import 'package:amal_marketplace/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the catalog payload used by the app', () {
    final product = Product.fromJson({
      'id': 'p1',
      'name': 'Wireless earbuds',
      'slug': 'wireless-earbuds',
      'brand': 'AMAL',
      'image_url': 'https://example.com/a.webp',
      'price': 10000,
      'sale_price': 8000,
      'stock': 4,
      'colors': ['Teal'],
      'sizes': ['One size'],
      'specifications': {'Battery': '6 hours'},
      'status': 'published',
      'rating': 4.5,
      'review_count': 12,
      'sold_count': 30,
      'is_featured': true,
      'is_flash_sale': true,
      'flash_ends_at': '2026-12-01T10:00:00Z',
    });

    expect(product.inStock, isTrue);
    expect(product.hasDiscount, isTrue);
    expect(product.effectivePrice, 8000);
    expect(product.discountPercent, 20);
    expect(product.colors, ['Teal']);
    expect(product.rating, 4.5);
    expect(product.isFeatured, isTrue);
    expect(product.isFlashSale, isTrue);
    expect(product.flashEndsAt, isNotNull);
  });

  test('missing optional fields fall back safely', () {
    final product = Product.fromJson({
      'id': 'p2',
      'name': 'Basic item',
      'price': 500,
      'stock': 0,
    });

    expect(product.slug, 'p2');
    expect(product.hasDiscount, isFalse);
    expect(product.inStock, isFalse);
    expect(product.colors, isEmpty);
    expect(product.specifications, isNull);
  });
}
