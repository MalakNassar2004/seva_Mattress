import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart'
    show describeError;
import 'package:seva_mattress/data/repositories/stock_repository.dart';
import 'inventory_models.dart';

enum AdjustMode { setQuantity, relative }

/// Adjust Stock bottom sheet. Created with Get.put inside the sheet
/// (bottom sheets are not routes, so they have no binding).
///
/// The quantity is per LOCATION (warehouse / showroom / damaged):
/// - Set New Quantity: the number is the new quantity at that location.
/// - Relative Change: the number is how many units to add (+) or remove (-).
class AdjustStockController extends GetxController {
  AdjustStockController({required this.item, required this.canViewCost});

  final StockItem item;

  /// Only the owner sees cost and inventory value.
  final bool canViewCost;

  // ---------------- State ----------------
  static const String damagedReason = 'Damaged goods';
  static const List<String> reasons = [
    'Count correction (Physical cycle count)',
    damagedReason,
    'Received stock',
    'Customer return',
    'Other',
  ];

  static const int maxNoteLength = 200;

  final _repo = StockRepository();

  final mode = AdjustMode.setQuantity.obs;
  late final value = _quantityAt(0).obs; // starts with "no change"
  final location = 0.obs;
  final reason = RxnString();
  final reasonError = false.obs;
  final isSaving = false.obs;

  // Not disposed on purpose (see the Login controller note).
  late final noteController = TextEditingController();

  /// Who is making the change (shown in the sheet footer).
  String get signedInAs => FirebaseAuth.instance.currentUser?.email ?? '';

  // ---------------- Locations ----------------
  /// (label, units, icon): same order as StockLocation.
  List<(String, int, IconData)> get locations => [
    ('Surrey Whse', item.warehouse, Icons.warehouse_outlined),
    ('Showroom', item.showroom, Icons.storefront_outlined),
    ('Damaged', item.damaged, Icons.warning_amber_rounded),
  ];

  int _quantityAt(int index) {
    switch (index) {
      case 0:
        return item.warehouse;
      case 1:
        return item.showroom;
      default:
        return item.damaged;
    }
  }

  String get locationLabel => locations[location.value].$1;

  // ---------------- Numbers ----------------
  /// Current quantity at the selected location.
  int get base => _quantityAt(location.value);

  /// How many units are added (+) or removed (-).
  int get delta => mode.value == AdjustMode.setQuantity
      ? value.value - base
      : value.value;

  /// Quantity at the selected location after the change.
  int get after => base + delta;

  /// Change in inventory value (owner only).
  double get valueDelta => delta * item.cost;

  /// "Damaged goods" taken out of the warehouse / showroom go to the
  /// damaged stock automatically.
  bool get moveToDamaged =>
      reason.value == damagedReason && location.value != 2 && delta < 0;

  int newUnitsFor(int index) {
    final current = _quantityAt(index);
    if (index == location.value) {
      final next = current + delta;
      return next < 0 ? 0 : next;
    }
    if (index == 2 && moveToDamaged) return current + (-delta);
    return current;
  }

  // ---------------- Actions ----------------
  void setMode(AdjustMode m) {
    if (m == mode.value) return;
    final d = delta;
    mode.value = m;
    value.value = m == AdjustMode.relative ? d : base + d;
  }

  void increment() {
    if (after >= StockRepository.maxUnits) return;
    value.value++;
  }

  void decrement() {
    if (after <= 0) return; // never below zero
    value.value--;
  }

  /// Keeps the same change (+/-) and applies it to the new location.
  void selectLocation(int index) {
    final d = delta;
    location.value = index;
    value.value = mode.value == AdjustMode.setQuantity ? _quantityAt(index) + d : d;
  }

  void selectReason(String? r) {
    reason.value = r;
    reasonError.value = false;
  }

  Future<void> onConfirmPressed() async {
    if (isSaving.value) return; // ignore double taps

    final selectedReason = reason.value;
    if (selectedReason == null) {
      reasonError.value = true;
      return;
    }

    final d = delta;
    if (d == 0) {
      _showMessage('No change', 'Change the quantity first.');
      return;
    }
    if (after < 0) {
      _showMessage('Check the quantity', 'The quantity cannot be below zero.');
      return;
    }
    if ((selectedReason == 'Received stock' ||
        selectedReason == 'Customer return') &&
        d < 0) {
      _showMessage(
        'Check the reason',
        '"$selectedReason" adds units. Use "Damaged goods" or "Count '
            'correction" to remove units.',
      );
      return;
    }

    final note = noteController.text.trim();
    if (note.length > maxNoteLength) {
      _showMessage('Note too long', 'Max $maxNoteLength characters.');
      return;
    }

    isSaving.value = true;
    try {
      await _repo.adjust(
        productId: item.id,
        location: StockLocation.values[location.value],
        delta: d,
        reason: selectedReason,
        note: note,
        moveToDamaged: moveToDamaged,
      );
      // Close the sheet first, then show the message.
      Get.back();
      _showMessage('Saved', 'The stock was updated.');
    } catch (e) {
      _showMessage('Could not save', describeError(e));
    } finally {
      isSaving.value = false;
    }
  }

  // ---------------- Navigation ----------------
  void onClosePressed() => Get.back();

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}