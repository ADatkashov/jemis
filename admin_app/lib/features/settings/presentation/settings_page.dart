import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';

/// Only changed values are sent (as in the old admin); the server validates every key.
Map<String, String> changedSettings(Map<String, String> original, Map<String, String> edits) =>
    {for (final e in edits.entries) if (original[e.key] != e.value) e.key: e.value};

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _edits = <String, String>{};
  final _controllers = <String, TextEditingController>{};
  String _msg = '';
  bool _isError = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(Map<String, String> original) async {
    final l = context.l;
    final changed = changedSettings(original, _edits);
    try {
      await ref.read(settingsRepositoryProvider).save(changed);
      _edits.clear();
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      ref.invalidate(settingsProvider);
      if (mounted) {
        setState(() {
          _msg = l.saved;
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _msg = errorMessage(l, e);
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final settings = ref.watch(settingsProvider);
    return PageFrame(
      title: Text(l.settings),
      children: [
        AsyncBody<Map<String, String>>(
          value: settings,
          onRetry: () => ref.invalidate(settingsProvider),
          builder: (data) {
            final dirty = changedSettings(data, _edits).isNotEmpty;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in data.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.m),
                      child: Wrap(spacing: Space.l, runSpacing: Space.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        SizedBox(
                          width: 420,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                            MutedText(settingHelp(l, e.key)),
                          ]),
                        ),
                        SizedBox(
                          width: 260,
                          child: TextField(
                            key: ValueKey('setting-${e.key}'),
                            controller: _controllers.putIfAbsent(e.key, () => TextEditingController(text: e.value)),
                            decoration: InputDecoration(labelText: e.key),
                            onChanged: (v) => setState(() => _edits[e.key] = v),
                          ),
                        ),
                      ]),
                    ),
                  Wrap(spacing: Space.m, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    FilledButton(key: const ValueKey('save'), onPressed: dirty ? () => _save(data) : null, child: Text(l.save)),
                    if (_msg.isNotEmpty) Semantics(liveRegion: true, child: Text(_msg, style: _isError ? TextStyle(color: Theme.of(context).colorScheme.error) : null)),
                  ]),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }
}
