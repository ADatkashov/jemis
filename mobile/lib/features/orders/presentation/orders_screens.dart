import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';

Color statusColor(BuildContext context, String s) {
  final cs = Theme.of(context).colorScheme;
  return switch (s) {
    'DELIVERED' => cs.primary,
    'CANCELLED' || 'REFUNDED' => cs.error,
    _ => const Color(0xFF8A5A00),
  };
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.ordersTitle)),
      body: orders.when(
        loading: () => const Padding(padding: EdgeInsets.all(Space.l), child: Column(children: [Skeleton(height: 72, radius: 16), SizedBox(height: Space.m), Skeleton(height: 72, radius: 16)])),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(ordersProvider)),
        data: (page) => page.items.isEmpty
            ? EmptyView(icon: Icons.receipt_long_outlined, title: l.noOrders, actionLabel: l.goShopping, onAction: () => context.go('/catalog'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ordersProvider);
                  await ref.read(ordersProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(Space.l),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.s),
                  itemBuilder: (_, i) {
                    final o = page.items[i];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/orders/${o.id}'),
                        title: Text(l.orderNumber(o.number), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(DateFormat.yMMMd(context.localeName).add_Hm().format(o.createdAt)),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(context.money(o.totalMinor), style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(statusLabel(l, o.status), style: TextStyle(color: statusColor(context, o.status), fontWeight: FontWeight.w600, fontSize: 12)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Timer? _poll;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // No push channel is active, so refresh periodically while an order is in progress.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      final o = ref.read(orderProvider(widget.id)).value;
      if (o != null && o.isActive) {
        ref.invalidate(orderProvider(widget.id));
        ref.invalidate(trackingProvider(widget.id));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(Order o) async {
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(content: Text(l.cancelOrderConfirm), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.cancelOrder))]),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(ordersRepositoryProvider).cancel(o.id);
      ref.invalidate(orderProvider(o.id));
      ref.invalidate(ordersProvider);
    });
  }

  Future<void> _reorder(Order o) => _run(() async {
        final skipped = await ref.read(ordersRepositoryProvider).reorder(o.id);
        await ref.read(cartProvider.notifier).reload();
        if (!mounted) return;
        if (skipped > 0) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.reorderSkipped)));
        context.go('/cart');
      });

  Future<void> _pay(Order o) => _run(() async {
        final l = context.l;
        final attempt = await ref.read(ordersRepositoryProvider).initiatePayment(o.id);
        if (!mounted) return;
        if (attempt.developmentOnly) {
          // DEVELOPMENT ONLY mock provider: completes through the backend's signed webhook path.
          final success = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.devOnly),
              content: Text(l.devPaymentNote),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.payFAILED)),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.paySUCCEEDED)),
              ],
            ),
          );
          if (success != null) await ref.read(ordersRepositoryProvider).simulateMockPayment(attempt.id, success: success);
        } else {
          throw StateError('Provider redirect flow is not implemented in this build');
        }
        ref.invalidate(orderProvider(o.id));
        ref.invalidate(ordersProvider);
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final order = ref.watch(orderProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: Text(order.value == null ? l.ordersTitle : l.orderNumber(order.value!.number)), actions: [
        IconButton(tooltip: l.retry, icon: const Icon(Icons.refresh), onPressed: () {
          ref.invalidate(orderProvider(widget.id));
          ref.invalidate(trackingProvider(widget.id));
        }),
      ]),
      body: order.when(
        loading: () => const Padding(padding: EdgeInsets.all(Space.l), child: Skeleton(height: 160, radius: 16)),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(orderProvider(widget.id))),
        data: (o) => ListView(padding: const EdgeInsets.all(Space.l), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(statusLabel(l, o.status), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: statusColor(context, o.status))),
                const SizedBox(height: Space.xs),
                Text('${l.paymentLabel}: ${paymentStatusLabel(l, o.paymentStatus)}'),
                if (o.slotLabel != null) Text(l.scheduledWindow('${o.slotDate} ${o.slotLabel}')),
                Text(o.addressLine),
              ]),
            ),
          ),
          const SizedBox(height: Space.m),
          if (o.awaitsOnlinePayment)
            FilledButton.icon(onPressed: _busy ? null : () => _pay(o), icon: const Icon(Icons.payment), label: Text(l.payNow)),
          if (o.isActive && o.status != 'PENDING_PAYMENT') _TrackingCard(orderId: o.id),
          const SizedBox(height: Space.m),
          Text(l.timeline, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: Space.s),
          for (final e in o.timeline)
            ListTile(
              dense: true,
              leading: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
              title: Text(statusLabel(l, e.status)),
              subtitle: Text(DateFormat.MMMd(context.localeName).add_Hm().format(e.at)),
            ),
          const SizedBox(height: Space.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(children: [
                for (final i in o.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [Expanded(child: Text('${i.name} × ${context.qty(i.quantityMilli)} ${unitLabel(l, i.unit)}')), Text(context.money(i.lineTotalMinor))]),
                  ),
                const Divider(),
                _line(l.subtotal, context.money(o.subtotalMinor)),
                if (o.discountMinor > 0) _line(l.discount, '−${context.money(o.discountMinor)}'),
                _line(l.deliveryFee, o.deliveryFeeMinor == 0 ? l.free : context.money(o.deliveryFeeMinor)),
                if (o.serviceFeeMinor > 0) _line(l.serviceFee, context.money(o.serviceFeeMinor)),
                _line(l.total, context.money(o.totalMinor), bold: true),
              ]),
            ),
          ),
          const SizedBox(height: Space.l),
          Wrap(spacing: Space.s, runSpacing: Space.s, children: [
            if (o.cancellable) OutlinedButton(onPressed: _busy ? null : () => _cancel(o), child: Text(l.cancelOrder)),
            OutlinedButton(onPressed: _busy ? null : () => _reorder(o), child: Text(l.reorder)),
            OutlinedButton.icon(
              icon: const Icon(Icons.support_agent),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppConfig.supportPhone.isEmpty ? l.supportNotConfigured : '${l.contactSupport}: ${AppConfig.supportPhone}'))),
              label: Text(l.contactSupport),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)), Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))]),
      );
}

/// Courier info + honest tracking: never a fabricated ETA or fake movement.
class _TrackingCard extends ConsumerWidget {
  const _TrackingCard({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final t = ref.watch(trackingProvider(orderId));
    return t.maybeWhen(
      data: (tr) => Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.courier, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Space.s),
            if (tr.courier == null)
              Text(l.courierPending)
            else
              Row(children: [
                CircleAvatar(backgroundColor: cs.primaryContainer, backgroundImage: tr.courier!.photoUrl == null ? null : NetworkImage(tr.courier!.photoUrl!), child: tr.courier!.photoUrl == null ? Icon(Icons.person, color: cs.onPrimaryContainer) : null),
                const SizedBox(width: Space.m),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr.courier!.name, style: const TextStyle(fontWeight: FontWeight.w700)), if (tr.courier!.maskedPhone != null) Text(tr.courier!.maskedPhone!, style: TextStyle(color: cs.onSurfaceVariant))])),
              ]),
            if (tr.courier?.lastLocationAt != null) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(l.lastKnownLocation(DateFormat.Hm(context.localeName).format(tr.courier!.lastLocationAt!)))),
            if (!tr.liveTracking) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(l.noLiveTracking, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))),
          ]),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
