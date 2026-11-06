import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../products/product_item.dart';

/// UI state only. The same screen is used for Add and Edit:
/// Edit starts with mock data, Add starts empty.
/// Backend wiring is marked with TODO(backend).
class ProductFormController extends GetxController {
  ProductFormController({required this.isEdit});

  final bool isEdit;

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

  // ---- text fields (not disposed on purpose, see Login controller note) ----
  late final nameController =
      TextEditingController(text: isEdit ? 'Seva Hybrid Luxury' : '');
  late final modelController =
      TextEditingController(text: isEdit ? 'SV-HYB-2024' : '');
  late final descriptionController = TextEditingController(
    text: isEdit
        ? 'Multi-layered organic latex and pocket coil hybrid mattress '
            'engineered for temperature regulation and ergonomic spinal support.'
        : '',
  );
  late final skuController =
      TextEditingController(text: isEdit ? 'MAT-SEV-HYB-QN' : '');
  late final retailController =
      TextEditingController(text: isEdit ? '1,899.00' : '');
  late final costController =
      TextEditingController(text: isEdit ? '760.00' : '');
  late final stockController = TextEditingController(text: isEdit ? '8' : '');
  late final dimensionsController = TextEditingController(
    text: isEdit ? 'Min: 28" × 50" — Max: 84" × 96"' : '',
  );

  // ---- selections ----
  late final category = RxnString(isEdit ? 'Mattresses' : null);
  final selectedSize = 'Queen'.obs;
  late final customSizeEnabled = isEdit.obs;
  late final thicknesses =
      (isEdit ? <String>['10" (Standard)'] : <String>[]).obs;
  late final cuts = (isEdit ? List<String>.from(cutOptions) : <String>[]).obs;
  late final pricingFormula =
      RxnString(isEdit ? 'Surcharge + \$18.50 / sq ft' : null);
  late final notesRequired = isEdit.obs;
  final isActive = true.obs;
  late final photoCount = (isEdit ? 2 : 0).obs;

  // ---- derived values ----
  final marginPercent = RxnDouble();
  final profit = RxnDouble();
  final stockUnits = RxnInt();

  String get productCode => isEdit ? '4102' : 'Auto';

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

  // ---- actions ----
  void selectSize(String size) => selectedSize.value = size;

  void toggleThickness(String t) {
    thicknesses.contains(t) ? thicknesses.remove(t) : thicknesses.add(t);
  }

  void toggleCut(String c) {
    cuts.contains(c) ? cuts.remove(c) : cuts.add(c);
  }

  void addPhoto() {
    // TODO(backend): open the image picker and upload the photo.
    if (photoCount.value < maxPhotos) photoCount.value++;
  }

  void removePhoto() {
    if (photoCount.value > 0) photoCount.value--;
  }

  void onSavePressed() {
    // TODO(backend): create (Add) or update (Edit) the product.
    // Cost price and inventory updates must be written to the owner audit log.
  }

  void onDiscardPressed() => Get.back();

  void onBackPressed() => Get.back();

  void onHelpPressed() {
    // TODO: open help
  }
}
