import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_dialog.dart';
import '../data/delivery_repository.dart';

class DeliveryPage extends ConsumerWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return PageFrame(
      title: Text(l.delivery),
      children: [
        MutedText(l.deliveryZonesNote),
        const SizedBox(height: Space.l),
        const _ZonesCard(),
        const SizedBox(height: Space.l),
        const _SlotsCard(),
        const SizedBox(height: Space.l),
        const _CouriersCard(),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: Space.m, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ?action,
        ]),
        const SizedBox(height: Space.s),
        child,
      ]);
}

// ------------------------------------------------------------------ zones

class _ZonesCard extends ConsumerWidget {
  const _ZonesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final zones = ref.watch(zonesProvider);
    Future<void> open(Zone? z) => showDialog<bool>(context: context, builder: (_) => ZoneDialog(initial: z));
    return _Section(
      title: l.zonesTitle,
      action: FilledButton.icon(key: const ValueKey('new-zone'), onPressed: () => open(null), icon: const Icon(Icons.add), label: Text(l.addZone)),
      child: AsyncBody<List<Zone>>(
        value: zones,
        onRetry: () => ref.invalidate(zonesProvider),
        builder: (list) => DataCard(
          headers: [l.colName, l.colCity, l.colFee, l.colMinimum, l.colFreeFrom, l.colActive, ''],
          rows: [
            for (final z in list)
              [
                Text(z.name),
                Text(z.city),
                Text(context.money(z.feeMinor)),
                Text(context.money(z.minOrderMinor)),
                Text(z.freeDeliveryThresholdMinor == null ? l.none : context.money(z.freeDeliveryThresholdMinor!)),
                BoolMark(z.active),
                TextButton(key: ValueKey('edit-zone-${z.id}'), onPressed: () => open(z), child: Text(l.edit)),
              ],
          ],
        ),
      ),
    );
  }
}

class ZoneDialog extends ConsumerStatefulWidget {
  const ZoneDialog({super.key, this.initial});
  final Zone? initial;
  @override
  ConsumerState<ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends ConsumerState<ZoneDialog> {
  final _form = GlobalKey<FormState>();
  late final Zone? _z = widget.initial;
  late bool _active = _z?.active ?? true;
  late final _name = TextEditingController(text: _z?.name);
  late final _city = TextEditingController(text: _z?.city);
  late final _fee = TextEditingController(text: moneyToInput(_z?.feeMinor ?? 0));
  late final _min = TextEditingController(text: moneyToInput(_z?.minOrderMinor ?? 0));
  late final _free = TextEditingController(text: _z?.freeDeliveryThresholdMinor == null ? '' : moneyToInput(_z!.freeDeliveryThresholdMinor!));

  @override
  void dispose() {
    for (final c in [_name, _city, _fee, _min, _free]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _save() async {
    final l = context.l;
    final r = validateZone(id: _z?.id, name: _name.text, city: _city.text, fee: _fee.text, min: _min.text, free: _free.text, active: _active);
    if (!r.ok) return formErrorMessage(l, r.error!);
    try {
      await ref.read(deliveryRepositoryProvider).saveZone(r.value!);
      ref.invalidate(zonesProvider);
      return null;
    } catch (e) {
      return errorMessage(l, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    const money = TextInputType.numberWithOptions(decimal: true);
    return AdminFormDialog(
      title: l.editZone,
      formKey: _form,
      onSubmit: _save,
      children: [
        FormRow(children: [
          TextBox(label: l.zoneName, controller: _name, required: true),
          TextBox(label: l.zoneCity, controller: _city, required: true, width: 340),
          TextBox(label: l.deliveryFeeLabel, controller: _fee, keyboard: money),
          TextBox(label: l.minOrderLabel, controller: _min, keyboard: money),
          TextBox(label: l.freeFromLabel, controller: _free, keyboard: money),
          SwitchBox(label: l.active, value: _active, onChanged: (v) => setState(() => _active = v)),
        ]),
      ],
    );
  }
}

// ------------------------------------------------------------------ slots

class _SlotsCard extends ConsumerWidget {
  const _SlotsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final slots = ref.watch(slotsProvider);
    Future<void> open(Slot? s) => showDialog<bool>(context: context, builder: (_) => SlotDialog(initial: s));
    return _Section(
      title: l.slotsTitle,
      action: FilledButton.icon(key: const ValueKey('new-slot'), onPressed: () => open(null), icon: const Icon(Icons.add), label: Text(l.addWindow)),
      child: AsyncBody<List<Slot>>(
        value: slots,
        onRetry: () => ref.invalidate(slotsProvider),
        builder: (list) => DataCard(
          headers: [l.colWindow, l.colCapacity, l.colDays, l.colExtraFee, l.colActive, ''],
          rows: [
            for (final s in list)
              [
                Text('${s.startTime}–${s.endTime}'),
                Text('${s.capacity}'),
                Text(s.daysOfWeek),
                Text(context.money(s.extraFeeMinor)),
                BoolMark(s.active),
                TextButton(key: ValueKey('edit-slot-${s.id}'), onPressed: () => open(s), child: Text(l.edit)),
              ],
          ],
        ),
      ),
    );
  }
}

class SlotDialog extends ConsumerStatefulWidget {
  const SlotDialog({super.key, this.initial});
  final Slot? initial;
  @override
  ConsumerState<SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends ConsumerState<SlotDialog> {
  final _form = GlobalKey<FormState>();
  late final Slot? _s = widget.initial;
  late bool _active = _s?.active ?? true;
  late final _start = TextEditingController(text: _s?.startTime ?? '10:00');
  late final _end = TextEditingController(text: _s?.endTime ?? '12:00');
  late final _cap = TextEditingController(text: '${_s?.capacity ?? 10}');
  late final _days = TextEditingController(text: _s?.daysOfWeek ?? '1,2,3,4,5,6,7');
  late final _extra = TextEditingController(text: moneyToInput(_s?.extraFeeMinor ?? 0));

  @override
  void dispose() {
    for (final c in [_start, _end, _cap, _days, _extra]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController c) async {
    final parts = c.text.split(':');
    final initial = TimeOfDay(hour: int.tryParse(parts.first) ?? 10, minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    final t = await showTimePicker(context: context, initialTime: initial, builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: w!));
    if (t != null) c.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<String?> _save() async {
    final l = context.l;
    final r = validateSlot(id: _s?.id, start: _start.text, end: _end.text, capacity: _cap.text, days: _days.text, extra: _extra.text, active: _active);
    if (!r.ok) return formErrorMessage(l, r.error!);
    try {
      await ref.read(deliveryRepositoryProvider).saveSlot(r.value!);
      ref.invalidate(slotsProvider);
      return null;
    } catch (e) {
      return errorMessage(l, e);
    }
  }

  Widget _time(String label, TextEditingController c, String key) => FieldBox(
        width: 150,
        child: TextFormField(
          key: ValueKey(key),
          controller: c,
          decoration: InputDecoration(labelText: label, suffixIcon: IconButton(icon: const Icon(Icons.schedule), onPressed: () => _pickTime(c))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AdminFormDialog(
      title: l.editWindow,
      formKey: _form,
      onSubmit: _save,
      children: [
        FormRow(children: [
          _time(l.fromTime, _start, 'slot-start'),
          _time(l.toTime, _end, 'slot-end'),
          TextBox(label: l.capacityLabel, controller: _cap, keyboard: TextInputType.number, width: 180),
          TextBox(label: l.daysLabel, controller: _days),
          TextBox(label: l.extraFeeLabel, controller: _extra, keyboard: const TextInputType.numberWithOptions(decimal: true), width: 180),
          SwitchBox(label: l.active, value: _active, onChanged: (v) => setState(() => _active = v)),
        ]),
      ],
    );
  }
}

// ------------------------------------------------------------------ couriers

class _CouriersCard extends ConsumerWidget {
  const _CouriersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final couriers = ref.watch(couriersProvider);
    return _Section(
      title: l.couriersTitle,
      child: AsyncBody<List<Courier>>(
        value: couriers,
        onRetry: () => ref.invalidate(couriersProvider),
        builder: (list) => DataCard(
          headers: const [],
          rows: [
            for (final c in list) [Text(c.displayName), Text(c.phone ?? ''), Text(c.active ? l.courierActive : l.courierDisabled), Text(c.trackingConsent ? l.locationOn : l.locationOff)],
          ],
          footer: MutedText(l.couriersNote),
        ),
      ),
    );
  }
}
