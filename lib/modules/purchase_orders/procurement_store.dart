import 'package:get/get.dart';
import '../suppliers/supplier_models.dart';
import '../suppliers/suppliers_mock.dart';
import 'po_mock.dart';
import 'po_models.dart';

/// In-memory suppliers + purchase orders shared by the Suppliers and
/// Purchase Orders screens, so a receipt or a new PO shows up everywhere.
/// TODO(backend): replace with a repository backed by the API.
class ProcurementStore extends GetxService {
  static ProcurementStore get to => Get.isRegistered<ProcurementStore>()
      ? Get.find<ProcurementStore>()
      : Get.put(ProcurementStore(), permanent: true);

  final suppliers = <Supplier>[...SuppliersMock.suppliers].obs;
  final orders = <PurchaseOrder>[...PoMock.orders].obs;

  Supplier? supplier(String id) =>
      suppliers.firstWhereOrNull((s) => s.id == id);

  PurchaseOrder? order(String number) =>
      orders.firstWhereOrNull((o) => o.number == number);

  List<PurchaseOrder> ordersOf(String supplierId) =>
      orders.where((o) => o.supplierId == supplierId).toList();

  List<PurchaseOrder> openOrdersOf(String supplierId) =>
      ordersOf(supplierId).where((o) => o.isOpen).toList();

  void saveSupplier(Supplier s) {
    final i = suppliers.indexWhere((x) => x.id == s.id);
    if (i >= 0) {
      suppliers[i] = s;
    } else {
      suppliers.insert(0, s);
    }
  }

  void saveOrder(PurchaseOrder o) {
    final i = orders.indexWhere((x) => x.number == o.number);
    if (i >= 0) {
      orders[i] = o;
    } else {
      orders.insert(0, o);
    }
  }

  String nextSupplierId() => 'SUP-${(60 + suppliers.length).toString().padLeft(3, '0')}';

  String nextPoNumber() {
    var max = 0;
    for (final o in orders) {
      final n = int.tryParse(o.number.split('-').last) ?? 0;
      if (n > max) max = n;
    }
    return '#PO-2024-${(max + 1).toString().padLeft(3, '0')}';
  }
}
