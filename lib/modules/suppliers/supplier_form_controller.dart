import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../purchase_orders/procurement_store.dart';
import 'supplier_models.dart';

/// Add / Edit Supplier. Arguments: supplier id (edit) or nothing (add).
/// UI state only. Backend wiring is marked with TODO(backend).
class SupplierFormController extends GetxController {
  final store = ProcurementStore.to;

  late final Supplier? editing =
      Get.arguments is String ? store.supplier(Get.arguments as String) : null;

  bool get isEdit => editing != null;

  late final nameController = TextEditingController(text: editing?.name);
  late final categoryController = TextEditingController(text: editing?.category);
  late final contactController = TextEditingController(text: editing?.contact);
  late final phoneController = TextEditingController(text: editing?.phone);
  late final emailController = TextEditingController(text: editing?.email);
  late final addressController = TextEditingController(text: editing?.address);
  late final cityController = TextEditingController(text: editing?.city);
  late final notesController = TextEditingController(text: editing?.notes);

  late final terms = (editing?.terms ?? 'Net 30').obs;

  /// Field key -> error text.
  final errors = <String, String>{}.obs;

  void selectTerms(String t) => terms.value = t;

  void clearError(String key) => errors.remove(key);

  bool _validate() {
    final e = <String, String>{};
    if (nameController.text.trim().isEmpty) e['name'] = 'Enter the supplier name';
    if (contactController.text.trim().isEmpty) {
      e['contact'] = 'Enter a contact person';
    }
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) e['phone'] = 'Enter a 10-digit phone number';
    final email = emailController.text.trim();
    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      e['email'] = 'Enter a valid email';
    }
    errors.assignAll(e);
    return e.isEmpty;
  }

  void onSave() {
    if (!_validate()) return;
    final base = editing;
    final s = base == null
        ? Supplier(
            id: store.nextSupplierId(),
            name: nameController.text.trim(),
            category: _orDash(categoryController.text),
            contact: contactController.text.trim(),
            phone: phoneController.text.trim(),
            email: emailController.text.trim(),
            city: _orDash(cityController.text),
            address: _orDash(addressController.text),
            terms: terms.value,
            totalPurchased: 0,
            lastOrder: 'No orders yet',
            notes: notesController.text.trim(),
          )
        : base.copyWith(
            name: nameController.text.trim(),
            category: _orDash(categoryController.text),
            contact: contactController.text.trim(),
            phone: phoneController.text.trim(),
            email: emailController.text.trim(),
            city: _orDash(cityController.text),
            address: _orDash(addressController.text),
            terms: terms.value,
            notes: notesController.text.trim(),
          );
    // TODO(backend): POST / PATCH the supplier.
    store.saveSupplier(s);
    Get.back();
    Get.snackbar(
      isEdit ? 'Supplier updated' : 'Supplier added',
      s.name,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.check_circle_outline),
    );
  }

  static String _orDash(String v) => v.trim().isEmpty ? '—' : v.trim();

  void onBackPressed() => Get.back();

  @override
  void onClose() {
    for (final c in [
      nameController,
      categoryController,
      contactController,
      phoneController,
      emailController,
      addressController,
      cityController,
      notesController,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
