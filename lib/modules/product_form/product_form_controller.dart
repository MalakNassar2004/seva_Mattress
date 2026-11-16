import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/app/routes/app_routes.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../products/product_item.dart';
import '../scanner/scanner_view.dart';

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

  // Limits (the Firestore rules enforce the same numbers).
  static const int maxNameLength = 80;
  static const int maxModelLength = 40;
  static const int maxDescriptionLength = 500;
  static const int maxDimensionsLength = 80;
  static const double maxPrice = 1000000;
  static const int maxStock = 100000;

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

  /// Id of the product being added. It is created ONCE for this form, so
  /// pressing Save twice (or retrying on a bad connection) can never create
  /// two products.
  late final String _newId = _repo.newProductId();

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

  // ---------------- Unsaved changes ----------------
  String _baseline = '';

  String _fingerprint() => [
    nameController.text,
    modelController.text,
    descriptionController.text,
    skuController.text,
    retailController.text,
    costController.text,
    stockController.text,
    dimensionsController.text,
    category.value ?? '',
    selectedSize.value,
    customSizeEnabled.value,
    thicknesses.join('|'),
    cuts.join('|'),
    pricingFormula.value ?? '',
    notesRequired.value,
    isActive.value,
  ].join('\u0001');

  bool get isDirty => _fingerprint() != _baseline;

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
    _baseline = _fingerprint();
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
        if (cost != null) {
          // Loading the saved cost is not a change made by the user.
          final wasClean = _fingerprint() == _baseline;
          costController.text = cost.toStringAsFixed(2);
          if (wasClean) _baseline = _fingerprint();
        }
      }
    } catch (_) {
      _permissionsLoaded = false;
    }
  }

  // ---------------- Helpers ----------------
  double? _parse(String text) =>
      double.tryParse(text.replaceAll(RegExp(r'[^0-9.]'), ''));

  /// Money rounded to 2 decimals (no 0.1 + 0.2 surprises later).
  double? _money(String text) {
    final v = _parse(text);
    return v == null ? null : (v * 100).round() / 100;
  }

  /// Trims and collapses repeated spaces.
  String _clean(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

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

  /// Scans a barcode with the camera and puts it in the SKU field. If the
  /// barcode already belongs to a product, it offers to open that product.
  Future<void> onScanPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final raw = await ScannerView.scan();
    if (raw == null) return;

    final code = normalizeSku(raw);
    if (code.isEmpty) return;

    final problem = skuProblem(code);
    if (problem != null) {
      _showMessage('Cannot use this code', problem);
      return;
    }

    ProductItem? existing;
    try {
      existing = await _repo.findBySku(code);
    } catch (_) {
      _showMessage(
        'Could not check duplicates',
        'No connection. The SKU was filled in and will be checked again '
            'when you save.',
      );
    }

    if (existing != null && existing.id != editing?.id) {
      if (isEdit) {
        _showMessage(
          'SKU already used',
          'This barcode belongs to "${existing.name}". Every product needs '
              'its own SKU.',
        );
        return;
      }
      final open = await _confirm(
        title: 'Product already exists',
        message: 'This barcode belongs to "${existing.name}". Open that '
            'product instead of adding a new one?',
        confirmLabel: 'Open product',
      );
      if (open) Get.offNamed(AppRoutes.productEdit, arguments: existing);
      return;
    }

    skuController.text = code;
  }

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
    final name = _clean(nameController.text);
    if (name.isEmpty) return 'Product name is required.';
    if (name.length > maxNameLength) {
      return 'Product name is too long (max $maxNameLength characters).';
    }
    if (category.value == null) return 'Please choose a category.';
    if (_clean(modelController.text).length > maxModelLength) {
      return 'Model number is too long (max $maxModelLength characters).';
    }
    if (descriptionController.text.trim().length > maxDescriptionLength) {
      return 'Description is too long (max $maxDescriptionLength characters).';
    }

    final sku = normalizeSku(skuController.text);
    final skuError = skuProblem(sku);
    if (skuError != null) return skuError;
    if (isEdit && sku.isEmpty && (editing?.sku ?? '').trim().isNotEmpty) {
      return 'SKU cannot be empty.';
    }

    final retail = _money(retailController.text);
    if (retail == null || retail <= 0) return 'Enter a valid retail price.';
    if (retail > maxPrice) return 'The retail price is too high.';

    if (canViewCost.value) {
      final costText = costController.text.trim();
      if (costText.isNotEmpty) {
        final cost = _money(costText);
        if (cost == null) return 'Enter a valid cost price.';
        if (cost > maxPrice) return 'The cost price is too high.';
      }
    }

    final stock = int.tryParse(stockController.text.trim());
    if (stock == null || stock < 0) {
      return 'Enter the stock quantity (0 or more).';
    }
    if (stock > maxStock) return 'The stock quantity is too high.';

    if (_clean(dimensionsController.text).length > maxDimensionsLength) {
      return 'Dimensions text is too long (max $maxDimensionsLength '
          'characters).';
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
    (canEditCost && costText.isNotEmpty) ? _money(costText) : null;
    final retail = _money(retailController.text)!;
    final sku = normalizeSku(skuController.text);

    if (costPrice != null && costPrice > retail) {
      final ok = await _confirm(
        title: 'Cost is higher than the price',
        message: 'The cost price (${formatMoney(costPrice)}) is higher than '
            'the retail price (${formatMoney(retail)}). Every sale would '
            'lose money. Save anyway?',
        confirmLabel: 'Save anyway',
        cancelLabel: 'Go back',
      );
      if (!ok) return;
    }

    // Photos and the cost price are not part of this map on purpose: photos
    // are managed separately, and the cost price lives in its own
    // owner-only document.
    final data = <String, dynamic>{
      'name': _clean(nameController.text),
      'model': _clean(modelController.text),
      'description': descriptionController.text.trim(),
      'sku': sku, // empty = the repository gives it an automatic SKU
      'category': category.value,
      'retailPrice': retail,
      'units': int.parse(stockController.text.trim()),
      'dimensions': _clean(dimensionsController.text),
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
      final String savedSku;
      if (isEdit) {
        final id = editing?.id ?? '';
        if (id.isEmpty) {
          _showMessage(
            'Cannot save',
            'Open the product from the list to edit it.',
          );
          return;
        }
        savedSku = await _repo.update(
          id,
          data,
          costPrice: costPrice,
          canEditCost: canEditCost,
        );
      } else {
        savedSku = await _repo.create(
          _newId,
          data,
          costPrice: costPrice,
          canEditCost: canEditCost,
        );
      }

      // Go back first, then show the message (a snackbar would otherwise
      // be closed by Get.back()).
      Get.back();
      final generated = sku.isEmpty && savedSku.isNotEmpty;
      _showMessage(
        'Saved',
        generated
            ? 'The product was saved. Its SKU is $savedSku.'
            : 'The product was saved.',
      );
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
  /// Asks before throwing away changes that were not saved.
  Future<void> _confirmLeave() async {
    if (isSaving.value) return;
    if (!isDirty) {
      Get.back();
      return;
    }
    final discard = await _confirm(
      title: 'Discard changes?',
      message: 'You have unsaved changes. If you leave now they will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
    );
    if (discard) Get.back();
  }

  void onDiscardPressed() => _confirmLeave();

  void onBackPressed() => _confirmLeave();

  // ---------------- Messages ----------------
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}