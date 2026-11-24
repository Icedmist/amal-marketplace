import 'package:amal_marketplace/models/product.dart';
import 'package:amal_marketplace/screens/about_screen.dart';
import 'package:amal_marketplace/screens/checkout_screen.dart';
import 'package:amal_marketplace/screens/product_detail_screen.dart';
import 'package:amal_marketplace/screens/shell_screen.dart';
import 'package:amal_marketplace/screens/welcome_screen.dart';
import 'package:amal_marketplace/services/catalog_service.dart';
import 'package:amal_marketplace/state/cart_state.dart';
import 'package:amal_marketplace/state/wishlist_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap(
    Widget child, {
    required CatalogService service,
    CartState? cart,
    WishlistState? wishlist,
  }) {
    return MultiProvider(
      providers: [
        Provider<CatalogService>.value(value: service),
        ChangeNotifierProvider<CartState>.value(
          value: cart ?? CartState(prefs),
        ),
        ChangeNotifierProvider<WishlistState>.value(
          value: wishlist ?? WishlistState(prefs),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('welcome screen offers shopping and the web shop', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: const WelcomeScreen()));

    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Visit web shop'), findsOneWidget);
  });

  testWidgets('about screen reflects the WhatsApp checkout', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    expect(find.text('Verified checkout'), findsOneWidget);
    expect(find.text('Free delivery zones'), findsNothing);
  });

  testWidgets('shell tabs load home, shop, wishlist, cart and account', (
    tester,
  ) async {
    final service = FakeCatalogService(
      products: [buildProduct(name: 'Shell product')],
      categories: const [
        CategoryItem(
          id: 'c1',
          name: 'Phones',
          slug: 'phones',
          icon: 'Smartphone',
        ),
      ],
    );

    await tester.pumpWidget(wrap(const ShellScreen(), service: service));
    await tester.pumpAndSettle();

    expect(find.text('Phones'), findsOneWidget);
    expect(find.text('Shell product'), findsWidgets);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(find.text('1 products · prices in ₦'), findsOneWidget);

    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();
    expect(find.text('No saved items yet'), findsOneWidget);

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Email support'), findsOneWidget);
  });

  testWidgets('product detail requires variants and adds to the cart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final product = buildProduct(
      stock: 4,
      colors: const ['Black', 'White'],
      sizes: const ['M'],
      specifications: const {'Material': 'Cotton'},
    );
    final service = FakeCatalogService(products: [product]);
    final cart = CartState(prefs);

    await tester.pumpWidget(
      wrap(
        ProductDetailScreen(slug: product.slug, preview: product),
        service: service,
        cart: cart,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to cart'));
    await tester.pump();
    expect(find.text('Choose a color first.'), findsOneWidget);
    expect(cart.lines, isEmpty);

    await tester.scrollUntilVisible(
      find.text('Black'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Black'));
    await tester.tap(find.text('M'));
    await tester.pump();

    await tester.tap(find.text('Add to cart'));
    await tester.pump();

    expect(cart.lines.single.color, 'Black');
    expect(cart.lines.single.size, 'M');
    expect(cart.itemCount, 1);

    await tester.scrollUntilVisible(
      find.text('Specifications'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cotton'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('No written reviews yet.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No written reviews yet.'), findsOneWidget);
  });

  testWidgets('checkout totals delivery and validates customer details', (
    tester,
  ) async {
    final product = buildProduct(price: 1000, salePrice: 900, stock: 10);
    final cart = CartState(prefs)..add(product, quantity: 2);

    await tester.pumpWidget(
      wrap(
        const CheckoutScreen(),
        service: FakeCatalogService(products: [product]),
        cart: cart,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('3,800'), findsOneWidget);

    final submit = find.text('Place order on WhatsApp');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(cart.itemCount, 2);
  });
}
