import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/theme/tokens.dart';

/// Bottom sheet to pick the delivery address (or add one). Signed-out users are sent to login.
Future<void> showAddressSheet(BuildContext context, WidgetRef ref) async {
  if (ref.read(authProvider).value == null) {
    context.push('/login');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    builder: (ctx) => Consumer(builder: (ctx, ref, _) {
      final l = ctx.l;
      final list = ref.watch(addressesProvider).value ?? const [];
      final selected = ref.watch(selectedAddressProvider);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.deliveryAddress, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: Space.s),
            RadioGroup<String>(
              groupValue: selected?.id,
              onChanged: (v) {
                if (v == null) return;
                ref.read(selectedAddressIdProvider.notifier).select(v);
                Navigator.pop(ctx);
              },
              child: Column(children: [
                for (final a in list)
                  RadioListTile<String>(
                    value: a.id,
                    title: Text('${a.city}, ${a.oneLine}'),
                    subtitle: a.isDefault ? Text(l.defaultAddress) : null,
                  ),
              ]),
            ),
            const SizedBox(height: Space.s),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/profile/addresses/new');
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(l.addAddress),
            ),
          ]),
        ),
      );
    }),
  );
}
