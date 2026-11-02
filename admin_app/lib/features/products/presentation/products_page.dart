import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_dialog.dart';
import '../data/catalog_admin_repository.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  ProductQuery _q = const ProductQuery();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _q = ProductQuery(q: v.trim())));
  }

  Future<void> _open(AdminProduct? p, List<AdminCategory> cats) =>
      showDialog<bool>(context: context, builder: (_) => ProductDialog(initial: p, categories: cats));

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cats = ref.watch(categoriesProvider).value ?? const <AdminCategory>[];
    final list = ref.watch(productsProvider(_q));
    return PageFrame(
      title: Text(l.products),
      children: [
        FormRow(children: [
          FieldBox(child: TextField(key: const ValueKey('search'), decoration: InputDecoration(labelText: l.search), onChanged: _search)),
          FilledButton.icon(key: const ValueKey('new'), onPressed: cats.isEmpty ? null : () => _open(null, cats), icon: const Icon(Icons.add), label: Text(l.newItem)),
        ]),
        AsyncBody<Paged<AdminProduct>>(
          value: list,
          onRetry: () => ref.invalidate(productsProvider),
          builder: (data) => data.items.isEmpty
              ? const EmptyNote()
              : DataCard(
                  headers: [l.colSku, l.colName, l.colPrice, l.colStock, l.colActive, ''],
                  rows: [
                    for (final p in data.items)
                      [
                        Text(p.sku),
                        Text(p.nameRu),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: context.money(p.priceMinor)),
                          if (p.oldPriceMinor != null)
                            TextSpan(text: ' ${context.money(p.oldPriceMinor!)}', style: TextStyle(decoration: TextDecoration.lineThrough, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ])),
                        Text('${context.qty(p.stockMilli)} / ${context.qty(p.reservedMilli)}'),
                        BoolMark(p.active),
                        TextButton(key: ValueKey('edit-${p.id}'), onPressed: () => _open(p, cats), child: Text(l.edit)),
                      ],
                  ],
                  footer: Align(alignment: Alignment.centerLeft, child: Pager(page: data.page, totalPages: data.totalPages, onPage: (p) => setState(() => _q = ProductQuery(q: _q.q, page: p)))),
                ),
        ),
      ],
    );
  }
}

class ProductDialog extends ConsumerStatefulWidget {
  const ProductDialog({super.key, this.initial, required this.categories});
  final AdminProduct? initial;
  final List<AdminCategory> categories;

  @override
  ConsumerState<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<ProductDialog> {
  final _form = GlobalKey<FormState>();
  late final AdminProduct? _p = widget.initial;
  late String _categoryId = _p?.categoryId ?? widget.categories.first.id!;
  late String _unit = _p?.unit ?? 'PIECE';
  late bool _weighted = _p?.weighted ?? false;
  late bool _active = _p?.active ?? true;
  late final _sku = TextEditingController(text: _p?.sku);
  late final _brand = TextEditingController(text: _p?.brand);
  late final _nameRu = TextEditingController(text: _p?.nameRu);
  late final _nameKk = TextEditingController(text: _p?.nameKk);
  late final _nameEn = TextEditingController(text: _p?.nameEn);
  late final _descRu = TextEditingController(text: _p?.descriptionRu);
  late final _descKk = TextEditingController(text: _p?.descriptionKk);
  late final _descEn = TextEditingController(text: _p?.descriptionEn);
  late final _step = TextEditingController(text: '${_p?.stepMilli ?? 1000}');
  late final _pack = TextEditingController(text: _p?.packLabel);
  late final _price = TextEditingController(text: _p == null ? '' : moneyToInput(_p.priceMinor));
  late final _old = TextEditingController(text: _p?.oldPriceMinor == null ? '' : moneyToInput(_p!.oldPriceMinor!));
  late final _image = TextEditingController(text: _p?.imageUrl);
  final _delta = TextEditingController();
  final _reason = TextEditingController();
  String? _stockError;

  @override
  void dispose() {
    for (final c in [_sku, _brand, _nameRu, _nameKk, _nameEn, _descRu, _descKk, _descEn, _step, _pack, _price, _old, _image, _delta, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _save() async {
    final l = context.l;
    final r = ProductInput(
      id: _p?.id,
      categoryId: _categoryId,
      sku: _sku.text,
      brand: _brand.text,
      nameRu: _nameRu.text,
      nameKk: _nameKk.text,
      nameEn: _nameEn.text,
      descriptionRu: _descRu.text,
      descriptionKk: _descKk.text,
      descriptionEn: _descEn.text,
      unit: _unit,
      weighted: _weighted,
      stepText: _step.text,
      packLabel: _pack.text,
      priceText: _price.text,
      oldPriceText: _old.text,
      imageUrl: _image.text,
      lowStockMilli: _p?.lowStockMilli ?? 5000,
      active: _active,
    ).toBody();
    if (!r.ok) return formErrorMessage(l, r.error!);
    try {
      await ref.read(catalogAdminRepositoryProvider).saveProduct(_p?.id, r.value!);
      ref.invalidate(productsProvider);
      return null;
    } catch (e) {
      return errorMessage(l, e);
    }
  }

  Future<void> _adjust() async {
    final l = context.l;
    final r = validateStockAdjustment(_delta.text, _reason.text);
    if (!r.ok) {
      setState(() => _stockError = formErrorMessage(l, r.error!));
      return;
    }
    try {
      await ref.read(catalogAdminRepositoryProvider).adjustStock(_p!.id!, r.value!.delta, r.value!.reason);
      ref.invalidate(productsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _stockError = errorMessage(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AdminFormDialog(
      title: _p == null ? l.newProduct : l.editProduct,
      formKey: _form,
      onSubmit: _save,
      children: [
        FormRow(children: [
          TextBox(label: l.colSku, controller: _sku, required: true),
          FieldBox(
            child: DropdownButtonFormField<String>(
              key: const ValueKey('category'),
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.category),
              items: [for (final c in widget.categories) DropdownMenuItem(value: c.id, child: Text(c.nameRu))],
              onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
            ),
          ),
          TextBox(label: l.brand, controller: _brand),
        ]),
        FormRow(children: [
          TextBox(label: l.nameRu, controller: _nameRu, required: true),
          TextBox(label: l.nameKk, controller: _nameKk, required: true),
          TextBox(label: l.nameEn, controller: _nameEn, required: true),
        ]),
        FormRow(children: [
          TextBox(label: l.descriptionRu, controller: _descRu, maxLines: 3),
          TextBox(label: l.descriptionKk, controller: _descKk, maxLines: 3),
          TextBox(label: l.descriptionEn, controller: _descEn, maxLines: 3),
        ]),
        FormRow(children: [
          FieldBox(
            child: DropdownButtonFormField<String>(
              key: const ValueKey('unit'),
              isExpanded: true,
              initialValue: _unit,
              decoration: InputDecoration(labelText: l.unit),
              items: [for (final u in productUnits) DropdownMenuItem(value: u, child: Text(unitLabel(l, u)))],
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
          ),
          SwitchBox(label: l.soldByWeight, value: _weighted, onChanged: (v) => setState(() => _weighted = v)),
          TextBox(label: l.stepMilli, controller: _step, keyboard: TextInputType.number),
          TextBox(label: l.packLabel, controller: _pack),
        ]),
        FormRow(children: [
          TextBox(label: l.priceLabel, controller: _price, required: true, keyboard: const TextInputType.numberWithOptions(decimal: true)),
          TextBox(label: l.previousPrice, controller: _old, keyboard: const TextInputType.numberWithOptions(decimal: true)),
          TextBox(label: l.imageUrl, controller: _image),
          SwitchBox(label: l.active, value: _active, onChanged: (v) => setState(() => _active = v)),
        ]),
        if (_p?.id != null) ...[
          const Divider(),
          Text(l.stockSummary(context.qty(_p!.stockMilli), context.qty(_p.reservedMilli))),
          const SizedBox(height: Space.s),
          FormRow(children: [
            TextBox(label: l.adjustBy, controller: _delta, validator: (_) => null),
            TextBox(label: l.reason, controller: _reason, validator: (_) => null),
            OutlinedButton(key: const ValueKey('adjust'), onPressed: _adjust, child: Text(l.applyAdjustment)),
          ]),
          FormErrorText(_stockError),
        ],
      ],
    );
  }
}
