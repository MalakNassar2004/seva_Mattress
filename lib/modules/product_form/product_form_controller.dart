import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../products/product_item.dart';

/// Add / Edit product. The same screen serves two routes (see
/// ProductFormBinding). Edit receives the product from the list
/// (Get.arguments), Add starts empty. Saving goes through ProductRepository.
///
/// The cost price is OWNER ONLY: it is loaded and saved only when the signed
/// in employee is the owner.
class ProductFormController extends GetxController {
  ProductFormController({required this.isEdit});

  final bool isEdit;

  // ---------------- State ----------------
  static const int maxPhotos = 5;

  static const Map<String, String> sizes = {
    'Twin': '(39"×75")',
    'Full': '(54"×75")',
    'Queen': '(60"×80")',
    'King': '(76"×80")',
    'Cal King': '(72"×84")',
  };

  static const List<String> categories = [
    'Mattresses',
    'Pillows',
    'Protectors',
    'Accessories',
  ];

  static const List<String> thicknessOptions = [
    '8"',
    '10" (Standard)',
    '12" Plush',
  ];

  static const List<String> cutOptions = [
    'Square (90°)',
    'Chamfer / Corner Cut',
    'Radius Rounded',
  ];

  static const List<String> pricingFormulas = [
    'Surcharge + \$18.50 / sq ft',
    'Fixed surcharge',
    'Rate per sq ft',
  ];

  final _repo = ProductRepository();

  /// The product being edited (passed from the list). Null when adding.
  late final ProductItem? editing = _readEditing();

  ProductItem? _readEditing() {
    if (!isEdit) return null;
    final args = Get.arguments;
    return args is ProductItem ? args : null;
  }

  // Text fields are not disposed on purpose (see the Login controller note).
  late final nameController = TextEditingController(text: editing?.name ?? '');
  late final modelController =
  TextEditingController(text: editing?.model ?? '');
  late final descriptionController =
  TextEditingController(text: editing?.description ?? '');
  late final skuController = TextEditingController(text: editing?.sku ?? '');
  late final retailController = TextEditingController(
    text: editing?.price.toStringAsFixed(2) ?? '',
  );
  // Filled in later, and only for the owner (see _loadPermissions).
  final costController = TextEditingController();
  late final stockController =
  TextEditingController(text: editing?.units.toString() ?? '');
  late final dimensionsController =
  TextEditingController(text: editing?.dimensions ?? '');

  late final category = RxnString(editing?.category);
  late final selectedSize = (editing?.size ?? 'Queen').obs;
  late final customSizeEnabled = (editing?.customSize ?? false).obs;
  late final thicknesses =
      List<String>.of(editing?.thicknesses ?? const <String>[]).obs;
  late final cuts = List<String>.of(editing?.cuts ?? const <String>[]).obs;
  late final pricingFormula = RxnString(editing?.pricingFormula);
  late final notesRequired = (editing?.notesRequired ?? false).obs;
  late final isActive = (editing?.isActive ?? true).obs;
  late final photoCount = (editing?.photoUrls.length ?? 0).obs;

  final isSaving = false.obs;

  /// true only when the signed-in employee is the owner. The view should
  /// hide the cost price field (and margin / profit) when this is false.
  final canViewCost = false.obs;
  bool _permissionsLoaded = false;

  /// Add: 'Auto'. Edit: the first characters of the product id.
  String get productCode {
    final id = editing?.id ?? '';
    if (id.isEmpty) return 'Auto';
    return (id.length > 6 ? id.substring(0, 6) : id).toUpperCase();
  }

  // Margin chip (derived from the retail and cost prices).
  final marginPercent = RxnDouble();
  final profit = RxnDouble();
  final stockUnits = RxnInt();

  @override
  void onInit() {
    super.onInit();
    retailController.addListener(_recalculate);
    costController.addListener(_recalculate);
    stockController.addListener(() {
      stockUnits.value = int.tryParse(stockController.text.trim());
    });
    _recalculate();
    stockUnits.value = int.tryParse(stockController.text.trim());
    _loadPermissions();
  }

  /// Finds out who is signed in. Only the owner gets the saved cost price.
  Future<void> _loadPermissions() async {
    try {
      final user = await SessionService().loadCurrentUser();
      _permissionsLoaded = user != null;
      canViewCost.value = user?.isOwner ?? false;

      final id = editing?.id ?? '';
      if (canViewCost.value && isEdit && id.isNotEmpty) {
        final cost = await _repo.loadCost(id);
        if (cost != null) costController.text = cost.toStringAsFixed(2);
      }
    } catch (_) {
      _permissionsLoaded = false;
    }
  }

  double? _parse(String text) =>
      double.tryParse(text.replaceAll(RegExp(r'[^0-9.]'), ''));

  void _recalculate() {
    final retail = _parse(retailController.text);
    final cost = _parse(costController.text);
    if (retail == null || cost == null || retail <= 0) {
      marginPercent.value = null;
      profit.value = null;
      return;
    }
    profit.value = retail - cost;
    marginPercent.value = (retail - cost) / retail * 100;
  }

  String get profitText =>
      profit.value == null ? '' : '+${formatMoney(profit.value!)} profit CAD';

  // ---------------- Actions ----------------
  void selectSize(String size) => selectedSize.value = size;

  void toggleThickness(String t) {
    thicknesses.contains(t) ? thicknesses.remove(t) : thicknesses.add(t);
  }

  void toggleCut(String c) {
    cuts.contains(c) ? cuts.remove(c) : cuts.add(c);
  }

  void setActive(bool active) => isActive.value = active;

  void addPhoto() {
    // TODO(storage): open the image picker and upload the photo. Needs
    // Cloud Storage (Blaze plan). For now this only changes the counter and
    // photos are NOT saved.
    if (photoCount.value < maxPhotos) photoCount.value++;
  }

  void removePhoto() {
    // TODO(storage): delete the uploaded photo.
    if (photoCount.value > 0) photoCount.value--;
  }

  String? _validationError() {
    if (nameController.text.trim().isEmpty) {
      return 'Product name is required.';
    }
    if (category.value == null) return 'Please choose a category.';

    final retail = _parse(retailController.text);
    if (retail == null || retail <= 0) return 'Enter a valid retail price.';

    if (canViewCost.value) {
      final costText = costController.text.trim();
      if (costText.isNotEmpty && _parse(costText) == null) {
        return 'Enter a valid cost price.';
      }
    }

    final stock = int.tryParse(stockController.text.trim());
    if (stock == null || stock < 0) {
      return 'Enter the stock quantity (0 or more).';
    }
    return null;
  }

  Future<void> onSavePressed() async {
    if (isSaving.value) return; // ignore double taps

    // Without this check an owner could save while we still do not know who
    // he is, and his cost price would be silently ignored.
    if (!_permissionsLoaded) {
      _showMessage(
        'Please wait',
        'Checking your permissions. If this keeps happening, check your '
            'connection and reopen this screen.',
      );
      return;
    }

    final error = _validationError();
    if (error != null) {
      _showMessage('Check the form', error);
      return;
    }

    final canEditCost = canViewCost.value;
    final costText = costController.text.trim();
    // Empty = "leave the saved cost as it is" (a saved cost cannot be erased).
    final double? costPrice =
    (canEditCost && costText.isNotEmpty) ? _parse(costText) : null;

    // Photos and the cost price are not part of this map on purpose: photos
    // are managed separately, and the cost price lives in its own
    // owner-only document.
    final data = <String, dynamic>{
      'name': nameController.text.trim(),
      'model': modelController.text.trim(),
      'description': descriptionController.text.trim(),
      'sku': skuController.text.trim(),
      'category': category.value,
      'retailPrice': _parse(retailController.text),
      'units': int.parse(stockController.text.trim()),
      'dimensions': dimensionsController.text.trim(),
      'size': selectedSize.value,
      'customSize': customSizeEnabled.value,
      'thicknesses': thicknesses.toList(),
      'cuts': cuts.toList(),
      'pricingFormula': pricingFormula.value,
      'notesRequired': notesRequired.value,
      'isActive': isActive.value,
    };

    isSaving.value = true;
    try {
      if (isEdit) {
        final id = editing?.id ?? '';
        if (id.isEmpty) {
          _showMessage(
            'Cannot save',
            'Open the product from the list to edit it.',
          );
          return;
        }
        await _repo.update(
          id,
          data,
          costPrice: costPrice,
          canEditCost: canEditCost,
        );
      } else {
        await _repo.create(
          data,
          costPrice: costPrice,
          canEditCost: canEditCost,
        );
      }

      // Go back first, then show the message (a snackbar would otherwise
      // be closed by Get.back()).
      Get.back();
      _showMessage('Saved', 'The product was saved.');
    } catch (e) {
      _showMessage('Could not save', describeError(e));
    } finally {
      isSaving.value = false;
    }
  }

  void onHelpPressed() {
    // TODO(backend): open the help content for this form.
  }

  // ---------------- Navigation ----------------
  void onDiscardPressed() => Get.back();

  void onBackPressed() => Get.back();

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}