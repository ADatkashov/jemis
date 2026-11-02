import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../data/orders_repository.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  OrderQuery _q = const OrderQuery();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _q = OrderQuery(q: v.trim(), status: _q.status)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final list = ref.watch(ordersListProvider(_q));
    return PageFrame(
      title: Text(l.orders),
      children: [
        FormRow(children: [
          FieldBox(
            child: TextField(key: const ValueKey('search'), decoration: InputDecoration(labelText: l.search, hintText: l.searchOrdersHint), onChanged: _search),
          ),
          FieldBox(
            child: DropdownButtonFormField<String>(
              key: const ValueKey('status-filter'),
              initialValue: _q.status,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.colStatus),
              items: [
                DropdownMenuItem(value: '', child: Text(l.allStatuses)),
                for (final s in orderStatuses) DropdownMenuItem(value: s, child: Text(statusLabel(l, s))),
              ],
              onChanged: (v) => setState(() => _q = OrderQuery(q: _q.q, status: v ?? '')),
            ),
          ),
        ]),
        AsyncBody<Paged<OrderRow>>(
          value: list,
          onRetry: () => ref.invalidate(ordersListProvider),
          builder: (data) => data.items.isEmpty
              ? const EmptyNote()
              : DataCard(
                  headers: [l.colNumber, l.colDate, l.colRecipient, l.colStatus, l.colPayment, l.colTotal],
                  rows: [
                    for (final o in data.items)
                      [
                        TextButton(key: ValueKey('order-${o.id}'), onPressed: () => context.go('/orders/${o.id}'), child: Text(o.number)),
                        Text(context.dateTime(o.createdAt)),
                        Text(o.recipientName),
                        Badge2(statusLabel(l, o.status)),
                        Text(paymentStatusLabel(l, o.paymentStatus)),
                        Text(context.money(o.totalMinor)),
                      ],
                  ],
                  footer: Align(
                    alignment: Alignment.centerLeft,
                    child: Pager(page: data.page, totalPages: data.totalPages, onPage: (p) => setState(() => _q = _q.copyWith(page: p))),
                  ),
                ),
        ),
        const SizedBox(height: Space.l),
      ],
    );
  }
}
