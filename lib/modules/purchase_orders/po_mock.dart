import 'package:flutter/material.dart';
import '../suppliers/suppliers_mock.dart';
import 'po_models.dart';

/// Mock data for Purchase Orders.
/// TODO(backend): delete when the API is wired.
class PoMock {
  PoMock._();

  /// "Today" in the mock data.
  static final DateTime today = DateTime(2024, 10, 25);

  static const String openValueTrend = '+6.4%';

  static final List<PurchaseOrder> orders = [
    PurchaseOrder(
      number: '#PO-2024-089',
      supplierId: SuppliersMock.cascadia.id,
      status: PoStatus.partial,
      expected: DateTime(2024, 10, 24),
      overdue: true,
      invoice: '#INV-4901',
      invoiceDue: 'Due Nov 15',
      packingSlip: '#PS-88410',
      carrier: 'Day & Ross Freight',
      dockPass: 'Dock Pass #402',
      deliveryNote: 'Driver delivered 2 pallets at rear dock. Inspected by Owner.',
      lines: const [
        PoLine(
          name: 'Organic Dunlop Latex Core',
          size: 'Queen 6"',
          sku: 'MAT-LTX-DUN-Q',
          qty: 12,
          unitCost: 800,
          icon: Icons.bed_outlined,
        ),
        PoLine(
          name: 'Natural Talalay Pillow Cores',
          sku: 'PIL-TAL-STD',
          qty: 24,
          unitCost: 120,
          icon: Icons.inventory_2_outlined,
        ),
        PoLine(
          name: 'Organic Wool Quilt Battens',
          sku: 'FAB-WOL-BAT',
          qty: 6,
          unitCost: 145,
          unit: 'rolls',
          icon: Icons.layers_outlined,
        ),
        PoLine(
          name: 'Comfort Topper Sheets',
          size: 'Queen 2"',
          sku: 'TOP-LTX-2Q',
          qty: 4,
          unitCost: 225,
          received: 4,
          icon: Icons.view_agenda_outlined,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-092',
      supplierId: SuppliersMock.pacific.id,
      status: PoStatus.ordered,
      expected: DateTime(2024, 10, 29),
      freight: 'In Transit',
      lines: const [
        PoLine(
          name: 'Pocket Coil Units',
          size: 'Queen',
          sku: 'COIL-PKT-Q',
          qty: 40,
          unitCost: 200,
          icon: Icons.blur_on,
        ),
        PoLine(
          name: 'Edge Support Wire',
          sku: 'WIRE-EDG-9',
          qty: 20,
          unitCost: 45,
          icon: Icons.linear_scale,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-094',
      supplierId: SuppliersMock.fraser.id,
      status: PoStatus.draft,
      expected: DateTime(2024, 11, 4),
      lastEdited: '2 hours ago',
      lines: const [
        PoLine(
          name: 'Organic Bamboo Quilting',
          sku: 'FAB-BAM-QLT',
          qty: 10,
          unitCost: 180,
          unit: 'rolls',
          icon: Icons.texture,
        ),
        PoLine(
          name: 'Cotton Ticking',
          sku: 'FAB-COT-TCK',
          qty: 8,
          unitCost: 120,
          unit: 'rolls',
          icon: Icons.texture,
        ),
        PoLine(
          name: 'Bonded Thread Spools',
          sku: 'SEW-THR-BND',
          qty: 12,
          unitCost: 35,
          icon: Icons.gesture,
        ),
        PoLine(
          name: 'Cover Zippers 80"',
          sku: 'SEW-ZIP-80',
          qty: 30,
          unitCost: 10,
          icon: Icons.drag_handle,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-095',
      supplierId: SuppliersMock.cascadia.id,
      status: PoStatus.ordered,
      expected: DateTime(2024, 11, 1),
      freight: 'In Production',
      lines: const [
        PoLine(
          name: 'Talalay Firm Blocks',
          size: 'King',
          sku: 'MAT-LTX-TAL-K',
          qty: 5,
          unitCost: 950,
          icon: Icons.king_bed_outlined,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-096',
      supplierId: SuppliersMock.pacific.id,
      status: PoStatus.ordered,
      expected: DateTime(2024, 11, 6),
      freight: 'Confirmed',
      lines: const [
        PoLine(
          name: 'Micro Coil Comfort Layer',
          size: 'Queen',
          sku: 'COIL-MIC-Q',
          qty: 20,
          unitCost: 85,
          icon: Icons.blur_on,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-097',
      supplierId: SuppliersMock.cascadia.id,
      status: PoStatus.draft,
      expected: DateTime(2024, 11, 8),
      lastEdited: 'Yesterday',
      lines: const [
        PoLine(
          name: 'RV Short Queen Latex Core',
          size: '60" x 74"',
          sku: 'MAT-LTX-RVSQ',
          qty: 3,
          unitCost: 720,
          icon: Icons.bed_outlined,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-078',
      supplierId: SuppliersMock.cascadia.id,
      status: PoStatus.received,
      expected: DateTime(2024, 10, 1),
      receivedOn: 'Oct 01, 2024',
      invoice: '#INV-4812',
      lines: const [
        PoLine(
          name: 'Natural Latex Cores',
          size: 'Queen',
          sku: 'MAT-LTX-NAT-Q',
          qty: 10,
          unitCost: 950,
          received: 10,
          icon: Icons.bed_outlined,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-066',
      supplierId: SuppliersMock.cascadia.id,
      status: PoStatus.received,
      expected: DateTime(2024, 9, 12),
      receivedOn: 'Sep 12, 2024',
      invoice: '#INV-4655',
      lines: const [
        PoLine(
          name: 'Organic Dunlop Latex Core',
          size: 'Queen 6"',
          sku: 'MAT-LTX-DUN-Q',
          qty: 10,
          unitCost: 820,
          received: 10,
          icon: Icons.bed_outlined,
        ),
      ],
    ),
    PurchaseOrder(
      number: '#PO-2024-080',
      supplierId: SuppliersMock.pacific.id,
      status: PoStatus.received,
      expected: DateTime(2024, 10, 18),
      receivedOn: 'Oct 18, 2024',
      invoice: '#INV-7702',
      lines: const [
        PoLine(
          name: 'Pocket Coil Units',
          size: 'King',
          sku: 'COIL-PKT-K',
          qty: 30,
          unitCost: 235,
          received: 30,
          icon: Icons.blur_on,
        ),
      ],
    ),
  ];

  /// Products the Create PO search offers, per supplier id.
  static final Map<String, List<PoProduct>> catalog = {
    SuppliersMock.cascadia.id: const [
      PoProduct(
        name: 'Organic Dunlop Latex Core',
        sku: 'MAT-LTX-DUN',
        sizes: ['Twin 6"', 'Queen 6"', 'King 6"'],
        unitCost: 800,
        icon: Icons.bed_outlined,
      ),
      PoProduct(
        name: 'Talalay Firm Blocks',
        sku: 'MAT-LTX-TAL',
        sizes: ['Queen', 'King'],
        unitCost: 950,
        icon: Icons.king_bed_outlined,
      ),
      PoProduct(
        name: 'Natural Talalay Pillow Cores',
        sku: 'PIL-TAL-STD',
        sizes: ['Standard', 'King'],
        unitCost: 120,
        icon: Icons.inventory_2_outlined,
      ),
      PoProduct(
        name: 'Organic Wool Quilt Battens',
        sku: 'FAB-WOL-BAT',
        sizes: ['60" roll'],
        unitCost: 145,
        unit: 'rolls',
        icon: Icons.layers_outlined,
      ),
    ],
    SuppliersMock.pacific.id: const [
      PoProduct(
        name: 'Pocket Coil Units',
        sku: 'COIL-PKT',
        sizes: ['Twin', 'Queen', 'King'],
        unitCost: 200,
        icon: Icons.blur_on,
      ),
      PoProduct(
        name: 'Edge Support Wire',
        sku: 'WIRE-EDG-9',
        sizes: ['9 ga'],
        unitCost: 45,
        icon: Icons.linear_scale,
      ),
      PoProduct(
        name: 'Micro Coil Comfort Layer',
        sku: 'COIL-MIC',
        sizes: ['Queen', 'King'],
        unitCost: 85,
        icon: Icons.blur_on,
      ),
    ],
    SuppliersMock.fraser.id: const [
      PoProduct(
        name: 'Organic Bamboo Quilting',
        sku: 'FAB-BAM-QLT',
        sizes: ['60" roll', '80" roll'],
        unitCost: 180,
        unit: 'rolls',
        icon: Icons.texture,
      ),
      PoProduct(
        name: 'Cotton Ticking',
        sku: 'FAB-COT-TCK',
        sizes: ['60" roll'],
        unitCost: 120,
        unit: 'rolls',
        icon: Icons.texture,
      ),
      PoProduct(
        name: 'Cover Zippers 80"',
        sku: 'SEW-ZIP-80',
        sizes: ['80"'],
        unitCost: 10,
        icon: Icons.drag_handle,
      ),
    ],
  };
}
