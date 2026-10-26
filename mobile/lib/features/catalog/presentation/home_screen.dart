import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../auth/presentation/auth_screens.dart' show JemisLogo;
import 'address_sheet.dart';

IconData categoryIcon(String? key) => switch (key) {
      'fruits' => Icons.apple,
      'vegetables' => Icons.eco_outlined,
      'dairy' => Icons.egg_alt_outlined,
      'meat' => Icons.set_meal_outlined,
      'fish' => Icons.phishing_outlined,
      'bakery' => Icons.bakery_dining_outlined,
      'drinks' => Icons.local_drink_outlined,
      'snacks' => Icons.cookie_outlined,
      'frozen' => Icons.ac_unit,
      'pantry' => Icons.grain,
      'household' => Icons.cleaning_services_outlined,
      'baby' => Icons.child_care,
      _ => Icons.category_outlined,
    };

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final feed = ref.watch(homeProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeProvider);
            await ref.read(homeProvider.future);
          },
          child: CustomScrollView(slivers: [
            const SliverToBoxAdapter(child: _Header()),
            ...feed.when(
              loading: () => [const SliverToBoxAdapter(child: _HomeSkeleton())],
              error: (e, _) => [SliverFillRemaining(hasScrollBody: false, child: ErrorView(error: e, onRetry: () => ref.invalidate(homeProvider)))],
              data: (f) => [
                if (f.banners.isNotEmpty) SliverToBoxAdapter(child: _Banners(banners: f.banners)),
                SliverToBoxAdapter(child: _SectionTitle(l.categories)),
                SliverToBoxAdapter(child: _Categories(categories: f.categories)),
                ..._section(context, ref, l.popular, f.popular, 'popularity', false),
                ..._section(context, ref, l.discounted, f.discounted, 'popularity', true),
                ..._section(context, ref, l.freshArrivals, f.fresh, 'newest', false),
                SliverToBoxAdapter(
                  child: Consumer(builder: (context, ref, _) {
                    final freq = ref.watch(frequentProvider).value ?? const <Product>[];
                    if (freq.isEmpty) return const SizedBox.shrink();
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _SectionTitle(l.frequentlyBought),
                      _ProductRow(products: freq),
                    ]);
                  }),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _section(BuildContext context, WidgetRef ref, String title, List<Product> items, String sort, bool discounted) {
    if (items.isEmpty) return const [];
    return [
      SliverToBoxAdapter(child: _SectionTitle(title, onSeeAll: () => context.go('/catalog?sort=$sort${discounted ? '&discounted=1' : ''}'))),
      SliverToBoxAdapter(child: _ProductRow(products: items)),
    ];
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final address = ref.watch(selectedAddressProvider);
    final cartCount = ref.watch(cartProvider.select((c) => c.value?.itemCount ?? 0));
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const JemisLogo(size: 36, showName: true),
          const Spacer(),
          Semantics(
            button: true,
            label: l.navCart,
            child: IconButton(
              onPressed: () => context.go('/cart'),
              icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
            ),
          ),
        ]),
        const SizedBox(height: Space.s),
        Semantics(
          button: true,
          label: l.deliverTo,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.chip),
            onTap: () => showAddressSheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(children: [
                Icon(Icons.location_on_outlined, color: cs.primary, size: 20),
                const SizedBox(width: Space.xs),
                Expanded(child: Text(address == null ? l.chooseAddress : '${address.city}, ${address.oneLine}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.keyboard_arrow_down),
              ]),
            ),
          ),
        ),
        const SizedBox(height: Space.s),
        Semantics(
          button: true,
          label: l.searchHint,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.chip),
            onTap: () => context.go('/catalog?focus=1'),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(Radii.chip), border: Border.all(color: cs.outline)),
              child: Row(children: [
                Icon(Icons.search, color: cs.onSurfaceVariant),
                const SizedBox(width: Space.s),
                Text(l.searchHint, style: TextStyle(color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Banners extends StatefulWidget {
  const _Banners({required this.banners});
  final List<BannerItem> banners;

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final _c = PageController(viewportFraction: 0.92);
  int _i = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color _color(String? hex) {
    if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return JemisColors.primaryStrong;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 140,
        child: PageView.builder(
          controller: _c,
          itemCount: widget.banners.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) {
            final b = widget.banners[i];
            final bg = _color(b.color);
            // Text colour chosen from the actual background luminance to keep contrast readable.
            final fg = bg.computeLuminance() > 0.5 ? JemisColors.text : Colors.white;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.s),
              child: Semantics(
                label: '${b.title}. ${b.subtitle ?? ''}',
                child: Container(
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.card)),
                  padding: const EdgeInsets.all(Space.l),
                  alignment: Alignment.centerLeft,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.title, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20, height: 1.15)),
                    if (b.subtitle != null) ...[const SizedBox(height: Space.xs), Text(b.subtitle!, style: TextStyle(color: fg))],
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      if (widget.banners.length > 1)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.banners.length; i++)
            Container(
              width: i == _i ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: i == _i ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
    ]);
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.m),
        itemBuilder: (_, i) {
          final c = categories[i];
          return Semantics(
            button: true,
            label: c.name,
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.card),
              onTap: () => context.go('/catalog?category=${c.id}'),
              child: SizedBox(
                width: 78,
                child: Column(children: [
                  CircleAvatar(radius: 30, backgroundColor: cs.primaryContainer, child: Icon(categoryIcon(c.icon), color: cs.onPrimaryContainer, size: 28)),
                  const SizedBox(height: Space.xs),
                  Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.1)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
        child: Row(children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)))),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: Text(context.l.seeAll)),
        ]),
      );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 290,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.l),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(width: Space.m),
          itemBuilder: (_, i) => ProductCard(product: products[i], width: 168),
        ),
      );
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(Space.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Skeleton(height: 120, radius: 16),
          SizedBox(height: Space.l),
          Skeleton(width: 140, height: 20),
          SizedBox(height: Space.m),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [ProductCardSkeleton(), SizedBox(width: Space.m), ProductCardSkeleton(), SizedBox(width: Space.m), ProductCardSkeleton()])),
        ]),
      );
}
