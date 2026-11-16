import 'package:flutter/material.dart';

/// Roles an employee can have. Owner exists only as a permission template.
enum StaffRole { manager, cashier, warehouse, driver }

extension StaffRoleInfo on StaffRole {
  /// Name used on chips and filters.
  String get label => switch (this) {
    StaffRole.manager => 'Manager',
    StaffRole.cashier => 'Cashier',
    StaffRole.warehouse => 'Warehouse',
    StaffRole.driver => 'Delivery Driver',
  };

  /// Plural name used on the Staff filter chips.
  String get plural => switch (this) {
    StaffRole.manager => 'Managers',
    StaffRole.cashier => 'Cashiers',
    StaffRole.warehouse => 'Warehouse',
    StaffRole.driver => 'Drivers',
  };

  /// One-line description on the role cards of Add / Edit Staff.
  String get description => switch (this) {
    StaffRole.manager =>
      'Full shift supervision, approvals & refunds up to \$1,000.',
    StaffRole.cashier =>
      'Ring sales, accept payments, print receipts, draft quotes.',
    StaffRole.warehouse =>
      'Receive stock, PO auditing, inventory adjustments, dock log.',
    StaffRole.driver =>
      'Route navigation, dispatch, delivery signature & customer proof.',
  };

  IconData get icon => switch (this) {
    StaffRole.manager => Icons.manage_accounts_outlined,
    StaffRole.cashier => Icons.point_of_sale_outlined,
    StaffRole.warehouse => Icons.inventory_2_outlined,
    StaffRole.driver => Icons.local_shipping_outlined,
  };

  /// Permission template matching this role.
  PermissionTemplate get template => switch (this) {
    StaffRole.manager => PermissionTemplate.manager,
    StaffRole.cashier => PermissionTemplate.cashier,
    StaffRole.warehouse => PermissionTemplate.warehouse,
    StaffRole.driver => PermissionTemplate.driver,
  };
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.title,
    required this.active,
    required this.lastActive,
    required this.location,
    required this.permissions,
    this.discountCap = 0,
    this.onShift = false,
    this.starred = false,
    this.onRoute,
    this.routeProgress,
    this.deactivatedOn,
  });

  /// Employee number, e.g. "EMP-0042".
  final String id;
  final String name;
  final String email;
  final String phone;
  final StaffRole role;

  /// Job title shown on the chip ("Store Manager", "Senior Cashier").
  final String title;
  final bool active;

  /// "14m ago", "2h ago".
  final String lastActive;

  /// Terminal or place of last activity ("Surrey Terminal 1").
  final String location;

  /// Granted permission ids (see PermissionCatalog).
  final Set<String> permissions;

  /// Max discount percent when "Give discounts" is granted.
  final int discountCap;
  final bool onShift;
  final bool starred;

  /// Drivers only: "On Route · Truck #2" while out on deliveries.
  final String? onRoute;

  /// Drivers only: "3 of 5 done".
  final String? routeProgress;
  final String? deactivatedOn;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  StaffMember copyWith({
    String? name,
    String? email,
    String? phone,
    StaffRole? role,
    String? title,
    bool? active,
    String? lastActive,
    Set<String>? permissions,
    int? discountCap,
    bool? onShift,
    String? deactivatedOn,
  }) {
    final nowActive = active ?? this.active;
    return StaffMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      title: title ?? this.title,
      active: nowActive,
      lastActive: lastActive ?? this.lastActive,
      location: location,
      permissions: permissions ?? this.permissions,
      discountCap: discountCap ?? this.discountCap,
      onShift: nowActive ? (onShift ?? this.onShift) : false,
      starred: starred,
      onRoute: nowActive ? onRoute : null,
      routeProgress: nowActive ? routeProgress : null,
      deactivatedOn: nowActive ? null : (deactivatedOn ?? this.deactivatedOn),
    );
  }
}

// ---------------- Permissions ----------------

class Permission {
  const Permission(
    this.id,
    this.label,
    this.helper, {
    this.sensitive = false,
    this.hasDiscountCap = false,
  });

  final String id;
  final String label;
  final String helper;
  final bool sensitive;

  /// "Give discounts" shows a max-percent input when granted.
  final bool hasDiscountCap;
}

class PermissionGroup {
  const PermissionGroup(this.title, this.subtitle, this.icon, this.items);

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Permission> items;
}

enum PermissionTemplate { owner, manager, cashier, warehouse, driver }

extension PermissionTemplateInfo on PermissionTemplate {
  String get label => switch (this) {
    PermissionTemplate.owner => 'Owner',
    PermissionTemplate.manager => 'Manager',
    PermissionTemplate.cashier => 'Cashier',
    PermissionTemplate.warehouse => 'Warehouse',
    PermissionTemplate.driver => 'Driver',
  };

  Set<String> get permissions => PermissionCatalog.templates[this]!;

  int get discountCap => switch (this) {
    PermissionTemplate.owner => 100,
    PermissionTemplate.manager => 25,
    PermissionTemplate.cashier => 10,
    _ => 0,
  };
}

class PermissionCatalog {
  PermissionCatalog._();

  static const List<PermissionGroup> groups = [
    PermissionGroup(
      'Sales & Reports',
      'Revenue dashboards, receipts and exports',
      Icons.point_of_sale_outlined,
      [
        Permission(
          'sales.total',
          'View total store sales',
          'Daily & cumulative showroom revenue dashboards',
        ),
        Permission(
          'sales.transactions',
          'View individual transactions',
          'Look up previous sales slips and reprint receipts',
        ),
        Permission(
          'sales.own',
          'View own sales totals',
          'Personal sales and commission for the current shift',
        ),
        Permission(
          'sales.export',
          'Export reports',
          'Download CSV / PDF register totals and commission logs',
          sensitive: true,
        ),
      ],
    ),
    PermissionGroup(
      'Money',
      'Costs, margins, refunds, discounts and pricing',
      Icons.payments_outlined,
      [
        Permission(
          'money.cost',
          'View cost prices',
          'Wholesale mattress manufacturing costs',
          sensitive: true,
        ),
        Permission(
          'money.margins',
          'View profit margins',
          'Margin % on products, orders and reports',
          sensitive: true,
        ),
        Permission(
          'money.valuation',
          'View inventory valuation',
          'Total stock value at cost across locations',
          sensitive: true,
        ),
        Permission(
          'money.refunds',
          'Process refunds',
          'Issue card reversals or store credit back to customers',
          sensitive: true,
        ),
        Permission(
          'money.void',
          'Void transactions',
          'Cancel completed invoices and roll back inventory',
          sensitive: true,
        ),
        Permission(
          'money.discounts',
          'Give discounts',
          'Apply line-item or cart-wide promotions',
          hasDiscountCap: true,
        ),
        Permission(
          'money.prices',
          'Change prices',
          'Edit selling prices on products and order lines',
          sensitive: true,
        ),
      ],
    ),
    PermissionGroup(
      'Inventory',
      'Mattress stock, pillow racks & warehouse bins',
      Icons.inventory_2_outlined,
      [
        Permission(
          'inv.edit',
          'Add / edit products',
          'Create products, variants and update details',
        ),
        Permission(
          'inv.adjust',
          'Adjust stock',
          'Record damage, recounts and manual corrections',
        ),
        Permission(
          'inv.view',
          'View stock',
          'See on-hand quantities across locations',
        ),
      ],
    ),
    PermissionGroup(
      'Customers',
      'Profiles, sleep trial dates, delivery notes',
      Icons.people_outline,
      [
        Permission(
          'cust.view',
          'View customers',
          'Customer profiles, history and contact details',
        ),
        Permission(
          'cust.edit',
          'Edit customers',
          'Update contact info, notes and addresses',
        ),
      ],
    ),
    PermissionGroup(
      'Purchasing',
      'Purchase orders and supplier receipts',
      Icons.receipt_long_outlined,
      [
        Permission(
          'po.manage',
          'View / create POs',
          'Draft and send purchase orders to suppliers',
        ),
        Permission(
          'po.receive',
          'Receive goods',
          'Check in deliveries against open purchase orders',
        ),
      ],
    ),
    PermissionGroup(
      'Deliveries',
      'Dispatch schedules, white-glove setup manifests',
      Icons.local_shipping_outlined,
      [
        Permission(
          'dlv.view',
          'View deliveries',
          'Delivery schedule, routes and proof of delivery',
        ),
        Permission(
          'dlv.assign',
          'Assign drivers',
          'Dispatch deliveries and reassign drivers',
        ),
      ],
    ),
    PermissionGroup(
      'Admin',
      'Employees, settings and audit journals',
      Icons.admin_panel_settings_outlined,
      [
        Permission(
          'admin.staff',
          'Manage employees',
          'Add, deactivate and change employee access',
          sensitive: true,
        ),
        Permission(
          'admin.settings',
          'Settings',
          'Store settings, taxes, terminals and hardware',
          sensitive: true,
        ),
        Permission(
          'admin.audit',
          'View audit logs',
          'Read the immutable owner audit journal',
          sensitive: true,
        ),
      ],
    ),
  ];

  static final List<Permission> all = [for (final g in groups) ...g.items];

  static int get total => all.length;

  static Permission byId(String id) => all.firstWhere((p) => p.id == id);

  static final Map<PermissionTemplate, Set<String>> templates = {
    PermissionTemplate.owner: {for (final p in all) p.id},
    PermissionTemplate.manager: {
      'sales.total',
      'sales.transactions',
      'sales.own',
      'sales.export',
      'money.margins',
      'money.refunds',
      'money.void',
      'money.discounts',
      'inv.edit',
      'inv.adjust',
      'inv.view',
      'cust.view',
      'cust.edit',
      'po.manage',
      'po.receive',
      'dlv.view',
      'dlv.assign',
    },
    PermissionTemplate.cashier: {
      'sales.transactions',
      'sales.own',
      'money.discounts',
      'inv.view',
      'cust.view',
      'cust.edit',
      'dlv.view',
    },
    PermissionTemplate.warehouse: {
      'inv.adjust',
      'inv.view',
      'po.manage',
      'po.receive',
      'dlv.view',
    },
    PermissionTemplate.driver: {'cust.view', 'dlv.view'},
  };
}
