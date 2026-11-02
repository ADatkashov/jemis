import 'package:flutter/material.dart';

import '../l10n_x.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Modal form: validates, runs [onSubmit] (returns an error message, or null on success which closes the dialog).
class AdminFormDialog extends StatefulWidget {
  const AdminFormDialog({super.key, required this.title, required this.formKey, required this.children, required this.onSubmit, this.submitLabel, this.extraActions = const []});
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Future<String?> Function() onSubmit;
  final String? submitLabel;
  final List<Widget> extraActions;

  @override
  State<AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<AdminFormDialog> {
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.onSubmit();
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: widget.formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: Space.s),
              ...widget.children,
              FormErrorText(_error),
            ]),
          ),
        ),
      ),
      actions: [
        ...widget.extraActions,
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(l.cancel)),
        FilledButton(key: const ValueKey('submit'), onPressed: _busy ? null : _submit, child: Text(widget.submitLabel ?? l.save)),
      ],
    );
  }
}

/// Convenience: text field that fills a [FieldBox] slot.
class TextBox extends StatelessWidget {
  const TextBox({super.key, required this.label, required this.controller, this.required = false, this.width = 240, this.keyboard, this.obscure = false, this.maxLines = 1, this.validator, this.autofillHints});
  final String label;
  final TextEditingController controller;
  final bool required;
  final double width;
  final TextInputType? keyboard;
  final bool obscure;
  final int maxLines;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return FieldBox(
      width: width,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        maxLines: maxLines,
        autofillHints: autofillHints,
        decoration: InputDecoration(labelText: label),
        validator: validator ?? (required ? (v) => requiredValidator(context, v) : null),
      ),
    );
  }
}

class SwitchBox extends StatelessWidget {
  const SwitchBox({super.key, required this.label, required this.value, required this.onChanged, this.width = 240});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  @override
  Widget build(BuildContext context) => FieldBox(width: width, child: SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(label), value: value, onChanged: onChanged));
}
