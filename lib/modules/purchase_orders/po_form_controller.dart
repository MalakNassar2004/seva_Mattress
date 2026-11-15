import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../suppliers/supplier_models.dart';
import 'po_mock.dart';
import 'po_models.dart';
import 'procurement_store.dart';

/// Create PO (and resume a draft).
/// Arguments: {'supplierId': id} to preselect a supplier, or
/// {'number': '#PO-...'} to resume a draft. Nothing = blank PO.
/// UI state only. Backend wiring is marked with TODO(backend).
class PoFormController extends GetxController {
  final store = ProcurementStore.to;

  /// GST on purchases (PST exempt for resale).
  static const double gstRate = 0.05;

  late final Map<String, dynamic> _args =
      Get.arguments is Map ? Map<String, dynamic>.from(Get.arguments as Map) : {};

  late final PurchaseOrder? editing =
      _args['number'] is String ? store.order(_args['number'] as String) : null;

  bool get isEdit => editing != null;

  // ---------------- State ----------------
  late final supplierId =
      RxnString(editing?.supplierId ?? _args['supplierId'] as String?);
  final lines = <PoLine>[].obs;
  final List<TextEditingController> costControllers = [];
  final query = ''.obs;
  final searchController = TextEditingController();
  late final expected = (editing?.expected ??
          PoMock.today.add(const Duration(days: 5)))
      .obs;
  late final notesController = TextEditingController(text: editing?.notes);
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    for (final l in editing?.lines ?? const <PoLine>[]) {
      _addLine(l);
    }
  }

  Supplier? get supplier =>
      supplierId.value == null ? null : store.supplier(supplierId.value!);

  /// Products of the selected supplier matching the search.
  List<PoProduct> get results {
    final id = supplierId.value;
    if (id == null) return const [];
    final q = query.value.trim().toLowerCase();
    final all = PoMock.catalog[id] ?? const <PoProduct>[];
    if (q.isEmpty) return all;
    return all
        .where((p) => '${p.name} ${p.sku}'.toLowerCase().contains(q))
        .toList();
  }

  double get subtotal => lines.fold(0, (s, l) => s + l.total);
  double get gst => subtotal * gstRate;
  double get total => subtotal + gst;
  int get units => lines.fold(0, (s, l) => s + l.qty);

  // ---------------- Actions ----------------
  void selectSupplier(String id) {
    if (id == supplierId.value) return;
    supplierId.value = id;
    // Items belong to one supplier: start a fresh list.
    lines.clear();
    for (final c in costControllers) {
      c.dispose();
    }
    costControllers.clear();
    error.value = null;
  }

  void onSearchChanged(String v) => query.value = v;

  void addProduct(PoProduct p) {
    final size = p.sizes.first;
    final existing = lines.indexWhere(
        (l) => l.name == p.name && l.size == size);
    if (existing >= 0) {
      increment(existing);
      return;
    }
    _addLine(PoLine(
      name: p.name,
      sku: '${p.sku}-${size.split(' ').first.toUpperCase()}',
      size: size,
      qty: 1,
      unitCost: p.unitCost,
      icon: p.icon,
      unit: p.unit,
    ));
    error.value = null;
  }

  void _addLine(PoLine l) {
    lines.add(l);
    costControllers.add(TextEditingController(text: l.unitCost.toStringAsFixed(2)));
  }

  /// Sizes offered for a line (from the catalog).
  List<String> sizesFor(PoLine l) {
    final id = supplierId.value;
    final p = (PoMock.catalog[id] ?? const <PoProduct>[])
        .firstWhereOrNull((p) => p.name == l.name);
    return p?.sizes ?? (l.size.isEmpty ? const [] : [l.size]);
  }

  void selectSize(int i, String size) => lines[i] = lines[i].copyWith(size: size);

  void increment(int i) => lines[i] = lines[i].copyWith(qty: lines[i].qty + 1);

  void decrement(int i) {
    if (lines[i].qty > 1) lines[i] = lines[i].copyWith(qty: lines[i].qty - 1);
  }

  void onCostChanged(int i, String v) {
    final cost = double.tryParse(v.replaceAll(',', '')) ?? 0;
    lines[i] = lines[i].copyWith(unitCost: cost);
  }

  void removeLine(int i) {
    lines.removeAt(i);
    costControllers.removeAt(i).dispose();
  }

  Future<void> onPickDatePressed(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expected.value,
      firstDate: PoMock.today,
      lastDate: PoMock.today.add(const Duration(days: 180)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) expected.value = picked;
  }

  bool _validate({required bool placing}) {
    if (supplierId.value == null) {
      error.value = 'Pick a supplier';
      return false;
    }
    if (lines.isEmpty) {
      error.value = 'Add at least one item';
      return false;
    }
    if (placing && lines.any((l) => l.unitCost <= 0)) {
      error.value = 'Every item needs a unit cost';
      return false;
    }
    return true;
  }

  PurchaseOrder _build(PoStatus status) => PurchaseOrder(
        number: editing?.number ?? store.nextPoNumber(),
        supplierId: supplierId.value!,
        status: status,
        lines: lines.toList(),
        expected: expected.value,
        notes: notesController.text.trim(),
        lastEdited: status == PoStatus.draft ? 'just now' : null,
        freight: status == PoStatus.ordered ? 'Confirmed' : null,
      );

  void onSaveDraft() {
    if (!_validate(placing: false)) return;
    // TODO(backend): save the draft.
    final po = _build(PoStatus.draft);
    store.saveOrder(po);
    Get.back();
    Get.snackbar('Draft saved', '${po.number} · ${po.itemCount} items',
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.save_outlined));
  }

  void onPlaceOrder() {
    if (!_validate(placing: true)) return;
    // TODO(backend): submit the PO and email it to the supplier.
    final po = _build(PoStatus.ordered);
    store.saveOrder(po);
    Get.back();
    Get.snackbar(
      'Order placed',
      '${po.number} sent to ${supplier?.name ?? 'supplier'}',
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.send_outlined),
    );
  }

  void onBackPressed() => Get.back();

  @override
  void onClose() {
    for (final c in costControllers) {
      c.dispose();
    }
    searchController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
