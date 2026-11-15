import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'inventory_mock.dart';

enum AdjustMode { setQuantity, relative }

/// Adjust Stock bottom sheet. Created with Get.put inside the sheet
/// (bottom sheets are not routes, so they have no binding).
/// UI state only. Backend wiring is marked with TODO(backend).
class AdjustStockController extends GetxController {
  // ---------------- State ----------------
  static const List<String> reasons = [
    'Count correction (Physical cycle count)',
    'Damaged goods',
    'Received stock',
    'Customer return',
    'Other',
  ];

  final mode = AdjustMode.setQuantity.obs;
  final value = AdjustStockMock.initialValue.obs;
  final location = 0.obs;
  final reason = RxnString(AdjustStockMock.initialReason);
  final reasonError = false.obs;

  // Not disposed on purpose (see the Login controller note).
  late final noteController =
      TextEditingController(text: AdjustStockMock.initialNote);

  // ---------------- Mock data ----------------
  // TODO(backend): receive the real product instead of this mock.
  static const String productName = AdjustStockMock.productName;
  static const String sku = AdjustStockMock.sku;
  static const double cost = AdjustStockMock.cost;
  static const int baseUnits = AdjustStockMock.baseUnits;
  static const List<(String, int, IconData)> locations =
      AdjustStockMock.locations;

  // UI counter (kept from the design, not business logic).
  int get delta => mode.value == AdjustMode.setQuantity
      ? value.value - baseUnits
      : value.value;

  int get total => baseUnits + delta;

  double get valueDelta => delta * cost;

  int newUnitsFor(int index) {
    final base = locations[index].$2;
    if (index != location.value) return base;
    final next = base + delta;
    return next < 0 ? 0 : next;
  }

  // ---------------- Actions ----------------
  void setMode(AdjustMode m) {
    if (m == mode.value) return;
    final d = delta;
    mode.value = m;
    value.value = m == AdjustMode.relative ? d : baseUnits + d;
  }

  void increment() => value.value++;

  void decrement() {
    if (total <= 0) return;
    value.value--;
  }

  void selectLocation(int index) => location.value = index;

  void selectReason(String? r) {
    reason.value = r;
    reasonError.value = false;
  }

  void onConfirmPressed() {
    if (reason.value == null) {
      reasonError.value = true;
      return;
    }
    // TODO(backend): save the stock adjustment (mode, delta, location,
    // reason, note) and write it to the owner audit log.
    Get.back();
  }

  // ---------------- Navigation ----------------
  void onClosePressed() => Get.back();
}
