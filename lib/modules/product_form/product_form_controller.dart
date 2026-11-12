import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../products/product_item.dart';
import 'product_form_mock.dart';

/// Add / Edit product. The same screen serves two routes (see
/// ProductFormBinding): Edit starts with mock data, Add starts empty.
/// UI state only. Backend wiring is marked with TODO(backend).
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

  // ---------------- Mock data ----------------
  // TODO(backend): load the product being edited instead of ProductFormMock.
  // Text fields are not disposed on purpose (see the Login controller note).
  late final nameController =
      TextEditingController(text: isEdit ? ProductFormMock.name : '');
  late final modelController =
      TextEditingController(text: isEdit ? ProductFormMock.model : '');
  late final descriptionController =
      TextEditingController(text: isEdit ? ProductFormMock.description : '');
  late final skuController =
      TextEditingController(text: isEdit ? ProductFormMock.sku : '');
  late final retailController =
      TextEditingController(text: isEdit ? ProductFormMock.retail : '');
  late final costController =
      TextEditingController(text: isEdit ? ProductFormMock.cost : '');
  late final stockController =
      TextEditingController(text: isEdit ? ProductFormMock.stock : '');
  late final dimensionsController =
      TextEditingController(text: isEdit ? ProductFormMock.dimensions : '');

  late final category = RxnString(isEdit ? ProductFormMock.category : null);
  final selectedSize = 'Queen'.obs;
  late final customSizeEnabled = isEdit.obs;
  late final thicknesses =
      (isEdit ? List<String>.from(ProductFormMock.thicknesses) : <String>[])
          .obs;
  late final cuts = (isEdit ? List<String>.from(cutOptions) : <String>[]).obs;
  late final pricingFormula =
      RxnString(isEdit ? ProductFormMock.pricingFormula : null);
  late final notesRequired = isEdit.obs;
  final isActive = true.obs;
  late final photoCount = (isEdit ? ProductFormMock.photoCount : 0).obs;

  String get productCode => isEdit ? ProductFormMock.code : 'Auto';

  // Margin chip (UI preview kept from the design, not business logic).
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
    // TODO(backend): open the image picker and upload the photo.
    if (photoCount.value < maxPhotos) photoCount.value++;
  }

  void removePhoto() {
    // TODO(backend): delete the uploaded photo.
    if (photoCount.value > 0) photoCount.value--;
  }

  void onSavePressed() {
    // TODO(backend): create (Add) or update (Edit) the product.
    // Cost price and inventory updates must be written to the owner audit log.
  }

  void onHelpPressed() {
    // TODO(backend): open the help content for this form.
  }

  // ---------------- Navigation ----------------
  void onDiscardPressed() => Get.back();

  void onBackPressed() => Get.back();
}
