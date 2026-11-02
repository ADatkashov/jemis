import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// One sidebar entry. The list is data so it can be unit-tested without building widgets.
class NavItem {
  const NavItem(this.path, this.id, this.icon, {this.adminOnly = false});
  final String path;
  final String id;
  final IconData icon;
  final bool adminOnly;

  String label(AppL10n l) => switch (id) {
        'dashboard' => l.dashboard,
        'orders' => l.orders,
        'products' => l.products,
        'categories' => l.categories,
        'delivery' => l.delivery,
        'promotions' => l.promotions,
        'customers' => l.customers,
        'staff' => l.staff,
        'settings' => l.settings,
        'audit' => l.audit,
        _ => id,
      };
}

const allNavItems = [
  NavItem('/', 'dashboard', Icons.dashboard_outlined),
  NavItem('/orders', 'orders', Icons.receipt_long_outlined),
  NavItem('/products', 'products', Icons.inventory_2_outlined),
  NavItem('/categories', 'categories', Icons.category_outlined),
  NavItem('/delivery', 'delivery', Icons.local_shipping_outlined),
  NavItem('/promotions', 'promotions', Icons.sell_outlined),
  NavItem('/customers', 'customers', Icons.people_outline),
  NavItem('/staff', 'staff', Icons.badge_outlined, adminOnly: true),
  NavItem('/settings', 'settings', Icons.settings_outlined, adminOnly: true),
  NavItem('/audit', 'audit', Icons.history, adminOnly: true),
];

/// Staff, settings and the audit log are visible to ADMIN only (the server enforces it as well).
List<NavItem> navItemsFor(String? role) => [for (final i in allNavItems) if (!i.adminOnly || role == 'ADMIN') i];

/// The sidebar entry that owns [location] (e.g. `/orders/42` belongs to `/orders`), or null.
NavItem? navItemFor(String location) {
  if (location == '/') return allNavItems.first;
  for (final i in allNavItems.skip(1)) {
    if (location == i.path || location.startsWith('${i.path}/')) return i;
  }
  return null;
}
