import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

final _naira = NumberFormat.currency(
  locale: 'en_NG',
  symbol: '₦',
  decimalDigits: 0,
);

String formatNaira(num amount) => _naira.format(amount);

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.struck = false,
    this.color,
  });

  final num amount;
  final TextStyle? style;
  final bool struck;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleMedium;
    return Text(
      formatNaira(amount),
      style: (base ?? const TextStyle()).copyWith(
        color: color ?? (struck ? AmalColors.muted : AmalColors.ink),
        decoration: struck ? TextDecoration.lineThrough : null,
        fontWeight: struck ? FontWeight.w500 : FontWeight.w800,
      ),
    );
  }
}
