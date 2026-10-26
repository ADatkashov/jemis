import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../auth/presentation/auth_screens.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final profile = ref.watch(authProvider).value;
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.profileTitle)),
        body: Column(children: [
          Expanded(child: SignInPrompt(icon: Icons.person_outline, onSignIn: () => context.push('/login'))),
          Padding(padding: const EdgeInsets.all(Space.l), child: _LanguagePicker()),
        ]),
      );
    }
    Widget tile(IconData icon, String title, String route, {Widget? trailing}) => ListTile(leading: Icon(icon), title: Text(title), trailing: trailing ?? const Icon(Icons.chevron_right), onTap: () => context.push(route));
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: ListView(padding: const EdgeInsets.all(Space.l), children: [
        Row(children: [
          CircleAvatar(radius: 28, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(profile.fullName.isEmpty ? '?' : profile.fullName[0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onPrimaryContainer))),
          const SizedBox(width: Space.m),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile.fullName, style: Theme.of(context).textTheme.titleLarge), Text(profile.email ?? profile.phone ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])),
        ]),
        const SizedBox(height: Space.l),
        Card(child: Column(children: [
          tile(Icons.receipt_long_outlined, l.ordersTitle, '/orders'),
          tile(Icons.location_on_outlined, l.addresses, '/profile/addresses'),
          tile(Icons.favorite_border, l.favorites, '/profile/favorites'),
          tile(Icons.notifications_none, l.notifications, '/profile/notifications', trailing: unread > 0 ? Badge(label: Text('$unread')) : const Icon(Icons.chevron_right)),
          tile(Icons.edit_outlined, l.editProfile, '/profile/edit'),
        ])),
        const SizedBox(height: Space.l),
        _LanguagePicker(),
        const SizedBox(height: Space.l),
        OutlinedButton(onPressed: () => ref.read(authProvider.notifier).logout(), child: Text(l.logout)),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(content: Text(l.deleteAccountConfirm), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.deleteAccount))]));
            if (ok == true) {
              try {
                await ref.read(profileRepositoryProvider).requestAccountDeletion();
                await ref.read(authProvider.notifier).logout();
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            }
          },
          child: Text(l.deleteAccount),
        ),
      ]),
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final current = ref.watch(localeProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.language, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: Space.s),
      SegmentedButton<String>(
        segments: const [ButtonSegment(value: 'ru', label: Text('Русский')), ButtonSegment(value: 'kk', label: Text('Қазақша')), ButtonSegment(value: 'en', label: Text('English'))],
        selected: {current.languageCode},
        onSelectionChanged: (s) async {
          await ref.read(localeProvider.notifier).set(Locale(s.first));
          if (ref.read(authProvider).value != null) {
            try {
              await ref.read(authProvider.notifier).syncLocale();
            } catch (_) {/* preference sync is best effort */}
          }
        },
      ),
    ]);
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final _name = TextEditingController(text: ref.read(authProvider).value?.fullName);
  late final _phone = TextEditingController(text: ref.read(authProvider).value?.phone);
  late bool _orders = ref.read(authProvider).value?.notifyOrders ?? true;
  late bool _promos = ref.read(authProvider).value?.notifyPromos ?? false;
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(Space.l), children: [
          TextFormField(controller: _name, decoration: InputDecoration(labelText: l.fullName), validator: (v) => Validators.required(v, l.fieldRequired)),
          const SizedBox(height: Space.m),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l.phone), validator: (v) => (v == null || v.trim().isEmpty || Validators.isPhone(v)) ? null : l.invalidPhone),
          const SizedBox(height: Space.m),
          SwitchListTile(title: Text(l.notifyOrders), value: _orders, onChanged: (v) => setState(() => _orders = v)),
          SwitchListTile(title: Text(l.notifyPromos), value: _promos, onChanged: (v) => setState(() => _promos = v)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: Space.l), child: Text(l.pushNotConfigured, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(height: Space.l),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() => _busy = true);
                    try {
                      await ref.read(authProvider.notifier).updateProfile(fullName: _name.text.trim(), phone: _phone.text.trim(), notifyOrders: _orders, notifyPromos: _promos);
                      if (context.mounted) context.pop();
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: Text(l.save),
          ),
        ]),
      ),
    );
  }
}

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final list = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.addresses)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/profile/addresses/new'), icon: const Icon(Icons.add), label: Text(l.addAddress)),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(addressesProvider)),
        data: (items) => items.isEmpty
            ? EmptyView(icon: Icons.location_off_outlined, title: l.addAddressFirst, actionLabel: l.addAddress, onAction: () => context.push('/profile/addresses/new'))
            : ListView(padding: const EdgeInsets.all(Space.l), children: [
                for (final a in items)
                  Card(
                    child: ListTile(
                      title: Text('${a.city}, ${a.oneLine}'),
                      subtitle: Text([if (a.isDefault) l.defaultAddress, if (a.label != null) a.label!].join(' · ')),
                      onTap: () => context.push('/profile/addresses/${a.id}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          try {
                            if (v == 'default') await ref.read(addressesProvider.notifier).makeDefault(a.id);
                            if (v == 'delete') await ref.read(addressesProvider.notifier).remove(a.id);
                          } catch (e) {
                            if (context.mounted) showError(context, e);
                          }
                        },
                        itemBuilder: (_) => [if (!a.isDefault) PopupMenuItem(value: 'default', child: Text(l.makeDefault)), PopupMenuItem(value: 'delete', child: Text(l.delete))],
                      ),
                    ),
                  ),
              ]),
      ),
    );
  }
}

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});
  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{for (final k in ['label', 'city', 'street', 'house', 'apartment', 'entrance', 'floor', 'intercom', 'recipientName', 'recipientPhone', 'instructions']) k: TextEditingController()};
  bool _default = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.addressId == null ? null : (ref.read(addressesProvider).value ?? const <Address>[]).where((a) => a.id == widget.addressId).firstOrNull;
    _c['city']!.text = existing?.city ?? 'Алматы';
    if (existing != null) {
      _c['label']!.text = existing.label ?? '';
      _c['street']!.text = existing.street;
      _c['house']!.text = existing.house;
      _c['apartment']!.text = existing.apartment ?? '';
      _c['entrance']!.text = existing.entrance ?? '';
      _c['floor']!.text = existing.floor ?? '';
      _c['intercom']!.text = existing.intercom ?? '';
      _c['recipientName']!.text = existing.recipientName ?? '';
      _c['recipientPhone']!.text = existing.recipientPhone ?? '';
      _c['instructions']!.text = existing.instructions ?? '';
      _default = existing.isDefault;
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final input = AddressInput(
      city: _c['city']!.text, street: _c['street']!.text, house: _c['house']!.text, label: _c['label']!.text, apartment: _c['apartment']!.text,
      entrance: _c['entrance']!.text, floor: _c['floor']!.text, intercom: _c['intercom']!.text, recipientName: _c['recipientName']!.text,
      recipientPhone: _c['recipientPhone']!.text, instructions: _c['instructions']!.text, isDefault: _default,
    );
    try {
      final n = ref.read(addressesProvider.notifier);
      if (widget.addressId == null) {
        final a = await n.add(input);
        ref.read(selectedAddressIdProvider.notifier).select(a.id);
      } else {
        await n.edit(widget.addressId!, input);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    String? req(String? v) => Validators.required(v, l.fieldRequired);
    Widget f(String key, String label, {bool required = false, TextInputType? type, int lines = 1}) => Padding(
          padding: const EdgeInsets.only(bottom: Space.m),
          child: TextFormField(controller: _c[key], decoration: InputDecoration(labelText: label), keyboardType: type, maxLines: lines, validator: required ? req : null),
        );
    return Scaffold(
      appBar: AppBar(title: Text(widget.addressId == null ? l.addAddress : l.editAddress)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(Space.l), children: [
          f('city', l.city, required: true),
          f('street', l.street, required: true),
          Row(children: [Expanded(child: f('house', l.house, required: true)), const SizedBox(width: Space.m), Expanded(child: f('apartment', l.apartment))]),
          Row(children: [Expanded(child: f('entrance', l.entrance)), const SizedBox(width: Space.m), Expanded(child: f('floor', l.floor)), const SizedBox(width: Space.m), Expanded(child: f('intercom', l.intercom))]),
          f('recipientName', l.recipient),
          f('recipientPhone', l.recipientPhone, type: TextInputType.phone),
          f('instructions', l.instructions, lines: 2),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.makeDefault), value: _default, onChanged: (v) => setState(() => _default = v)),
          const SizedBox(height: Space.m),
          FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
        ]),
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final favs = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.favorites)),
      body: favs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(favoritesProvider)),
        data: (items) => items.isEmpty
            ? EmptyView(icon: Icons.favorite_border, title: l.noFavorites)
            : GridView.builder(
                padding: const EdgeInsets.all(Space.l),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: Space.m, crossAxisSpacing: Space.m, childAspectRatio: 0.62),
                itemCount: items.length,
                itemBuilder: (_, i) => ProductCard(product: items[i]),
              ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the list marks everything as read.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(profileRepositoryProvider).markAllRead();
        ref.invalidate(unreadCountProvider);
      } catch (_) {/* best effort */}
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final n = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.notifications)),
      body: n.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(notificationsProvider)),
        data: (page) => page.items.isEmpty
            ? EmptyView(icon: Icons.notifications_none, title: l.noNotifications, hint: l.pushNotConfigured)
            : ListView.separated(
                padding: const EdgeInsets.all(Space.l),
                itemCount: page.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.s),
                itemBuilder: (_, i) {
                  final x = page.items[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(x.read ? Icons.notifications_none : Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
                      title: Text(x.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${x.body}\n${DateFormat.MMMd(context.localeName).add_Hm().format(x.createdAt)}'),
                      isThreeLine: true,
                      onTap: x.orderId == null ? null : () => context.push('/orders/${x.orderId}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
