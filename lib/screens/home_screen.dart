import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_rail.dart';
import 'product_detail_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onBrowseAll});

  final VoidCallback? onBrowseAll;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final catalog = context.read<CatalogService>();
    final results = await Future.wait([
      catalog.fetchHomeFeed(),
      catalog.fetchCategories(),
    ]);
    return _HomeData(
      products: results[0] as List<Product>,
      categories: results[1] as List<CategoryItem>,
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(slug: product.slug),
      ),
    );
  }

  void _showDeliveryZones() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery & free zones',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Standard delivery is free in our Adamawa zones. Express delivery '
                'is available nationwide.',
                style: TextStyle(height: 1.45, color: AmalColors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AmalBrand.freeDeliveryZones
                    .map((zone) => Chip(label: Text(zone)))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const _DeliveryRow(label: 'Free zone — standard', value: 'Free'),
              const _DeliveryRow(label: 'Free zone — express', value: '₦1,000'),
              const _DeliveryRow(label: 'Adamawa — standard', value: '₦2,000'),
              const _DeliveryRow(label: 'Adamawa — express', value: '₦3,500'),
              const _DeliveryRow(
                label: 'Nationwide — standard',
                value: '₦5,000',
              ),
              const _DeliveryRow(
                label: 'Nationwide — express',
                value: '₦8,500',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    );
                  },
                  child: const Text('Start shopping'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = _load());
          await _future;
        },
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Could not load catalog'),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AmalColors.muted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _future = _load()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final featured = data.products
                .where((p) => p.isFeatured || p.isBestSeller)
                .take(12)
                .toList();
            final deals = data.products
                .where((p) => p.isFlashSale || p.isDailyDeal || p.hasDiscount)
                .take(12)
                .toList();
            final newest = data.products.take(12).toList();
            final topCategories = data.categories
                .where((c) => c.parentId == null)
                .take(12)
                .toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/brand/amal-icon.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(AmalBrand.name),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'WhatsApp support',
                      onPressed: () => launchUrl(
                        Uri.parse(AmalBrand.contacts.first.link),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.chat_outlined),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [AmalColors.navyDeep, AmalColors.navy],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shop smart in Jimeta & beyond',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AmalBrand.tagline,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeroChip(
                                label: 'Free delivery zones',
                                onTap: _showDeliveryZones,
                              ),
                              _HeroChip(
                                label: 'Browse all',
                                onTap:
                                    widget.onBrowseAll ??
                                    () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ShopScreen(),
                                        ),
                                      );
                                    },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (topCategories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 108,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: topCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final category = topCategories[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ShopScreen(
                                    initialCategoryId: category.id,
                                    initialCategoryName: category.name,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 108,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE8ECF3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _categoryGlyph(category.icon),
                                  const Spacer(),
                                  Text(
                                    category.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: ProductRail(
                    title: 'Flash deals',
                    products: deals,
                    onProductTap: _openProduct,
                    onSeeAll: widget.onBrowseAll,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ProductRail(
                    title: 'Featured',
                    products: featured.isEmpty ? newest : featured,
                    onProductTap: _openProduct,
                    onSeeAll: widget.onBrowseAll,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ProductRail(
                    title: 'New arrivals',
                    products: newest,
                    onProductTap: _openProduct,
                    onSeeAll: widget.onBrowseAll,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  const _HomeData({required this.products, required this.categories});

  final List<Product> products;
  final List<CategoryItem> categories;
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AmalColors.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

const _categoryIcons = <String, IconData>{
  'Armchair': Icons.chair_outlined,
  'Baby': Icons.child_care,
  'BookOpen': Icons.menu_book_outlined,
  'CookingPot': Icons.soup_kitchen_outlined,
  'Dumbbell': Icons.fitness_center,
  'Footprints': Icons.directions_walk,
  'Gamepad2': Icons.sports_esports_outlined,
  'Headphones': Icons.headphones,
  'Laptop': Icons.laptop_mac,
  'Moon': Icons.nightlight_outlined,
  'Package': Icons.inventory_2_outlined,
  'Refrigerator': Icons.kitchen_outlined,
  'Shirt': Icons.checkroom,
  'ShoppingBag': Icons.shopping_bag_outlined,
  'Smartphone': Icons.smartphone,
  'Sparkles': Icons.auto_awesome,
  'SprayCan': Icons.spa_outlined,
  'Tv': Icons.tv,
  'Watch': Icons.watch_outlined,
};

Widget _categoryGlyph(String? icon) {
  final mapped = _categoryIcons[icon?.trim()];
  if (mapped != null) {
    return Icon(mapped, size: 22, color: AmalColors.navy);
  }
  final raw = icon?.trim() ?? '';
  final isEmoji = raw.isNotEmpty && !RegExp(r'^[A-Za-z0-9 _-]+$').hasMatch(raw);
  if (isEmoji) {
    return Text(raw, style: const TextStyle(fontSize: 20));
  }
  return const Icon(
    Icons.storefront_outlined,
    size: 22,
    color: AmalColors.navy,
  );
}
