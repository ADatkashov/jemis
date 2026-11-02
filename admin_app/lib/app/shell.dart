import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_x.dart';
import '../core/theme/tokens.dart';
import 'nav.dart';
import 'providers.dart';

const _wideBreakpoint = 900.0;

/// Side navigation on desktop widths; a drawer behind an app bar on narrow windows.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final nav = SideNav(location: location);
    if (wide) {
      return Scaffold(body: Row(children: [SizedBox(width: 240, child: nav), Expanded(child: child)]));
    }
    return Scaffold(
      appBar: AppBar(title: Text(navItemFor(location)?.label(context.l) ?? context.l.appName)),
      drawer: Drawer(backgroundColor: JemisColors.deep, child: SafeArea(child: nav)),
      body: child,
    );
  }
}

class SideNav extends ConsumerWidget {
  const SideNav({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final auth = ref.watch(authProvider);
    final current = navItemFor(location);
    final locale = ref.watch(localeProvider);
    return Material(
      color: JemisColors.deep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.m),
            child: Text('JEMIS', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Space.s),
              children: [
                for (final item in navItemsFor(auth.role))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      key: ValueKey('nav-${item.id}'),
                      dense: true,
                      selected: item == current,
                      selectedTileColor: JemisColors.primaryStrong,
                      selectedColor: Colors.white,
                      textColor: Colors.white,
                      iconColor: Colors.white70,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(item.icon),
                      title: Text(item.label(l)),
                      onTap: () {
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) Navigator.of(context).pop();
                        context.go(item.path);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.m),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Theme(
                data: Theme.of(context).copyWith(canvasColor: JemisColors.deep),
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('lang'),
                  initialValue: locale.languageCode,
                  isDense: true,
                  dropdownColor: JemisColors.deep,
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: l.language,
                    labelStyle: const TextStyle(color: Colors.white70),
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ru', child: Text('Русский')),
                    DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) {
                    if (v != null) ref.read(localeProvider.notifier).set(Locale(v));
                  },
                ),
              ),
              const SizedBox(height: Space.s),
              OutlinedButton.icon(
                key: const ValueKey('logout'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: Text(l.logout),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
