import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../../delivery/data/delivery_repository.dart';
import '../data/orders_repository.dart';

/// "Almaty, Abay 1, apt 5, entrance 2": optional parts are appended only when present.
String formatAddress(AppL10n l, OrderAddress a) {
  final parts = <String>[
    '${a.city}, ${a.street} ${a.house}',
    if (_has(a.apartment)) l.addrApartment(a.apartment!),
    if (_has(a.entrance)) l.addrEntrance(a.entrance!),
    if (_has(a.floor)) l.addrFloor(a.floor!),
    if (_has(a.intercom)) l.addrIntercom(a.intercom!),
  ];
  return parts.join(', ');
}

bool _has(String? s) => s != null && s.isNotEmpty;

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  String _msg = '';
  String? _courierId;

  Future<void> _act(Future<void> Function() fn) async {
    final l = context.l;
    setState(() => _msg = '');
    try {
      await fn();
      ref.invalidate(orderDetailProvider(widget.id));
    } catch (e) {
      if (mounted) setState(() => _msg = errorMessage(l, e));
    }
  }

  Future<void> _changeStatus(String s) async {
    if (s == 'CANCELLED' && !await confirmDialog(context, context.l.cancelOrderConfirm)) return;
    await _act(() => ref.read(ordersRepositoryProvider).changeStatus(widget.id, s));
  }

  Future<void> _refund() async {
    if (!await confirmDialog(context, context.l.refundConfirm)) return;
    await _act(() => ref.read(ordersRepositoryProvider).refund(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final detail = ref.watch(orderDetailProvider(widget.id));
    final o = detail.value;
    return PageFrame(
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(o?.number ?? l.orders),
        if (o != null) ...[const SizedBox(width: Space.m), Badge2(statusLabel(l, o.status))],
      ]),
      children: [
        AsyncBody<OrderDetailModel>(
          value: detail,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.id)),
          builder: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: Space.m), child: ErrorBox(message: _msg)),
            _statusCard(context, d),
            _card(context, l.deliverySection, [
              Text('${d.recipientName} ${d.recipientPhone ?? ''}'.trim()),
              Text(formatAddress(l, d.address)),
              if (d.slotLabel != null) Text(d.slotLabel!),
              if (_has(d.instructions)) MutedText(d.instructions!),
            ]),
            _card(context, l.itemsSection, [_itemsTable(context, d)]),
            _card(context, l.paymentSection(d.paymentMethod), [
              Align(alignment: Alignment.centerLeft, child: Badge2(paymentStatusLabel(l, d.paymentStatus))),
              const SizedBox(height: Space.s),
              for (final p in d.payments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${p.provider}  ${paymentStatusLabel(l, p.status)}  ${context.money(p.amountMinor)}  ${p.failureReason ?? ''}'.trim()),
                ),
            ]),
            if (d.issues.isNotEmpty)
              _card(context, l.deliveryIssues, [for (final i in d.issues) Text('${context.dateTime(i.createdAt)}: ${i.description}')]),
            _card(context, l.timeline, [
              for (final e in d.timeline)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${context.dateTime(e.at)} — ${statusLabel(l, e.status)}'),
                    if (_has(e.note)) TextSpan(text: ' (${e.note})', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),
                ),
            ]),
            _NotesCard(
              key: ValueKey('notes-${d.id}-${d.operatorNotes}'),
              initial: d.operatorNotes ?? '',
              onSave: (text) => _act(() => ref.read(ordersRepositoryProvider).saveNotes(widget.id, text)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: Space.l),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: Space.s),
                ...children,
              ]),
            ),
          ),
        ),
      );

  Widget _statusCard(BuildContext context, OrderDetailModel d) {
    final l = context.l;
    final couriers = ref.watch(couriersProvider).value ?? const <Courier>[];
    final active = couriers.where((c) => c.active).toList();
    final cs = Theme.of(context).colorScheme;
    return _card(context, l.orderStatusSection, [
      Wrap(spacing: Space.s, runSpacing: Space.s, children: [
        for (final s in d.allowedNext)
          FilledButton(
            key: ValueKey('to-$s'),
            style: s == 'CANCELLED' ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
            onPressed: () => _changeStatus(s),
            child: Text(l.moveTo(statusLabel(l, s))),
          ),
        if (d.canRefund) OutlinedButton(key: const ValueKey('refund'), onPressed: _refund, child: Text(l.refund)),
      ]),
      if (d.canAssignCourier) ...[
        const SizedBox(height: Space.m),
        Wrap(spacing: Space.m, runSpacing: Space.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FieldBox(
            child: DropdownButtonFormField<String>(
              key: const ValueKey('courier'),
              initialValue: _courierId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.courier),
              items: [for (final c in active) DropdownMenuItem(value: c.id, child: Text(c.displayName))],
              onChanged: (v) => setState(() => _courierId = v),
            ),
          ),
          FilledButton(
            key: const ValueKey('assign'),
            onPressed: _courierId == null ? null : () => _act(() => ref.read(ordersRepositoryProvider).assign(widget.id, _courierId!)),
            child: Text(l.offerToCourier),
          ),
        ]),
      ],
      if (d.courierName != null) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(l.courierLine(d.courierName!, d.courierPhone ?? '').trim())),
    ]);
  }

  Widget _itemsTable(BuildContext context, OrderDetailModel d) {
    final l = context.l;
    Widget total(String label, String value, {bool b = false}) => _TotalRow(label, value, bold: b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DataCard(
        headers: [l.colSku, l.colName, l.colQty, l.colPrice, l.colTotal],
        rows: [
          for (final i in d.items) [Text(i.sku), Text(i.name), Text(context.qty(i.quantityMilli)), Text(context.money(i.unitPriceMinor)), Text(context.money(i.lineTotalMinor))],
        ],
      ),
      const SizedBox(height: Space.s),
      total(l.subtotal, context.money(d.subtotalMinor)),
      if (d.discountMinor > 0) total(l.discountLine(d.promoCode ?? '').trim(), '−${context.money(d.discountMinor)}'),
      total(l.deliveryFee, context.money(d.deliveryFeeMinor)),
      if (d.serviceFeeMinor > 0) total(l.serviceFee, context.money(d.serviceFeeMinor)),
      total(l.total, context.money(d.totalMinor), b: true),
    ]);
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w700) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: Space.s),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]),
    );
  }
}

class _NotesCard extends StatefulWidget {
  const _NotesCard({super.key, required this.initial, required this.onSave});
  final String initial;
  final Future<void> Function(String) onSave;

  @override
  State<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<_NotesCard> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.operatorNotes, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Space.s),
            TextField(key: const ValueKey('notes'), controller: _c, minLines: 3, maxLines: 6, onChanged: (_) => setState(() {})),
            const SizedBox(height: Space.s),
            FilledButton(
              key: const ValueKey('save-notes'),
              onPressed: _c.text.trim().isEmpty || _c.text == widget.initial ? null : () => widget.onSave(_c.text.trim()),
              child: Text(l.save),
            ),
          ]),
        ),
      ),
    );
  }
}
