import 'supplier_models.dart';

/// Mock data for Suppliers.
/// TODO(backend): delete when the API is wired.
class SuppliersMock {
  SuppliersMock._();

  static const int activeSuppliers = 12;
  static const double totalSpendYtd = 214800;
  static const String spendTrend = '+12.4%';
  static const String avgLeadTime = '4.2 Days';

  static const Supplier cascadia = Supplier(
    id: 'SUP-041',
    name: 'Cascadia Foam & Latex Works',
    category: 'Latex & Core Materials',
    specialty: 'Latex & Foam Core Specialist',
    contact: 'Robert MacIntyre',
    contactRole: 'Lead Showroom Account Rep',
    phone: '(604) 555-7821',
    email: 'orders@cascadiafoam.ca',
    city: 'Delta, BC',
    address: 'Delta Industrial Park, BC',
    terms: 'Net 30',
    totalPurchased: 94500,
    lastOrder: 'Oct 22, 2024',
    preferred: true,
    leadDays: '3-5 Days',
    onTimePct: 98.1,
    lifetimePos: 18,
    fulfilledPct: 100,
    taxId: 'BC-PST 1084-2918 · GST Registered',
    notes: 'Requires 48hr advance notification for custom RV chamfer latex '
        'cutouts.',
    costLabel: 'Latex Cost Trend',
    costUnit: 'sq ft (Standard Firm)',
    costTrend: [
      CostPoint('MAY', 31.9),
      CostPoint('JUN', 33.1),
      CostPoint('JUL', null),
      CostPoint('AUG', 32.6),
      CostPoint('SEP', 32.0),
      CostPoint('OCT', 32.4),
    ],
  );

  static const Supplier pacific = Supplier(
    id: 'SUP-027',
    name: 'Pacific Spring & Wire Ltd.',
    category: 'Pocket Coils & Innerspring',
    specialty: 'Innerspring Manufacturer',
    contact: 'Elena Chen',
    phone: '(604) 555-3419',
    email: 'sales@pacificspring.ca',
    city: 'Richmond, BC',
    address: '12100 Vulcan Way, Richmond, BC',
    terms: 'Net 15',
    totalPurchased: 68200,
    lastOrder: 'Oct 18, 2024',
    leadDays: '3 Days',
    onTimePct: 96.5,
    lifetimePos: 11,
    fulfilledPct: 97,
    taxId: 'BC-PST 2231-0045 · GST Registered',
    costLabel: 'Coil Unit Cost Trend',
    costUnit: 'queen coil unit',
    costTrend: [
      CostPoint('MAY', 192),
      CostPoint('JUN', 195),
      CostPoint('JUL', 198),
      CostPoint('AUG', 198),
      CostPoint('SEP', 201),
      CostPoint('OCT', 200),
    ],
  );

  static const Supplier fraser = Supplier(
    id: 'SUP-052',
    name: 'Fraser Valley Textiles Inc.',
    category: 'Organic Cotton & Bamboo Covers',
    specialty: 'Quilted Covers & Ticking',
    contact: 'Gurpreet Dhillon',
    phone: '(778) 555-9012',
    email: 'gurpreet@fvtextiles.ca',
    city: 'Abbotsford, BC',
    address: '31450 Marshall Rd, Abbotsford, BC',
    terms: 'Net 30',
    totalPurchased: 52100,
    lastOrder: 'Oct 05, 2024',
    leadDays: '5-7 Days',
    onTimePct: 99.4,
    lifetimePos: 9,
    fulfilledPct: 100,
    taxId: 'BC-PST 3390-1177 · GST Registered',
    costLabel: 'Quilting Cost Trend',
    costUnit: 'linear yard',
    costTrend: [
      CostPoint('MAY', 17.5),
      CostPoint('JUN', 17.8),
      CostPoint('JUL', 18.0),
      CostPoint('AUG', 18.2),
      CostPoint('SEP', null),
      CostPoint('OCT', 18.0),
    ],
  );

  static const List<Supplier> suppliers = [cascadia, pacific, fraser];
}
