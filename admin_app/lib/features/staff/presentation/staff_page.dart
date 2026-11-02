import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_dialog.dart';
import '../data/staff_repository.dart';

class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});

  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> {
  String? _error;

  Future<void> _toggle(StaffRow r) async {
    final l = context.l;
    setState(() => _error = null);
    try {
      await ref.read(staffRepositoryProvider).setActive(r.id, !r.isActive);
      ref.invalidate(staffProvider);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final list = ref.watch(staffProvider);
    return PageFrame(
      title: Text(l.staff),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(key: const ValueKey('new'), onPressed: () => showDialog<bool>(context: context, builder: (_) => const StaffDialog()), icon: const Icon(Icons.add), label: Text(l.create)),
          ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: ErrorBox(message: _error!)),
        AsyncBody<List<StaffRow>>(
          value: list,
          onRetry: () => ref.invalidate(staffProvider),
          builder: (data) => DataCard(
            headers: [l.colName, l.colEmail, l.colRole, l.colStatus, ''],
            rows: [
              for (final r in data)
                [
                  Text(r.fullName),
                  Text(r.email),
                  Text(roleLabel(l, r.role)),
                  Text(userStatusLabel(l, r.status)),
                  OutlinedButton(key: ValueKey('toggle-${r.id}'), onPressed: () => _toggle(r), child: Text(r.isActive ? l.disable : l.enable)),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class StaffDialog extends ConsumerStatefulWidget {
  const StaffDialog({super.key});
  @override
  ConsumerState<StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<StaffDialog> {
  final _form = GlobalKey<FormState>();
  String _role = 'MANAGER';
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    for (final c in [_email, _name, _phone, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _save() async {
    final l = context.l;
    final r = validateStaff(email: _email.text, fullName: _name.text, password: _pw.text, role: _role, phone: _phone.text);
    if (!r.ok) return formErrorMessage(l, r.error!);
    try {
      await ref.read(staffRepositoryProvider).create(r.value!);
      ref.invalidate(staffProvider);
      return null;
    } catch (e) {
      return errorMessage(l, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AdminFormDialog(
      title: l.newStaff,
      formKey: _form,
      onSubmit: _save,
      submitLabel: l.create,
      children: [
        FormRow(children: [
          TextBox(label: l.email, controller: _email, required: true, keyboard: TextInputType.emailAddress),
          TextBox(label: l.fullName, controller: _name, required: true),
          TextBox(label: l.phone, controller: _phone, keyboard: TextInputType.phone),
          FieldBox(
            child: DropdownButtonFormField<String>(
              key: const ValueKey('role'),
              isExpanded: true,
              initialValue: _role,
              decoration: InputDecoration(labelText: l.role),
              items: [for (final r in staffRoles) DropdownMenuItem(value: r, child: Text(roleLabel(l, r)))],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
          ),
          TextBox(label: l.passwordMin, controller: _pw, required: true, obscure: true, autofillHints: const [AutofillHints.newPassword]),
        ]),
      ],
    );
  }
}
