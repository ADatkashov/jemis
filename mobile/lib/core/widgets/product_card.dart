import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../l10n_x.dart';
import '../models.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'quantity_stepper.dart';

/// Adds/changes a cart line; sends signed-out users to the login screen.
Future<void> changeCartQuantity(BuildContext context, WidgetRef ref, Product p, int milli) async {
  // Await the session check: the provider may still be loading right after app start.
  final profile = await ref.read(authProvider.future).then<Object?>((p) => p).catchError((_) => null);
  if (!context.mounted) return;
  if (profile == null) {
    context.push('/login');
    return;
  }
  try {
    await ref.read(cartProvider.notifier).setQuantity(p.id, milli);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({super.key, required this.product, this.width});
  final Product product;
  final double? width;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _busy = false;

  Future<void> _set(int milli) async {
    setState(() => _busy = true);
    await changeCartQuantity(context, ref, widget.product, milli);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final qty = ref.watch(cartProvider.select((c) => c.value?.quantityOf(p.id) ?? 0));
    final unit = unitLabel(l, p.unit);
    final perUnit = p.packLabel != null && !p.weighted ? p.packLabel! : unit;
    return SizedBox(
      width: widget.width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/product/${p.id}'),
          child: Padding(
            padding: const EdgeInsets.all(Space.s),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: Stack(fit: StackFit.expand, children: [
                  ProductImage(url: p.imageUrl),
                  if (p.discountPercent != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs),
                        decoration: const BoxDecoration(color: JemisColors.accent, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                        child: Text(l.discountBadge(p.discountPercent.toString()), style: const TextStyle(fontWeight: FontWeight.w800, color: JemisColors.text, fontSize: 12)),
                      ),
                    ),
                  if (!p.available)
                    Container(
                      color: Colors.white70,
                      alignment: Alignment.center,
                      child: Text(l.unavailable, style: const TextStyle(fontWeight: FontWeight.w700, color: JemisColors.text)),
                    ),
                ]),
              ),
              const SizedBox(height: Space.s),
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2)),
              const SizedBox(height: Space.xs),
              Text(p.weighted ? l.perUnit(context.money(p.priceMinor), unit) : perUnit, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: Space.xs),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (p.oldPriceMinor != null)
                      Text(context.money(p.oldPriceMinor!), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, decoration: TextDecoration.lineThrough)),
                    if (!p.weighted) Text(context.money(p.priceMinor), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
                if (p.available)
                  qty == 0
                      ? Semantics(
                          button: true,
                          label: '${l.addToCart}: ${p.name}',
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton.filled(
                              onPressed: _busy ? null : () => _set(p.initialQuantityMilli),
                              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
              ]),
              if (p.available && qty > 0) ...[
                const SizedBox(height: Space.xs),
                Center(child: QuantityStepper(compact: true, quantityMilli: qty, stepMilli: p.stepMilli, unit: p.unit, availableMilli: p.availableMilli, busy: _busy, onChanged: _set)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
