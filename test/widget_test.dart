import 'package:flutter_test/flutter_test.dart';

import 'package:amal_marketplace/config/brand.dart';
import 'package:amal_marketplace/widgets/money_text.dart';

void main() {
  test('formats naira without decimals for whole amounts', () {
    expect(formatNaira(1500), contains('1,500'));
    expect(formatNaira(1500), contains('₦'));
  });

  test('delivery fee is free in Jimeta for standard delivery', () {
    final fee = AmalBrand.deliveryFee(
      method: 'standard',
      state: 'Adamawa',
      city: 'Jimeta',
    );
    expect(fee, 0);
  });

  test('express delivery outside Adamawa uses nationwide rate', () {
    final fee = AmalBrand.deliveryFee(
      method: 'express',
      state: 'Lagos',
      city: 'Ikeja',
    );
    expect(fee, 8500);
  });
}
