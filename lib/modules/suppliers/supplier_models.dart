/// Payment terms offered on the supplier form.
const List<String> kPaymentTerms = ['COD', 'Net 15', 'Net 30', 'Net 45', 'Net 60'];

/// One month of the cost trend chart. [value] null = no purchase that month.
class CostPoint {
  const CostPoint(this.month, this.value);

  final String month;
  final double? value;
}

/// A vendor.
/// TODO(backend): replace with the real supplier model.
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.category,
    required this.contact,
    required this.phone,
    required this.email,
    required this.city,
    required this.address,
    required this.terms,
    required this.totalPurchased,
    required this.lastOrder,
    this.contactRole = 'Account Rep',
    this.specialty = '',
    this.preferred = false,
    this.leadDays = '3-5 Days',
    this.onTimePct,
    this.lifetimePos = 0,
    this.fulfilledPct = 100,
    this.notes = '',
    this.taxId = '',
    this.deliveryMode = 'Direct Dock Delivery to Surrey Flagship Whse',
    this.costLabel = '',
    this.costUnit = '',
    this.costTrend = const [],
  });

  /// "SUP-041".
  final String id;
  final String name;

  /// "Latex & Core Materials".
  final String category;
  final String contact;
  final String phone;
  final String email;

  /// "Delta, BC".
  final String city;
  final String address;

  /// "Net 30".
  final String terms;

  /// Purchased this year (CAD).
  final double totalPurchased;

  /// "Oct 22, 2024".
  final String lastOrder;
  final String contactRole;

  /// "LATEX & FOAM CORE SPECIALIST".
  final String specialty;
  final bool preferred;
  final String leadDays;
  final double? onTimePct;
  final int lifetimePos;
  final int fulfilledPct;
  final String notes;
  final String taxId;
  final String deliveryMode;

  /// "Latex Cost Trend", unit shown in the chart subtitle ("sq ft").
  final String costLabel;
  final String costUnit;
  final List<CostPoint> costTrend;

  String get initials {
    final parts = contact.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Supplier copyWith({
    String? name,
    String? category,
    String? contact,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? terms,
    String? notes,
  }) =>
      Supplier(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        contact: contact ?? this.contact,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        city: city ?? this.city,
        address: address ?? this.address,
        terms: terms ?? this.terms,
        totalPurchased: totalPurchased,
        lastOrder: lastOrder,
        contactRole: contactRole,
        specialty: specialty,
        preferred: preferred,
        leadDays: leadDays,
        onTimePct: onTimePct,
        lifetimePos: lifetimePos,
        fulfilledPct: fulfilledPct,
        notes: notes ?? this.notes,
        taxId: taxId,
        deliveryMode: deliveryMode,
        costLabel: costLabel,
        costUnit: costUnit,
        costTrend: costTrend,
      );
}
