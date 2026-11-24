import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../services/catalog_service.dart';
import '../state/cart_state.dart';
import '../state/wishlist_state.dart';
import '../theme/app_theme.dart';
import '../widgets/money_text.dart';
import '../widgets/product_rail.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.slug, this.preview});

  final String slug;
  final Product? preview;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product?> _future;
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Product?> _load() {
    return context.read<CatalogService>().fetchProductBySlug(widget.slug);
  }

  void _retry() {
    setState(() => _future = _load());
  }

  void _addToCart(Product product) {
    if (product.colors.isNotEmpty && _selectedColor == null) {
      _showMessage('Choose a color first.');
      return;
    }
    if (product.sizes.isNotEmpty && _selectedSize == null) {
      _showMessage('Choose a size first.');
      return;
    }
    context.read<CartState>().add(
      product,
      quantity: _quantity,
      color: _selectedColor,
      size: _selectedSize,
    );
    _showMessage('Added to cart');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openRelated(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(slug: product.slug, preview: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _future,
      builder: (context, snapshot) {
        final product = snapshot.data ?? widget.preview;
        if (product == null &&
            snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load this product'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final wishlist = context.watch<WishlistState>();
        final wished = wishlist.contains(product.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name, maxLines: 1),
            actions: [
              IconButton(
                onPressed: () => wishlist.toggle(product),
                icon: Icon(
                  wished ? Icons.favorite : Icons.favorite_border,
                  color: wished ? AmalColors.danger : null,
                ),
              ),
            ],
          ),
          body: ListView(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl == null
                    ? Container(color: AmalColors.cream)
                    : CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AmalColors.cream),
                        errorWidget: (_, _, _) => Container(
                          color: AmalColors.cream,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AmalColors.muted,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(
                        product.brand!,
                        style: const TextStyle(
                          color: AmalColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        MoneyText(
                          product.effectivePrice,
                          style: const TextStyle(fontSize: 24),
                          color: AmalColors.navy,
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 10),
                          MoneyText(product.price, struck: true),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AmalColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '-${product.discountPercent}%',
                              style: const TextStyle(
                                color: AmalColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.inventory_2_outlined,
                          label: product.inStock
                              ? '${product.stock} in stock'
                              : 'Out of stock',
                        ),
                        if (product.rating > 0)
                          _InfoChip(
                            icon: Icons.star_rounded,
                            label:
                                '${product.rating.toStringAsFixed(1)} · ${product.reviewCount} reviews',
                          ),
                        if (product.soldCount > 0)
                          _InfoChip(
                            icon: Icons.local_fire_department_outlined,
                            label: '${product.soldCount} sold',
                          ),
                      ],
                    ),
                    if (product.isFlashSale &&
                        product.flashEndsAt != null &&
                        product.flashEndsAt!.isAfter(DateTime.now())) ...[
                      const SizedBox(height: 14),
                      _FlashCountdown(endsAt: product.flashEndsAt!),
                    ],
                    if (product.colors.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const _SectionTitle('Color'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.colors
                            .map(
                              (color) => ChoiceChip(
                                label: Text(color),
                                selected: _selectedColor == color,
                                onSelected: (_) =>
                                    setState(() => _selectedColor = color),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (product.sizes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const _SectionTitle('Size'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.sizes
                            .map(
                              (size) => ChoiceChip(
                                label: Text(size),
                                selected: _selectedSize == size,
                                onSelected: (_) =>
                                    setState(() => _selectedSize = size),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (product.inStock) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const _SectionTitle('Quantity'),
                          const Spacer(),
                          _QuantityStepper(
                            value: _quantity,
                            max: product.stock,
                            onChanged: (value) =>
                                setState(() => _quantity = value),
                          ),
                        ],
                      ),
                    ],
                    if (product.description != null &&
                        product.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const _SectionTitle('Description'),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: const TextStyle(
                          height: 1.55,
                          color: AmalColors.ink,
                        ),
                      ),
                    ],
                    if (product.videoUrl != null &&
                        product.videoUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(product.videoUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Watch product video'),
                      ),
                    ],
                    if (product.specifications != null &&
                        product.specifications!.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const _SectionTitle('Specifications'),
                      const SizedBox(height: 8),
                      _Specifications(values: product.specifications!),
                    ],
                    const SizedBox(height: 22),
                    _ReviewsSection(
                      productId: product.id,
                      rating: product.rating,
                      reviewCount: product.reviewCount,
                    ),
                    _RelatedProducts(
                      categoryId: product.categoryId,
                      excludeId: product.id,
                      onProductTap: _openRelated,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final variant = [
                          if (_selectedColor != null) 'Color: $_selectedColor',
                          if (_selectedSize != null) 'Size: $_selectedSize',
                        ].join(', ');
                        final message =
                            'Hi AMAL, I want to order: ${product.name}'
                            '${variant.isEmpty ? '' : ' ($variant)'} '
                            'x$_quantity (${formatNaira(product.effectivePrice * _quantity)})';
                        launchUrl(
                          Uri.parse(AmalBrand.whatsappOrderUrl(message)),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !product.inStock
                          ? null
                          : () => _addToCart(product),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AmalColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AmalColors.navy),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E6EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value <= 1 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Specifications extends StatelessWidget {
  const _Specifications({required this.values});

  final Map<String, dynamic> values;

  static String _label(String key) {
    final spaced = key.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return key;
    return spaced
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static String _value(dynamic value) {
    if (value == null) return '—';
    if (value is List) {
      return value.map((item) => item.toString()).join(', ');
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${_label(entry.key.toString())}: ${entry.value}')
          .join(', ');
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final entries = values.entries
        .where((entry) => _value(entry.value).trim().isNotEmpty)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      _label(entries[i].key),
                      style: const TextStyle(color: AmalColors.muted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _value(entries[i].value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (i != entries.length - 1)
              const Divider(height: 1, color: Color(0xFFEEF1F6)),
          ],
        ],
      ),
    );
  }
}

class _FlashCountdown extends StatefulWidget {
  const _FlashCountdown({required this.endsAt});

  final DateTime endsAt;

  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endsAt.difference(DateTime.now());
    final ended = remaining.isNegative;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AmalColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AmalColors.danger),
          const SizedBox(width: 8),
          Text(
            ended
                ? 'Flash sale ended'
                : 'Flash sale ends in '
                      '${hours.toString().padLeft(2, '0')}:'
                      '${minutes.toString().padLeft(2, '0')}:'
                      '${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AmalColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({
    required this.productId,
    required this.rating,
    required this.reviewCount,
  });

  final String productId;
  final double rating;
  final int reviewCount;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  late Future<List<ProductReview>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<CatalogService>().fetchReviews(widget.productId);
  }

  @override
  void didUpdateWidget(covariant _ReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _future = context.read<CatalogService>().fetchReviews(widget.productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductReview>>(
      future: _future,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <ProductReview>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SectionTitle('Reviews'),
                const SizedBox(width: 8),
                if (widget.reviewCount > 0)
                  Text(
                    '(${widget.reviewCount})',
                    style: const TextStyle(color: AmalColors.muted),
                  ),
              ],
            ),
            if (widget.rating > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _StarRow(rating: widget.rating),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.rating.toStringAsFixed(1)} out of 5',
                    style: const TextStyle(color: AmalColors.muted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            if (snapshot.connectionState != ConnectionState.done &&
                reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (snapshot.hasError)
              const Text(
                'Reviews are unavailable right now.',
                style: TextStyle(color: AmalColors.muted),
              )
            else if (reviews.isEmpty)
              const Text(
                'No written reviews yet.',
                style: TextStyle(color: AmalColors.muted),
              )
            else
              Column(
                children: reviews
                    .take(5)
                    .map((review) => _ReviewTile(review: review))
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = rating >= index + 1;
        final half = !filled && rating > index + 0.25;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_border_rounded,
          size: size,
          color: AmalColors.gold,
        );
      }),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final createdAt = review.createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName?.trim().isNotEmpty == true
                      ? review.authorName!
                      : 'AMAL customer',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (review.isVerified)
                const Icon(Icons.verified, size: 16, color: AmalColors.success),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _StarRow(rating: review.rating, size: 14),
              if (createdAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().format(createdAt),
                  style: const TextStyle(color: AmalColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!, style: const TextStyle(height: 1.45)),
          ],
        ],
      ),
    );
  }
}

class _RelatedProducts extends StatefulWidget {
  const _RelatedProducts({
    required this.categoryId,
    required this.excludeId,
    required this.onProductTap,
  });

  final String? categoryId;
  final String excludeId;
  final ValueChanged<Product> onProductTap;

  @override
  State<_RelatedProducts> createState() => _RelatedProductsState();
}

class _RelatedProductsState extends State<_RelatedProducts> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _RelatedProducts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.excludeId != widget.excludeId) {
      _future = _load();
    }
  }

  Future<List<Product>> _load() {
    return context.read<CatalogService>().fetchRelated(
      categoryId: widget.categoryId,
      excludeId: widget.excludeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Product>[];
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ProductRail(
            title: 'You may also like',
            products: products,
            onProductTap: widget.onProductTap,
          ),
        );
      },
    );
  }
}
