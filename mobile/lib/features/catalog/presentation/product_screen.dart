import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/quantity_stepper.dart';

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        actions: [
          detail.maybeWhen(
            data: (d) => _FavoriteButton(product: d.product),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Padding(padding: EdgeInsets.all(Space.l), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Skeleton(height: 260, radius: 20), SizedBox(height: Space.l), Skeleton(width: 220, height: 24), SizedBox(height: Space.m), Skeleton(width: 120, height: 20)])),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(productDetailProvider(id))),
        data: (d) => _Body(detail: d),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = (ref.watch(favoritesProvider).value ?? const []).any((p) => p.id == product.id);
    return IconButton(
      tooltip: context.l.favorites,
      isSelected: isFav,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite, color: Theme.of(context).colorScheme.error),
      onPressed: () async {
        if (ref.read(authProvider).value == null) {
          context.push('/login');
          return;
        }
        try {
          await ref.read(favoritesProvider.notifier).toggle(product);
        } catch (e) {
          if (context.mounted) showError(context, e);
        }
      },
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.detail});
  final ProductDetail detail;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  int? _pending; // quantity chosen before adding to the cart
  bool _busy = false;

  Future<void> _apply(Product p, int milli) async {
    setState(() => _busy = true);
    await changeCartQuantity(context, ref, p, milli);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final p = widget.detail.product;
    final inCart = ref.watch(cartProvider.select((c) => c.value?.quantityOf(p.id) ?? 0));
    final unit = unitLabel(l, p.unit);
    final chosen = _pending ?? p.initialQuantityMilli;
    final lineTotal = ((p.priceMinor * chosen) + 500) ~/ 1000; // preview only; the server recalculates
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(Space.l), children: [
          AspectRatio(aspectRatio: 1.3, child: ProductImage(url: p.imageUrl, radius: 20)),
          const SizedBox(height: Space.l),
          if (p.brand != null) Text(p.brand!, style: TextStyle(color: cs.onSurfaceVariant)),
          Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: Space.s),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(p.weighted ? l.perUnit(context.money(p.priceMinor), unit) : context.money(p.priceMinor), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (p.oldPriceMinor != null) ...[
              const SizedBox(width: Space.s),
              Text(context.money(p.oldPriceMinor!), style: TextStyle(color: cs.onSurfaceVariant, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: Space.s),
              Chip(label: Text(l.discountBadge(p.discountPercent.toString())), backgroundColor: JemisColors.accent, labelStyle: const TextStyle(color: JemisColors.text, fontWeight: FontWeight.w800), visualDensity: VisualDensity.compact),
            ],
          ]),
          if (p.packLabel != null) Text(p.packLabel!, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: Space.s),
          if (!p.available) Text(l.unavailable, style: TextStyle(color: cs.error, fontWeight: FontWeight.w700)) else if (p.lowStock) Text(l.lowStockLabel, style: const TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w700)),
          if (p.weighted) ...[
            const SizedBox(height: Space.s),
            Container(padding: const EdgeInsets.all(Space.m), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(Radii.chip)), child: Row(children: [
              Icon(Icons.scale_outlined, color: cs.onPrimaryContainer),
              const SizedBox(width: Space.s),
              Expanded(child: Text(l.priceByWeight(unit), style: TextStyle(color: cs.onPrimaryContainer))),
            ])),
          ],
          // Only facts supplied by the catalog are shown; nothing is invented.
          _Section(title: l.description, text: p.description),
          _Section(title: l.ingredients, text: p.ingredients),
          _Section(title: l.storage, text: p.storage),
          _Section(title: l.allergens, text: p.allergens),
          if (p.attributes != null && p.attributes!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: Space.l), child: Wrap(spacing: Space.s, runSpacing: Space.s, children: [for (final e in p.attributes!.entries) Chip(label: Text('${e.key}: ${e.value}'))])),
          if (widget.detail.related.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            Text(l.related, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Space.s),
            SizedBox(height: 290, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: widget.detail.related.length, separatorBuilder: (_, _) => const SizedBox(width: Space.m), itemBuilder: (_, i) => ProductCard(product: widget.detail.related[i], width: 168))),
          ],
        ]),
      ),
      if (p.available)
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(Space.l),
            decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outline))),
            child: inCart > 0
                ? Row(children: [
                    QuantityStepper(quantityMilli: inCart, stepMilli: p.stepMilli, unit: p.unit, availableMilli: p.availableMilli, busy: _busy, onChanged: (m) => _apply(p, m)),
                    const SizedBox(width: Space.m),
                    Expanded(child: FilledButton(onPressed: () => context.go('/cart'), child: Text(l.navCart))),
                  ])
                : Row(children: [
                    QuantityStepper(quantityMilli: chosen, stepMilli: p.stepMilli, unit: p.unit, availableMilli: p.availableMilli, onChanged: (m) => setState(() => _pending = m < p.stepMilli ? p.stepMilli : m)),
                    const SizedBox(width: Space.m),
                    Expanded(child: FilledButton(onPressed: _busy ? null : () => _apply(p, chosen), child: Text('${l.addToCart} · ${context.money(lineTotal)}'))),
                  ]),
          ),
        ),
    ]);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.text});
  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.l),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.xs),
        Text(text!),
      ]),
    );
  }
}
