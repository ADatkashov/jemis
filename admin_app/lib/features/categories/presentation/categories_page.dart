import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../products/data/catalog_admin_repository.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final list = ref.watch(categoriesProvider);
    final all = list.value ?? const <AdminCategory>[];
    Future<void> open(AdminCategory? c) => showDialog<bool>(context: context, builder: (_) => CategoryDialog(initial: c, all: all));
    return PageFrame(
      title: Text(l.categories),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(alignment: Alignment.centerLeft, child: FilledButton.icon(key: const ValueKey('new'), onPressed: () => open(null), icon: const Icon(Icons.add), label: Text(l.newItem))),
        ),
        AsyncBody<List<AdminCategory>>(
          value: list,
          onRetry: () => ref.invalidate(categoriesProvider),
          builder: (data) => DataCard(
            headers: [l.sortOrder, l.colSlug, '${l.nameRu} / ${l.nameKk} / ${l.nameEn}', l.colActive, ''],
            rows: [
              for (final x in data)
                [
                  Text('${x.sortOrder}'),
                  Text(x.slug),
                  Text('${x.nameRu} / ${x.nameKk} / ${x.nameEn}'),
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

class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({super.key, this.initial, required this.all});
  final AdminCategory? initial;
  final List<AdminCategory> all;

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final AdminCategory? _c = widget.initial;
  late String? _parent = widget.all.any((x) => x.id == _c?.parentId) ? _c?.parentId : null;
  late bool _active = _c?.active ?? true;
  late final _slug = TextEditingController(text: _c?.slug);
  late final _icon = TextEditingController(text: _c?.icon);
  late final _sort = TextEditingController(text: '${_c?.sortOrder ?? 0}');
  late final _ru = TextEditingController(text: _c?.nameRu);
  late final _kk = TextEditingController(text: _c?.nameKk);
  late final _en = TextEditingController(text: _c?.nameEn);

  @override
  void dispose() {
    for (final c in [_slug, _icon, _sort, _ru, _kk, _en]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _save() async {
    final l = context.l;
    final r = validateCategory(
      id: _c?.id,
      parentId: _parent,
      slug: _slug.text,
      nameRu: _ru.text,
      nameKk: _kk.text,
      nameEn: _en.text,
      icon: _icon.text,
      imageUrl: _c?.imageUrl,
      sortOrder: _sort.text,
      active: _active,
    );
    if (!r.ok) return formErrorMessage(l, r.error!);
    try {
      await ref.read(catalogAdminRepositoryProvider).saveCategory(r.value!);
      ref.invalidate(categoriesProvider);
      return null;
    } catch (e) {
      return errorMessage(l, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AdminFormDialog(
      title: _c == null ? l.newCategory : l.editCategory,
      formKey: _form,
      onSubmit: _save,
      children: [
        FormRow(children: [
          TextBox(label: l.slugLabel, controller: _slug, required: true),
          FieldBox(
            child: DropdownButtonFormField<String?>(
              key: const ValueKey('parent'),
              initialValue: _parent,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.parent),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                for (final x in widget.all.where((x) => x.id != _c?.id)) DropdownMenuItem<String?>(value: x.id, child: Text(x.nameRu)),
              ],
              onChanged: (v) => setState(() => _parent = v),
            ),
          ),
          TextBox(label: l.iconKey, controller: _icon),
          TextBox(label: l.sortOrder, controller: _sort, keyboard: TextInputType.number),
          SwitchBox(label: l.active, value: _active, onChanged: (v) => setState(() => _active = v)),
        ]),
        FormRow(children: [
          TextBox(label: l.nameRu, controller: _ru, required: true),
          TextBox(label: l.nameKk, controller: _kk, required: true),
          TextBox(label: l.nameEn, controller: _en, required: true),
        ]),
      ],
    );
  }
}
