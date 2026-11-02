import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../data/customers_repository.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  CustomerQuery _q = const CustomerQuery();
  String? _selected;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _q = CustomerQuery(q: v.trim())));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final list = ref.watch(customersProvider(_q));
    return PageFrame(
      title: Text(l.customers),
      children: [
        FormRow(children: [
          FieldBox(child: TextField(key: const ValueKey('search'), decoration: InputDecoration(labelText: l.search, hintText: l.searchCustomersHint), onChanged: _search)),
        ]),
        AsyncBody<Paged<CustomerRow>>(
          value: list,
          onRetry: () => ref.invalidate(customersProvider),
          builder: (data) => data.items.isEmpty
              ? const EmptyNote()
              : DataCard(
                  headers: [l.colName, l.colEmail, l.colPhone, l.colStatus, ''],
                  rows: [
                    for (final c in data.items)
                      [
                        Text(c.fullName),
                        Text(c.email ?? ''),
                        Text(c.phone ?? ''),
                        Text(userStatusLabel(l, c.status)),
                        OutlinedButton(key: ValueKey('orders-${c.id}'), onPressed: () => setState(() => _selected = c.id), child: Text(l.customerOrders)),
                      ],
                  ],
                  footer: Align(alignment: Alignment.centerLeft, child: Pager(page: data.page, totalPages: data.totalPages, onPage: (p) => setState(() => _q = CustomerQuery(q: _q.q, page: p)))),
                ),
        ),
        if (_selected != null) ...[
          const SizedBox(height: Space.l),
          _CustomerOrders(id: _selected!),
        ],
      ],
    );
  }
}

class _CustomerOrders extends ConsumerWidget {
  const _CustomerOrders({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return AsyncBody<CustomerDetail>(
      value: ref.watch(customerDetailProvider(id)),
      onRetry: () => ref.invalidate(customerDetailProvider(id)),
      builder: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.customer.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.s),
        d.orders.isEmpty
            ? const EmptyNote()
            : DataCard(
                headers: [l.colNumber, l.colStatus, l.colTotal, l.colDate],
                rows: [
                  for (final o in d.orders)
                    [
                      TextButton(key: ValueKey('customer-order-${o.id}'), onPressed: () => context.go('/orders/${o.id}'), child: Text(o.number)),
                      Text(statusLabel(l, o.status)),
                      Text(context.money(o.totalMinor)),
                      Text(context.dateTime(o.createdAt)),
                    ],
                ],
              ),
      ]),
    );
  }
}
