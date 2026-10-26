import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';

/// Single-page checkout: address -> time -> payment -> review -> confirm.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  /// One key per checkout attempt: repeated taps or network retries return the same order.
  final String _idempotencyKey = const Uuid().v4();
  String? _slotId;
  String? _slotDate;
  int _slotExtraFee = 0;
  String _method = 'CASH';
  bool _placing = false;
  String? _message;
  Quote? _quote;

  Future<void> _refreshQuote() async {
    final address = ref.read(selectedAddressProvider);
    if (address == null) return;
    try {
      final q = await ref.read(checkoutRepositoryProvider).quote(addressId: address.id, slotTemplateId: _slotId, promoCode: ref.read(promoCodeProvider));
      if (mounted) setState(() => _quote = q);
    } catch (e) {
      if (mounted) setState(() => _message = errorMessage(context.l, e));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuote());
  }

  Future<void> _place() async {
    final l = context.l;
    final address = ref.read(selectedAddressProvider);
    final quote = _quote;
    if (address == null || quote == null || _slotId == null || _slotDate == null) return;
    setState(() {
      _placing = true;
      _message = null;
    });
    try {
      final order = await ref.read(checkoutRepositoryProvider).place(
            idempotencyKey: _idempotencyKey,
            addressId: address.id,
            slotTemplateId: _slotId!,
            slotDate: _slotDate!,
            paymentMethod: _method,
            promoCode: ref.read(promoCodeProvider),
            expectedTotalMinor: quote.totalMinor,
          );
      ref.read(promoCodeProvider.notifier).set(null);
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      ref.invalidate(availabilityProvider);
      if (mounted) context.go('/checkout/done/${order.id}');
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.code == 'PRICE_CHANGED') {
        final total = (e.details?['totalMinor'] as num?)?.toInt();
        setState(() => _message = total == null ? l.errorGeneric : l.priceChanged(context.money(total)));
        await _refreshQuote();
      } else if (e.code == 'CHECKOUT_BLOCKED') {
        final issues = (e.details?['issues'] as List?)?.cast<String>() ?? const [];
        setState(() => _message = issues.contains('ADDRESS_NOT_SERVICEABLE')
            ? l.addressNotServiceable
            : issues.contains('MIN_ORDER_NOT_MET')
                ? l.minOrderNotMet
                : l.checkoutBlocked);
        ref.invalidate(cartProvider);
      } else if (e.code == 'SLOT_FULL' || e.code == 'SLOT_UNAVAILABLE') {
        setState(() {
          _message = l.slotUnavailable;
          _slotId = null;
          _slotDate = null;
        });
        ref.invalidate(availabilityProvider);
      } else {
        setState(() => _message = errorMessage(l, e));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final addresses = ref.watch(addressesProvider);
    final address = ref.watch(selectedAddressProvider);
    final availability = ref.watch(availabilityProvider);
    final methods = ref.watch(paymentMethodsProvider);
    ref.listen(selectedAddressProvider, (_, _) => _refreshQuote());
    final ready = address != null && _quote != null && _slotId != null && !_quote!.checkoutBlocked;

    return Scaffold(
      appBar: AppBar(title: Text(l.checkoutTitle)),
      body: addresses.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.all(Space.l), children: [
                  _Title(l.deliveryAddress),
                  if (address == null)
                    Card(child: ListTile(leading: const Icon(Icons.add_location_alt_outlined), title: Text(l.addAddressFirst), onTap: () => context.push('/profile/addresses/new')))
                  else
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.location_on_outlined, color: cs.primary),
                        title: Text('${address.city}, ${address.oneLine}'),
                        subtitle: address.instructions == null ? null : Text(address.instructions!),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickAddress(context, addresses.value ?? const []),
                      ),
                    ),
                  const SizedBox(height: Space.l),
                  _Title(l.deliveryTime),
                  availability.when(
                    loading: () => const Skeleton(height: 120, radius: 16),
                    error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(availabilityProvider)),
                    data: (a) => _Slots(
                      availability: a,
                      selectedId: _slotId,
                      selectedDate: _slotDate,
                      onSelect: (day, slot) {
                        setState(() {
                          _slotId = slot.templateId;
                          _slotDate = day.date;
                          _slotExtraFee = slot.extraFeeMinor;
                        });
                        _refreshQuote();
                      },
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  _Title(l.paymentMethod),
                  methods.when(
                    loading: () => const Skeleton(height: 100, radius: 16),
                    error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(paymentMethodsProvider)),
                    data: (list) {
                      if (!list.any((m) => m.method == _method) && list.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _method = list.first.method));
                      return RadioGroup<String>(
                        groupValue: _method,
                        onChanged: (v) => setState(() => _method = v ?? _method),
                        child: Column(children: [
                          for (final m in list)
                            Card(
                              child: RadioListTile<String>(
                                value: m.method,
                                title: Text(m.method == 'CASH' ? l.payCash : l.payOnline),
                                subtitle: m.developmentOnly ? Text('${l.devOnly}: ${l.devPaymentNote}', style: const TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w700)) : null,
                              ),
                            ),
                        ]),
                      );
                    },
                  ),
                  const SizedBox(height: Space.l),
                  _Title(l.orderSummary),
                  if (_quote != null) _Summary(quote: _quote!, slotFee: _slotExtraFee),
                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.only(top: Space.m),
                      padding: const EdgeInsets.all(Space.m),
                      decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Radii.chip)),
                      child: Text(_message!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
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
                      onPressed: ready && !_placing ? _place : null,
                      child: _placing ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('${l.placeOrder}${_quote == null ? '' : ' · ${context.money(_quote!.totalMinor)}'}'),
                    ),
                  ),
                ),
              ),
            ]),
    );
  }

  void _pickAddress(BuildContext context, List<Address> list) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final a in list)
            ListTile(
              title: Text('${a.city}, ${a.oneLine}'),
              onTap: () {
                ref.read(selectedAddressIdProvider.notifier).select(a.id);
                Navigator.pop(ctx);
              },
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(context.l.addAddress),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/profile/addresses/new');
            },
          ),
        ]),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: Space.s), child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))));
}

class _Slots extends StatefulWidget {
  const _Slots({required this.availability, required this.selectedId, required this.selectedDate, required this.onSelect});
  final Availability availability;
  final String? selectedId;
  final String? selectedDate;
  final void Function(SlotDay, Slot) onSelect;

  @override
  State<_Slots> createState() => _SlotsState();
}

class _SlotsState extends State<_Slots> {
  int _day = 0;

  String _dayLabel(BuildContext context, SlotDay d, int index) {
    if (index == 0) return context.l.today;
    if (index == 1) return context.l.tomorrow;
    return DateFormat.MMMEd(context.localeName).format(DateTime.parse(d.date));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final days = widget.availability.days.where((d) => d.slots.isNotEmpty).toList();
    if (days.isEmpty) return Text(l.noSlots);
    final day = days[_day.clamp(0, days.length - 1)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.selectSlotHint, style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: Space.s),
      Wrap(spacing: Space.s, children: [
        for (var i = 0; i < days.length; i++) ChoiceChip(label: Text(_dayLabel(context, days[i], i)), selected: i == _day, onSelected: (_) => setState(() => _day = i)),
      ]),
      const SizedBox(height: Space.s),
      Wrap(spacing: Space.s, runSpacing: Space.s, children: [
        for (final s in day.slots)
          Semantics(
            button: true,
            enabled: s.available,
            selected: widget.selectedId == s.templateId && widget.selectedDate == day.date,
            label: '${s.label}${s.available ? '' : ', ${l.slotFull}'}',
            child: ChoiceChip(
              label: Text(s.available ? (s.extraFeeMinor > 0 ? '${s.label} (+${context.money(s.extraFeeMinor)})' : s.label) : '${s.label} · ${l.slotFull}'),
              selected: widget.selectedId == s.templateId && widget.selectedDate == day.date,
              onSelected: s.available ? (_) => widget.onSelect(day, s) : null,
            ),
          ),
      ]),
    ]);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.quote, required this.slotFee});
  final Quote quote;
  final int slotFee;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    Widget row(String a, String b, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)), Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 18 : 14))]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(children: [
          for (final line in quote.lines) row('${line.name} × ${context.qty(line.quantityMilli)}', context.money(line.lineTotalMinor)),
          const Divider(),
          row(l.subtotal, context.money(quote.subtotalMinor)),
          if (quote.discountMinor > 0) row(l.discount, '−${context.money(quote.discountMinor)}'),
          row(l.deliveryFee, quote.deliveryFeeMinor == 0 ? l.free : context.money(quote.deliveryFeeMinor)),
          if (quote.serviceFeeMinor > 0) row(l.serviceFee, context.money(quote.serviceFeeMinor)),
          const Divider(),
          row(l.total, context.money(quote.totalMinor), bold: true),
          if (quote.promoError != null) Align(alignment: Alignment.centerLeft, child: Text(promoErrorLabel(l, quote.promoError!), style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ]),
      ),
    );
  }
}

class OrderDoneScreen extends ConsumerWidget {
  const OrderDoneScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final order = ref.watch(orderProvider(orderId));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Icon(Icons.check_circle, size: 88, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: Space.l),
            Text(l.orderPlacedTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Space.s),
            order.maybeWhen(data: (o) => Text(l.orderNumber(o.number), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), orElse: () => const SizedBox.shrink()),
            const SizedBox(height: Space.s),
            Text(l.orderPlacedHint, textAlign: TextAlign.center),
            const SizedBox(height: Space.xxl),
            FilledButton(onPressed: () => context.go('/orders/$orderId'), child: Text(order.value?.awaitsOnlinePayment == true ? l.payNow : l.viewOrder)),
            const SizedBox(height: Space.s),
            OutlinedButton(onPressed: () => context.go('/'), child: Text(l.backToHome)),
          ]),
        ),
      ),
    );
  }
}
