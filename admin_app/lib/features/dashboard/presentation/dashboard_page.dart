import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../data/dashboard_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final dash = ref.watch(dashboardProvider);
    return PageFrame(
      title: Text(l.dashboard),
      children: [
        AsyncBody<Dashboard>(
          value: dash,
          onRetry: () => ref.invalidate(dashboardProvider),
          builder: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: Space.m, runSpacing: Space.m, children: [
              _Metric(l.ordersToday, '${d.ordersToday}'),
              _Metric(l.paidRevenue, context.money(d.paidRevenueTodayMinor, currency: d.currency)),
              _Metric(l.awaiting, '${d.awaitingProcessing}'),
              _Metric(l.inDelivery, '${d.inDelivery}'),
              _Metric(l.lowStock, '${d.lowStockCount}'),
            ]),
            const SizedBox(height: Space.m),
            MutedText(l.revenueNote),
            const SizedBox(height: Space.l),
            _Section(l.recent),
            DataCard(
              headers: [l.colNumber, l.colStatus, l.colPayment, l.colTotal],
              rows: [
                for (final o in d.recentOrders)
                  [
                    TextButton(key: ValueKey('order-${o.id}'), onPressed: () => context.go('/orders/${o.id}'), child: Text(o.number)),
                    Badge2(statusLabel(l, o.status)),
                    Text(paymentStatusLabel(l, o.paymentStatus)),
                    Text(context.money(o.totalMinor)),
                  ],
              ],
            ),
            const SizedBox(height: Space.l),
            _Section(l.lowStock),
            DataCard(
              headers: [l.colSku, l.colName, l.colQty],
              rows: [
                for (final p in d.lowStock) [Text(p.sku), Text(p.name), Text(context.qty(p.availableMilli))],
              ],
            ),
          ]),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: Space.s), child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)));
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: Space.xs),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}
