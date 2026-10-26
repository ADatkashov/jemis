import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/quantity_stepper.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final signedIn = ref.watch(authProvider).value != null;
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.cartTitle),
        actions: [
          if (cart.value != null && !cart.value!.isEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: Text(l.clearCartConfirm),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.clearCart))],
                  ),
                );
                if (ok == true) {
                  try {
                    await ref.read(cartProvider.notifier).clear();
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                }
              },
              child: Text(l.clearCart),
            ),
        ],
      ),
      body: !signedIn
          ? SignInPrompt(icon: Icons.shopping_cart_outlined, onSignIn: () => context.push('/login'))
          : cart.when(
              loading: () => const Padding(padding: EdgeInsets.all(Space.l), child: Column(children: [Skeleton(height: 80, radius: 16), SizedBox(height: Space.m), Skeleton(height: 80, radius: 16)])),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(cartProvider)),
              data: (q) => q == null || q.isEmpty
                  ? EmptyView(icon: Icons.shopping_basket_outlined, title: l.cartEmpty, hint: l.cartEmptyHint, actionLabel: l.goShopping, onAction: () => context.go('/catalog'))
                  : _CartBody(quote: q),
            ),
    );
  }
}

class _CartBody extends ConsumerStatefulWidget {
  const _CartBody({required this.quote});
  final Quote quote;

  @override
  ConsumerState<_CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends ConsumerState<_CartBody> {
  final _promo = TextEditingController();
  final _busy = <String>{};

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  Future<void> _set(CartLine line, int milli) async {
    setState(() => _busy.add(line.productId));
    try {
      await ref.read(cartProvider.notifier).setQuantity(line.productId, milli);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(line.productId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final q = widget.quote;
    final cs = Theme.of(context).colorScheme;
    final blocked = q.issues.contains('UNAVAILABLE_ITEMS');
    final belowMin = q.issues.contains('MIN_ORDER_NOT_MET');
    final remainingForFree = q.freeDeliveryThresholdMinor == null ? null : q.freeDeliveryThresholdMinor! - (q.subtotalMinor - q.discountMinor);
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(Space.l), children: [
          if (q.minOrderMinor > 0) _Note(icon: Icons.shopping_bag_outlined, text: l.minOrderNote(context.money(q.minOrderMinor)), warn: belowMin),
          if (remainingForFree != null && remainingForFree > 0) _Note(icon: Icons.local_shipping_outlined, text: l.freeDeliveryNote(context.money(q.freeDeliveryThresholdMinor!))),
          for (final line in q.lines) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.m),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 72, height: 72, child: ProductImage(url: line.imageUrl)),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(line.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${context.money(line.unitPriceMinor)} / ${unitLabel(l, line.unit)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      if (line.issue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Space.xs),
                          child: Text(line.issue == 'UNAVAILABLE' ? l.itemUnavailable : l.itemInsufficient(context.qty(line.availableMilli)), style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                        ),
                      const SizedBox(height: Space.s),
                      Row(children: [
                        if (line.available)
                          QuantityStepper(compact: true, quantityMilli: line.quantityMilli, stepMilli: line.stepMilli, unit: line.unit, availableMilli: line.availableMilli, busy: _busy.contains(line.productId), onChanged: (m) => _set(line, m))
                        else
                          TextButton.icon(onPressed: () => _set(line, 0), icon: const Icon(Icons.delete_outline), label: Text(l.removeItem)),
                        const Spacer(),
                        Text(context.money(line.lineTotalMinor), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: Space.s),
          ],
          const SizedBox(height: Space.s),
          Row(children: [
            Expanded(child: TextField(controller: _promo, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: l.promoCode))),
            const SizedBox(width: Space.s),
            OutlinedButton(
              onPressed: () async {
                try {
                  await ref.read(cartProvider.notifier).applyPromo(_promo.text);
                } catch (e) {
                  if (!mounted) return;
                  showError(this.context, e);
                }
              },
              child: Text(l.apply),
            ),
          ]),
          if (q.promoError != null) Padding(padding: const EdgeInsets.only(top: Space.xs), child: Text(promoErrorLabel(l, q.promoError!), style: TextStyle(color: cs.error))),
          if (q.promoCode != null) Padding(padding: const EdgeInsets.only(top: Space.xs), child: Text('${l.promoApplied}: ${q.promoCode}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600))),
          const SizedBox(height: Space.l),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(children: [
                _Row(l.subtotal, context.money(q.subtotalMinor)),
                if (q.discountMinor > 0) _Row(l.discount, '−${context.money(q.discountMinor)}', color: cs.primary),
                _Row(l.deliveryFee, q.deliveryFeeMinor == 0 ? l.free : context.money(q.deliveryFeeMinor)),
                if (q.serviceFeeMinor > 0) _Row(l.serviceFee, context.money(q.serviceFeeMinor)),
                const Divider(),
                _Row(l.total, context.money(q.totalMinor), bold: true),
              ]),
            ),
          ),
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: blocked || belowMin ? null : () => context.push('/checkout'),
              child: Text('${l.checkout} · ${context.money(q.totalMinor)}'),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.warn = false});
  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.s),
      padding: const EdgeInsets.all(Space.m),
      decoration: BoxDecoration(color: warn ? const Color(0xFFFFF1C2) : cs.primaryContainer, borderRadius: BorderRadius.circular(Radii.chip)),
      child: Row(children: [
        Icon(icon, size: 20, color: warn ? JemisColors.text : cs.onPrimaryContainer),
        const SizedBox(width: Space.s),
        Expanded(child: Text(text, style: TextStyle(color: warn ? JemisColors.text : cs.onPrimaryContainer))),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 18 : 14, color: color);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]));
  }
}
