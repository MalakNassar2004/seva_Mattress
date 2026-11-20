import 'dart:async';
import 'package:seva_mattress/data/services/payment_methods.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart';
import 'package:seva_mattress/data/repositories/order_repository.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../customers/customer_form_sheet.dart';
import '../customers/customer_models.dart';
import '../products/product_item.dart';
import '../scanner/scanner_view.dart';
import 'order_models.dart';
import 'orders_controller.dart';

/// A product in the order, with its quantity.
class CartLine {
  const CartLine(this.product, this.qty);

  final ProductItem product;
  final int qty;

  int get unitCents => (product.price * 100).round();
  int get totalCents => unitCents * qty;
}

/// What the phone field is doing.
enum PhoneState { empty, incomplete, checking, found, notFound }

/// Create Order / Quote.
/// Arguments: 'order' | 'quote' (new), a QuoteItem (edit), or a CustomerItem
/// (a new order for that customer).
///
/// The customer is found by PHONE. If the phone is new, the customer is saved
/// together with the order. A sale with no customer ("walk-in") is allowed
/// only when it is paid in full. Only the owner can give a discount.
class OrderFormController extends GetxController {
  static const int orderType = 0;
  static const int quoteType = 1;

  static const int maxQty = 99;
  static const int maxLines = 50;

  // Limits of a custom build (inches / degrees).
  static const double minSize = 1;
  static const double maxSize = 300;
  static const double maxAngle = 90;
  static const double minThickness = 0.5;
  static const double maxThickness = 30;

   /// The methods the owner turned on in Settings > Payment methods.
  static List<String> get paymentMethods => PaymentMethodsConfig.enabled;

  /// Quote validity in days (7 / 14 / 30).
  static const List<int> validityOptions = [7, 14, 30];

  final _orders = OrderRepository();
  final _customers = CustomerRepository();
  final _productRepo = ProductRepository();

  /// Created ONCE for this form, so a double tap on Save (or a retry on a bad
  /// connection) can never create two orders or two customers.
  late final String _orderId = _orders.newOrderId();
  late final String _newCustomerId = _orders.newCustomerId();

  final QuoteItem? editing =
      Get.arguments is QuoteItem ? Get.arguments as QuoteItem : null;

  bool get isEdit => editing != null;

  // ---------------- State ----------------
  late final type =
      (Get.arguments == 'quote' || isEdit ? quoteType : orderType).obs;

  // Customer.
  // Not disposed on purpose (see the Login controller note).
  final phoneController = TextEditingController();
  final newNameController = TextEditingController();
  final newCityController = TextEditingController();
  final phoneState = PhoneState.empty.obs;
  final customer = Rxn<CustomerItem>();
  Timer? _debounce;
  int _lookupToken = 0;

  // Items.
  final products = <ProductItem>[].obs;
  final query = ''.obs;
  final lines = <CartLine>[].obs;
  StreamSubscription<List<ProductItem>>? _productsSub;

  // Custom build.
  final isCustom = false.obs;
  final widthController = TextEditingController();
  final lengthController = TextEditingController();
  final angleController = TextEditingController();
  final thicknessController = TextEditingController();
  final notesController = TextEditingController();

  // Discount: only the owner can give one.
  final isOwner = false.obs;
  final discountPercent = true.obs; // true = percent, false = amount in CAD
  final discountController = TextEditingController();
  final discountReasonController = TextEditingController();
  final discountInput = 0.0.obs;

  // Payment.
  final depositController = TextEditingController();
  final deposit = 0.0.obs;
  final depositMethodIndex = 1.obs; // Cash

  // Dates. Only the day matters.
  final nextPaymentDate = Rxn<DateTime>();
  final deliveryDate = Rxn<DateTime>();

  final validityIndex = 1.obs;

  final isSaving = false.obs;
  final error = RxnString();

  /// Tax rates in basis points (500 = 5%). They come from the store settings
  /// (settings/company) and are saved on every order, so a later change of a
  /// rate does not touch old orders.
  final gstBp = 500.obs;
  final pstBp = 700.obs;

  @override
  void onInit() {
    super.onInit();

    // The current tax rates (the defaults are used if they cannot be read).
    CompanyRepository().load().then((c) {
      gstBp.value = c.gstBp;
         pstBp.value = c.pstBp;
      // The enabled payment methods are known now: pick Cash (or the first).
      final cash = paymentMethods.indexOf('Cash');
      depositMethodIndex.value = cash >= 0 ? cash : 0;
      depositMethodIndex.refresh();
    });

    // Only the owner can give a discount.
    SessionService().loadCurrentUser().then((u) {
      isOwner.value = u?.isOwner ?? false;
    }).catchError((Object _) {});

    // Opened from a customer page: that customer is already chosen.
    final arg = Get.arguments;
    if (arg is CustomerItem) {
      phoneController.text = arg.phone;
      customer.value = arg;
      phoneState.value = PhoneState.found;
    }

    _productsSub = _productRepo.watchProducts().listen(
      (list) => products.assignAll(list.where((p) => p.isActive)),
      onError: (Object e) => error.value = describeError(e),
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _productsSub?.cancel();
    super.onClose();
  }

  // ---------------- Amounts ----------------
  int get subtotalCents => lines.fold(0, (a, l) => a + l.totalCents);
  double get subtotal => subtotalCents / 100;

  /// The discount in cents. Only the owner can give one: it is 0 for anybody
  /// else.
  int get discountCents {
    if (!isOwner.value) return 0;
    final v = discountInput.value;
    if (v <= 0 || subtotalCents <= 0) return 0;
    return discountPercent.value
        ? (subtotalCents * v / 100).round()
        : (v * 100).round();
  }

  double get discount => discountCents / 100;

  /// What the tax is worked out on: the items minus the discount.
  int get taxableCents {
    final t = subtotalCents - discountCents;
    return t < 0 ? 0 : t;
  }

  /// GST and PST are each rounded to the nearest cent on their own.
  int get gstCents => (taxableCents * gstBp.value + 5000) ~/ 10000;
  int get pstCents => (taxableCents * pstBp.value + 5000) ~/ 10000;
  double get gst => gstCents / 100;
  double get pst => pstCents / 100;

  int get taxBp => gstBp.value + pstBp.value;
  int get taxCents => gstCents + pstCents;
  double get tax => taxCents / 100;
  int get totalCents => taxableCents + taxCents;
  double get total => totalCents / 100;
  int get itemCount => lines.fold(0, (a, l) => a + l.qty);

  static String _pct(int bp) =>
      bp % 100 == 0 ? '${bp ~/ 100}%' : '${(bp / 100).toStringAsFixed(2)}%';

  /// "GST (5%)" and "PST (7%)", as printed in the summary.
  String get gstLabel => 'GST (${_pct(gstBp.value)})';
  String get pstLabel => 'PST (${_pct(pstBp.value)})';

  int get _depositCents => (deposit.value * 100).round();

  /// True while something is left to pay after today's payment, so the next
  /// payment date is needed.
  bool get needsNextPayment => totalCents > 0 && _depositCents < totalCents;

  // ---------------- Discount ----------------
  void setDiscountKind(bool percent) {
    discountPercent.value = percent;
    error.value = null;
  }

  void onDiscountChanged(String v) {
    discountInput.value =
        double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;
    error.value = null;
  }

  // ---------------- Customer ----------------
  void onPhoneChanged(String v) {
    error.value = null;
    _debounce?.cancel();
    customer.value = null;

    if (v.trim().isEmpty) {
      phoneState.value = PhoneState.empty;
      return;
    }
    final key = normalizePhone(v);
    if (key == null) {
      phoneState.value = PhoneState.incomplete;
      return;
    }

    phoneState.value = PhoneState.checking;
    final token = ++_lookupToken;
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _lookup(key, token),
    );
  }

  Future<void> _lookup(String key, int token) async {
    try {
      final found = await _customers.findByPhone(key);
      if (token != _lookupToken) return; // the phone changed meanwhile
      if (found == null) {
        phoneState.value = PhoneState.notFound;
        return;
      }
      await _select(found, token);
    } catch (e) {
      if (token != _lookupToken) return;
      phoneState.value = PhoneState.incomplete;
      error.value = describeCustomerError(e);
    }
  }

  Future<void> _select(CustomerItem c, int token) async {
    var chosen = c;
    if (c.city.trim().isEmpty) {
      // An older customer saved without a city: complete it first.
      final updated = await CustomerFormSheet.open(editing: c);
      if (token != _lookupToken) return;
      if (updated == null) {
        phoneState.value = PhoneState.incomplete;
        error.value = 'This customer needs a city before an order can be '
            'created.';
        return;
      }
      chosen = updated;
    }
    customer.value = chosen;
    phoneState.value = PhoneState.found;
  }

  /// "+ New": opens the full customer form and uses the saved customer.
  Future<void> onAddCustomerPressed() async {
    final saved = await CustomerFormSheet.open(
      initialPhone: phoneController.text.trim(),
    );
    if (saved == null) return;
    phoneController.text = saved.phone;
    customer.value = saved;
    phoneState.value = PhoneState.found;
    error.value = null;
  }

  // ---------------- Items ----------------
  void onProductQueryChanged(String v) => query.value = v;

  /// The products that match the search (at most 8).
  List<ProductItem> get results {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final list = products
        .where((p) => [p.name, p.sku, p.model]
            .any((s) => s.toLowerCase().contains(q)))
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list.take(8).toList();
  }

  void addProduct(ProductItem p) {
    error.value = null;
    final i = lines.indexWhere((l) => l.product.id == p.id);
    if (i >= 0) {
      incrementAt(i);
      return;
    }
    if (lines.length >= maxLines) {
      error.value = 'An order can have at most $maxLines different products.';
      return;
    }
    lines.add(CartLine(p, 1));
  }

  void incrementAt(int i) {
    final l = lines[i];
    if (l.qty >= maxQty) return;
    lines[i] = CartLine(l.product, l.qty + 1);
    error.value = null;
  }

  void decrementAt(int i) {
    final l = lines[i];
    if (l.qty <= 1) {
      lines.removeAt(i);
    } else {
      lines[i] = CartLine(l.product, l.qty - 1);
    }
  }

  /// Scan a barcode and add that product.
  Future<void> onScanProduct() async {
    final raw = await ScannerView.scan();
    if (raw == null) return;
    final code = normalizeSku(raw);
    if (code.isEmpty) return;
    for (final p in products) {
      if (normalizeSku(p.sku) == code) {
        addProduct(p);
        return;
      }
    }
    error.value = 'No product has the SKU $code.';
  }

  // ---------------- Payment ----------------
  void selectType(int i) => type.value = i;

  void toggleCustom(bool v) => isCustom.value = v;

  void selectValidity(int i) => validityIndex.value = i;

  void selectDepositMethod(int i) => depositMethodIndex.value = i;

  void onDepositChanged(String v) =>
      deposit.value = double.tryParse(v.replaceAll(',', '')) ?? 0;

  void _setDeposit(double v) {
    deposit.value = v;
    depositController.text = v <= 0 ? '' : v.toStringAsFixed(2);
  }

  void onPayFull() => _setDeposit(total);

  void onPayHalf() => _setDeposit((totalCents / 2).round() / 100);

  void onNoDeposit() => _setDeposit(0);

  // ---------------- Dates ----------------
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<DateTime?> _pickDate(DateTime? current, int defaultDays) {
    final today = _today;
    var initial = current ?? today.add(Duration(days: defaultDays));
    if (initial.isBefore(today)) initial = today;
    return showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
  }

  Future<void> pickNextPaymentDate() async {
    final picked = await _pickDate(nextPaymentDate.value, 14);
    if (picked == null) return;
    nextPaymentDate.value = DateTime(picked.year, picked.month, picked.day);
    error.value = null;
  }

  Future<void> pickDeliveryDate() async {
    final picked = await _pickDate(deliveryDate.value, 7);
    if (picked == null) return;
    deliveryDate.value = DateTime(picked.year, picked.month, picked.day);
    error.value = null;
  }

  void clearDeliveryDate() => deliveryDate.value = null;

  // ---------------- Save ----------------
  String _clean(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  double? _number(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// "Mattresses · Queen · SKU MAT-1"
  String _details(ProductItem p) => [
        p.category,
        if (p.category == 'Mattresses') p.size,
        if (p.sku.isNotEmpty) 'SKU ${p.sku}',
      ].join(' · ');

  /// Checks the custom build. Returns the problem, or null when it is fine.
  String? _customProblem() {
    final width = _number(widthController.text);
    final length = _number(lengthController.text);
    if (width == null || length == null) {
      return 'Enter the width and length of the custom build';
    }
    if (width < minSize || width > maxSize) {
      return 'The width must be between ${minSize.toInt()} and '
          '${maxSize.toInt()} inches';
    }
    if (length < minSize || length > maxSize) {
      return 'The length must be between ${minSize.toInt()} and '
          '${maxSize.toInt()} inches';
    }
    if (angleController.text.trim().isNotEmpty) {
      final angle = _number(angleController.text);
      if (angle == null || angle < 0 || angle > maxAngle) {
        return 'The cut angle must be between 0 and ${maxAngle.toInt()} degrees';
      }
    }
    if (thicknessController.text.trim().isNotEmpty) {
      final t = _number(thicknessController.text);
      if (t == null || t < minThickness || t > maxThickness) {
        return 'The thickness must be between $minThickness and '
            '${maxThickness.toInt()} inches';
      }
    }
    return null;
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps
    FocusManager.instance.primaryFocus?.unfocus();

    if (type.value == quoteType) {
      error.value = 'Quotes are not available yet. Create an order instead.';
      return;
    }
    if (lines.isEmpty) {
      error.value = 'Add at least one item';
      return;
    }

    if (isCustom.value) {
      final problem = _customProblem();
      if (problem != null) {
        error.value = problem;
        return;
      }
    }

    // ---- discount (only the owner has one) ----
    final discountC = discountCents;
    final percent = discountPercent.value;
    final dv = discountInput.value;
    final discountReason = _clean(discountReasonController.text);
    if (discountC > 0) {
      if (percent && (dv > 100 || (dv * 100).round() < 1)) {
        error.value = 'Enter a discount between 0.01% and 100%';
        return;
      }
      if (discountC >= subtotalCents) {
        error.value = 'The discount cannot be the whole order';
        return;
      }
      if (discountReason.length < 3) {
        error.value = 'Write the reason for the discount';
        return;
      }
    }

    final totalC = totalCents;
    final depositC = _depositCents;
    if (depositC > totalC) {
      error.value = 'Deposit is more than the order total';
      return;
    }

    // ---- dates ----
    final today = _today;
    DateTime? nextDate;
    if (depositC < totalC) {
      nextDate = nextPaymentDate.value;
      if (nextDate == null) {
        error.value = 'Choose the date of the next payment';
        return;
      }
      if (nextDate.isBefore(today)) {
        error.value = 'The next payment date cannot be in the past';
        return;
      }
    }
    final delivery = deliveryDate.value;
    if (delivery != null && delivery.isBefore(today)) {
      error.value = 'The delivery date cannot be in the past';
      return;
    }

    // ---- customer ----
    final phoneText = phoneController.text.trim();
    String? existingId;
    NewCustomerInput? newCustomer;

    if (phoneText.isEmpty) {
      final paidInFull = totalC > 0 && depositC >= totalC;
      if (isCustom.value || !paidInFull) {
        error.value = 'Add the customer phone. Only a walk-in sale that is '
            'paid in full can be saved without a customer.';
        return;
      }
    } else {
      final key = normalizePhone(phoneText);
      if (key == null) {
        error.value = 'Enter a valid customer phone number';
        return;
      }
      switch (phoneState.value) {
        case PhoneState.found:
          existingId = customer.value?.id;
          if (existingId == null || existingId.isEmpty) {
            error.value = 'Check the customer phone number';
            return;
          }
          break;
        case PhoneState.notFound:
          final name = _clean(newNameController.text);
          final city = _clean(newCityController.text);
          if (name.isEmpty) {
            error.value = 'Enter the name of the new customer';
            return;
          }
          if (city.length < 2) {
            error.value = 'Enter the city of the new customer';
            return;
          }
          newCustomer = NewCustomerInput(
            id: _newCustomerId,
            name: name,
            phoneKey: key,
            city: city,
          );
          break;
        case PhoneState.checking:
          error.value = 'Looking for the customer. Try again in a moment.';
          return;
        default:
          error.value = 'Check the customer phone number';
          return;
      }
    }

    final inputs = [
      for (final l in lines)
        OrderLineInput(
          productId: l.product.id,
          sku: l.product.sku,
          name: l.product.name,
          details: _details(l.product),
          unitCents: l.unitCents,
          qty: l.qty,
          trackStock: !l.product.customSize,
        ),
    ];

    isSaving.value = true;
    try {
      final created = await _orders.createOrder(
        orderId: _orderId,
        lines: inputs,
        customerId: existingId,
        newCustomer: newCustomer,
        gstBp: gstBp.value,
        pstBp: pstBp.value,
        isCustom: isCustom.value,
        spec: isCustom.value
            ? {
                'width': widthController.text.trim(),
                'length': lengthController.text.trim(),
                'angle': angleController.text.trim(),
                'thickness': thicknessController.text.trim(),
                'notes': notesController.text.trim(),
              }
            : null,
        depositCents: depositC,
        depositMethod: paymentMethods[
            depositMethodIndex.value.clamp(0, paymentMethods.length - 1)],        nextPaymentDate: nextDate,
        deliveryDate: delivery,
        discountCents: discountC,
        discountKind: discountC > 0 ? (percent ? 'percent' : 'amount') : '',
        discountValue:
            discountC > 0 ? (percent ? (dv * 100).round() : discountC) : 0,
        discountReason: discountC > 0 ? discountReason : '',
      );

      if (Get.isRegistered<OrdersController>()) {
        final oc = Get.find<OrdersController>();
        oc.segment.value = OrdersController.ordersSegment;
        oc.statusFilterIndex.value = 0;
      }
      // Open the new order (to take the next payment or print the invoice).
      Get.offNamed(AppRoutes.orderDetail, arguments: created);
    } catch (e) {
      error.value = describeCustomerError(e);
    } finally {
      isSaving.value = false;
    }
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();
}