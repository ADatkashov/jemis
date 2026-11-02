import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n_x.dart';
import '../theme/tokens.dart';

/// Page frame: title row (with optional actions) above scrolling content, capped to a readable width on wide screens.
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, this.actions = const [], required this.children});
  final Widget title;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.xl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Space.m,
                runSpacing: Space.s,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [DefaultTextStyle.merge(style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800), child: title), ...actions],
              ),
              const SizedBox(height: Space.l),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: Space.m),
          Text(context.l.loading),
        ]),
      );
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: Space.m, runSpacing: Space.s, children: [
            Icon(Icons.error_outline, color: cs.error),
            Text(message, style: TextStyle(color: cs.error)),
            if (onRetry != null) OutlinedButton(onPressed: onRetry, child: Text(context.l.retry)),
          ]),
        ),
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(Space.l), child: Text(context.l.empty, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
}

/// Renders an [AsyncValue] with the app's loading / error (with retry) states. While refreshing, the old data stays.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.builder, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue && !value.hasError) return builder(value.requireValue);
    if (value.hasError) return ErrorBox(message: errorMessage(context.l, value.error!), onRetry: onRetry);
    return const Loading();
  }
}

class MutedText extends StatelessWidget {
  const MutedText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
}

/// Data table in a card; scrolls horizontally when the window is narrower than the table.
class DataCard extends StatelessWidget {
  const DataCard({super.key, required this.headers, required this.rows, this.footer});
  final List<String> headers;
  final List<List<Widget>> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                headingRowHeight: headers.isEmpty ? 0 : 44,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 72,
                columnSpacing: Space.xl,
                columns: [for (final h in (headers.isEmpty ? List.filled(rows.isEmpty ? 1 : rows.first.length, '') : headers)) DataColumn(label: Text(h))],
                rows: [for (final r in rows) DataRow(cells: [for (final c in r) DataCell(c)])],
              ),
            ),
          ),
        ),
        if (footer != null) Padding(padding: const EdgeInsets.all(Space.m), child: footer),
      ]),
    );
  }
}

class Pager extends StatelessWidget {
  const Pager({super.key, required this.page, required this.totalPages, required this.onPage});
  final int page, totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(tooltip: context.l.prevPage, onPressed: page == 0 ? null : () => onPage(page - 1), icon: const Icon(Icons.chevron_left)),
      Text(context.l.pageOf('${page + 1}', '$totalPages')),
      IconButton(tooltip: context.l.nextPage, onPressed: page + 1 >= totalPages ? null : () => onPage(page + 1), icon: const Icon(Icons.chevron_right)),
    ]);
  }
}

class Badge2 extends StatelessWidget {
  const Badge2(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 2),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
    );
  }
}

/// Tick / dash for boolean columns.
class BoolMark extends StatelessWidget {
  const BoolMark(this.value, {super.key});
  final bool value;
  @override
  Widget build(BuildContext context) => Text(value ? '✓' : '—', semanticsLabel: value ? context.l.active : context.l.none);
}

/// Wide form field that fills its row slot; use inside [FormRow].
class FormRow extends StatelessWidget {
  const FormRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.m),
        child: Wrap(spacing: Space.m, runSpacing: Space.m, children: children),
      );
}

class FieldBox extends StatelessWidget {
  const FieldBox({super.key, required this.child, this.width = 240});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}

/// Inline error under a form (role=alert for screen readers).
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.s),
      child: Semantics(liveRegion: true, child: Text(message!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String message) async {
  final l = context.l;
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.confirm)),
      ],
    ),
  );
  return r ?? false;
}

/// Picks a date and time; shows "—" when empty and offers a clear button.
class DateTimeField extends StatelessWidget {
  const DateTimeField({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: value ?? now, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d == null || !context.mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value ?? now));
    if (t == null) return;
    onChanged(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(children: [
        Expanded(child: Text(value == null ? context.l.none : context.dateTime(value))),
        IconButton(tooltip: context.l.pickDateTime, onPressed: () => _pick(context), icon: const Icon(Icons.event)),
        if (value != null) IconButton(tooltip: context.l.clear, onPressed: () => onChanged(null), icon: const Icon(Icons.clear)),
      ]),
    );
  }
}

/// Text field validators backed by localized messages.
String? requiredValidator(BuildContext context, String? v) => (v == null || v.trim().isEmpty) ? context.l.requiredField : null;
