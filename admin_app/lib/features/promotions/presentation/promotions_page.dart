import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_dialog.dart';
import '../data/promotions_repository.dart';

class PromotionsPage extends ConsumerWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final list = ref.watch(promotionsProvider);
    Future<void> open(Promo? p) => showDialog<bool>(context: context, builder: (_) => PromoDialog(initial: p));
    return PageFrame(
      title: Text(l.promotions),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(alignment: Alignment.centerLeft, child: FilledButton.icon(key: const ValueKey('new'), onPressed: () => open(null), icon: const Icon(Icons.add), label: Text(l.newItem))),
        ),
        AsyncBody<List<Promo>>(
          value: list,
          onRetry: () => ref.invalidate(promotionsProvider),
          builder: (data) => DataCard(
            headers: [l.colCode, l.colDiscount, l.colMinOrder, l.colUsed, l.colActive, ''],
            rows: [
              for (final x in data)
                [
                  Text(x.code),
                  Text(x.type == PromoType.percent ? '${x.value}%' : context.money(x.value)),
                  Text(context.money(x.minOrderMinor)),
                  Text('${x.usedCount}${x.usageLimit != null ? ' / ${x.usageLimit}' : ''}'),
                  BoolMark(x.active),
                  TextButton(key: ValueKey('edit-${x.id}'), onPressed: () => open(x), child: Text(l.edit)),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class PromoDialog extends ConsumerStatefulWidget {
  const PromoDialog({super.key, this.initial});
  final Promo? initial;
  @override
  ConsumerState<PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends ConsumerState<PromoDialog> {
  final _form = GlobalKey<FormState>();
  late final Promo? _p = widget.initial;
  late PromoType _type = _p?.type ?? PromoType.percent;
  late bool _stackable = _p?.stackable ?? false;
  late bool _active = _p?.active ?? true;
  late DateTime? _starts = _p?.startsAt?.toLocal();
  late DateTime? _ends = _p?.endsAt?.toLocal();
  late final _code = TextEditingController(text: _p?.code);
  late final _value = TextEditingController(text: _p == null ? '10' : (_p.type == PromoType.percent ? '${_p.value}' : moneyToInput(_p.value)));
  late final _max = TextEditingController(text: _p?.maxDiscountMinor == null ? '' : moneyToInput(_p!.maxDiscountMinor!));
  late final _min = TextEditingController(text: moneyToInput(_p?.minOrderMinor ?? 0));
  late final _uses = TextEditingController(text: _p?.usageLimit?.toString() ?? '');
  late final _perCustomer = TextEditingController(text: _p?.perCustomerLimit?.toString() ?? '');

  @override
  void dispose() {
    for (final c in [_code, _value, _max, _min, _uses, _perCustomer]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _save() async {
    final l = context.l;
    final r = validatePromo(
      id: _p?.id,
      categoryId: _p?.categoryId,
      code: _code.text,
      type: _type,
      value: _value.text,
      maxDiscount: _max.text,
      minOrder: _min.text,
      startsAt: _starts,
      endsAt: _ends,
      usageLimit: _uses.text,
      perCustomerLimit: _perCustomer.text,
      stackable: _stackable,
      active: _active,
      usedCount: _p?.usedCount ?? 0,
    );
    if (!r.ok) return formErrorMessage(l, r.error!);
    try {
      await ref.read(promotionsRepositoryProvider).save(r.value!);
      ref.invalidate(promotionsProvider);
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
      title: _p == null ? l.newPromo : l.editPromo,
      formKey: _form,
      onSubmit: _save,
      children: [
        FormRow(children: [
          TextBox(label: l.promoCode, controller: _code, required: true),
          FieldBox(
            child: DropdownButtonFormField<PromoType>(
              key: const ValueKey('promo-type'),
              isExpanded: true,
              initialValue: _type,
              decoration: InputDecoration(labelText: l.promoType),
              items: [DropdownMenuItem(value: PromoType.percent, child: Text(l.promoPercent)), DropdownMenuItem(value: PromoType.fixed, child: Text(l.promoFixed))],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ),
          TextBox(label: _type == PromoType.percent ? l.percentLabel : l.amountLabel, controller: _value, keyboard: money),
          TextBox(label: l.maxDiscountLabel, controller: _max, keyboard: money),
          TextBox(label: l.minOrderShort, controller: _min, keyboard: money),
        ]),
        FormRow(children: [
          FieldBox(width: 300, child: DateTimeField(label: l.startsAt, value: _starts, onChanged: (v) => setState(() => _starts = v))),
          FieldBox(width: 300, child: DateTimeField(label: l.endsAt, value: _ends, onChanged: (v) => setState(() => _ends = v))),
          TextBox(label: l.totalUses, controller: _uses, keyboard: TextInputType.number, width: 160),
          TextBox(label: l.perCustomer, controller: _perCustomer, keyboard: TextInputType.number, width: 160),
          SwitchBox(label: l.stackable, value: _stackable, onChanged: (v) => setState(() => _stackable = v), width: 300),
          SwitchBox(label: l.active, value: _active, onChanged: (v) => setState(() => _active = v)),
        ]),
      ],
    );
  }
}
