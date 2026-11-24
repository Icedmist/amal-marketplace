import 'package:amal_marketplace/state/cart_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps variants of the same product in separate lines', () async {
    final prefs = await SharedPreferences.getInstance();
    final cart = CartState(prefs);
    final product = buildProduct(stock: 5, colors: const ['Black']);

    cart.add(product, color: 'Black');
    cart.add(product, color: 'White');

    expect(cart.lines.length, 2);
    expect(cart.itemCount, 2);
  });

  test('caps quantity at the available stock', () async {
    final prefs = await SharedPreferences.getInstance();
    final cart = CartState(prefs);
    final product = buildProduct(stock: 3);

    cart.add(product, quantity: 2);
    expect(cart.itemCount, 2);

    cart.add(product, quantity: 5);
    expect(cart.itemCount, 3);

    final line = cart.lines.single;
    cart.setQuantity(line.key, 99);
    expect(line.quantity, 3);
  });

  test('removes a line when quantity reaches zero', () async {
    final prefs = await SharedPreferences.getInstance();
    final cart = CartState(prefs);
    cart.add(buildProduct());

    cart.setQuantity(cart.lines.single.key, 0);

    expect(cart.lines, isEmpty);
  });

  test('ignores out-of-stock products', () async {
    final prefs = await SharedPreferences.getInstance();
    final cart = CartState(prefs);

    cart.add(buildProduct(stock: 0));

    expect(cart.lines, isEmpty);
  });

  test('persists and restores variants', () async {
    final prefs = await SharedPreferences.getInstance();
    final cart = CartState(prefs);
    cart.add(
      buildProduct(colors: const ['Black'], sizes: const ['M']),
      color: 'Black',
      size: 'M',
    );
    await Future<void>.delayed(Duration.zero);

    final restored = CartState(prefs);

    expect(restored.lines.single.variantLabel, 'Black · M');
  });
}
