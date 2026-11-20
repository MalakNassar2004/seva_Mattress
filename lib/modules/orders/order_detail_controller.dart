import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart' show Printing;
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show CustomerRepository, describeCustomerError;
import 'package:seva_mattress/data/repositories/order_repository.dart';
import 'package:seva_mattress/data/services/invoice_service.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/money.dart';
import 'change_status_sheet.dart';
import 'order_models.dart';
import 'record_payment_sheet.dart';
import 'refund_sheet.dart';

/// Order detail. Opened with the OrderItem (from the list) as arguments, then
/// it follows the live order, payments and timeline from Firestore.
class OrderDetailController extends GetxController {
  /// Stepper labels, in order.
  static const List<String> steps = [
    'Placed',
    'Deposit',
    'In Production',
    'Ready',
    'Out for Delivery',
    'Delivered',
  ];

  final _repo = OrderRepository();
  final _company = CompanyRepository();
  final _invoice = const InvoiceService();

  final OrderItem? _source =
      Get.arguments is OrderItem ? Get.arguments as OrderItem : null;

  String get orderId => _source?.id ?? '';

  // ---------------- State ----------------
  late final Rx<OrderDetail> detail = Rx<OrderDetail>(_placeholder());
  late final status = (_source?.status ?? OrderStatus.newOrder).obs;
  final payments = <PaymentRecord>[].obs;
  final timeline = <TimelineEvent>[].obs;

  final subtotalCents = 0.obs;
  final taxCents = 0.obs;
  final totalCents = 0.obs;
  final paidCents = 0.obs;
  final isBusy = false.obs;

  /// The discount given on this order (cents). 0 when there is none.
  final discountCents = 0.obs;
  /// The tax is shown in two parts: GST and PST (rates in basis points).
  final gstCents = 0.obs;
  final pstCents = 0.obs;
  final gstBp = 500.obs;
  final pstBp = 700.obs;

  /// When the next payment is due, and when the order is to be delivered.
  final nextPaymentDate = Rxn<DateTime>();
  final deliveryDate = Rxn<DateTime>();

  /// The order document as it is in Firestore (used to build the invoice).
  Map<String, dynamic> _raw = {};

  /// Company name used in the subject of the invoice email.
  String _companyName = '';

  String get number => detail.value.number;
  String get customer => detail.value.customer;

  double get subtotal => subtotalCents.value / 100;
  double get tax => taxCents.value / 100;
  double get gst => gstCents.value / 100;
  double get pst => pstCents.value / 100;
    double get discount => discountCents.value / 100;

  /// "Discount (10%)" for a percent discount, else "Discount".
  String get discountLabel {
    final kind = (_raw['discountKind'] as String?) ?? '';
    final v = (_raw['discountValue'] as num?)?.toInt() ?? 0;
    if (kind == 'percent' && v > 0) return 'Discount (${_pct(v)})';
    return 'Discount';
  }
  double get total => totalCents.value / 100;
  double get paid => paidCents.value / 100;
  double get balance =>
      ((totalCents.value - paidCents.value) / 100).clamp(0, double.infinity);
  double get paidRatio =>
      totalCents.value == 0 ? 0 : (paidCents.value / totalCents.value).clamp(0, 1);

  static String _pct(int bp) =>
      bp % 100 == 0 ? '${bp ~/ 100}%' : '${(bp / 100).toStringAsFixed(2)}%';

  /// "GST (5%)" and "PST (7%)", as shown in the price breakdown.
  String get gstLabel => 'GST (${_pct(gstBp.value)})';
  String get pstLabel => 'PST (${_pct(pstBp.value)})';

  /// The line under "Balance owing": when the next payment is due.
  String get nextPaymentLabel {
    final d = nextPaymentDate.value;
    if (d == null) return 'No next payment date set';
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final days = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (days < 0) return 'Overdue since ${fmtOrderDate(d)}';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Next payment due ${fmtOrderDate(d)}';
  }

  /// Index of the current step in [steps]. All done when Delivered.
  int get currentStep => switch (status.value) {
        OrderStatus.newOrder => paid > 0 ? 2 : 1,
        OrderStatus.inProduction => 2,
        OrderStatus.ready => 3,
        OrderStatus.outForDelivery => 4,
        OrderStatus.delivered => steps.length,
        OrderStatus.cancelled => -1,
      };

  /// Created once per payment, so a retry cannot record it twice.
  String? _paymentId;

  StreamSubscription<Map<String, dynamic>?>? _orderSub;
  StreamSubscription<List<PaymentRecord>>? _paymentsSub;
  StreamSubscription<List<TimelineEvent>>? _eventsSub;

  OrderDetail _placeholder() => OrderDetail(
        number: _source?.number ?? '',
        customer: _source?.customer ?? '',
        store: 'Showroom',
        placed: '',
        status: _source?.status ?? OrderStatus.newOrder,
        spec: null,
        lines: const [],
        taxRate: 0.12,
        payments: const [],
        destination: '',
        destinationNote: '',
        deliveryWindow: 'Not scheduled',
        deliveryTeam: 'Not assigned',
        timeline: const [],
      );

  @override
  void onInit() {
    super.onInit();
    if (orderId.isEmpty) return;
    _orderSub = _repo.watchOrder(orderId).listen(_onOrder, onError: _onError);
    _paymentsSub = _repo.watchPayments(orderId).listen(
          (list) => payments.assignAll(list),
      onError: _onError,
    );
    _eventsSub = _repo.watchEvents(orderId).listen(
          (list) => timeline.assignAll(list),
      onError: _onError,
    );
  }

  @override
  void onClose() {
    _orderSub?.cancel();
    _paymentsSub?.cancel();
    _eventsSub?.cancel();
    super.onClose();
  }

  void _onError(Object e) =>
      _showMessage('Could not load the order', describeCustomerError(e));

  void _onOrder(Map<String, dynamic>? m) {
    if (m == null) return;
    _raw = Map<String, dynamic>.from(m);

    final st = orderStatusFrom(m['status'] as String?);
    status.value = st;
    subtotalCents.value = (m['subtotalCents'] as num?)?.toInt() ?? 0;
    taxCents.value = (m['taxCents'] as num?)?.toInt() ?? 0;
    totalCents.value = (m['totalCents'] as num?)?.toInt() ?? 0;
    paidCents.value = (m['paidCents'] as num?)?.toInt() ?? 0;
        discountCents.value = (m['discountCents'] as num?)?.toInt() ?? 0;

    // GST and PST. An order saved before the tax was split has only the
    // total: it is shown as GST 5% and the rest as PST.
    final taxBpValue = (m['taxBp'] as num?)?.toInt() ?? 1200;
    if (m['gstCents'] == null) {
      final g = (subtotalCents.value * 500 + 5000) ~/ 10000;
      gstBp.value = 500;
      pstBp.value = taxBpValue > 500 ? taxBpValue - 500 : 0;
      gstCents.value = g;
      pstCents.value = taxCents.value - g;
    } else {
      gstBp.value = (m['gstBp'] as num?)?.toInt() ?? 500;
      pstBp.value = (m['pstBp'] as num?)?.toInt() ?? 700;
      gstCents.value = (m['gstCents'] as num?)?.toInt() ?? 0;
      pstCents.value = (m['pstCents'] as num?)?.toInt() ?? 0;
    }

    nextPaymentDate.value = (m['nextPaymentDate'] as Timestamp?)?.toDate();
    final delivery = (m['deliveryDate'] as Timestamp?)?.toDate();
    deliveryDate.value = delivery;

    final created = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final rawLines = (m['lines'] as List?) ?? const [];
    final city = (m['customerCity'] as String?) ?? '';
    final address = (m['customerAddress'] as String?) ?? '';

    detail.value = OrderDetail(
      number: (m['number'] as String?) ?? '',
      customer: (m['customerName'] as String?) ?? '',
      store: 'Showroom',
      placed: 'Placed ${fmtOrderDate(created)}',
      status: st,
      spec: specFromMap(m, st),
      lines: [
        for (final l in rawLines)
          orderLineFromMap(Map<String, dynamic>.from(l as Map)),
      ],
      taxRate: taxBpValue / 10000,
      payments: const [],
      destination: address.isNotEmpty
          ? address
          : (city.isNotEmpty ? city : 'Not set'),
      destinationNote: '',
      deliveryWindow:
          delivery == null ? 'Not scheduled' : fmtOrderDate(delivery),
      deliveryTeam: 'Not assigned',
      timeline: const [],
    );
  }

  // ---------------- Actions ----------------
  Future<void> onChangeStatusPressed() async {
    if (isBusy.value || orderId.isEmpty) return;
    final result = await ChangeStatusSheet.open(status.value);
    if (result == null || result.status == status.value) return;

    if (result.status == OrderStatus.cancelled) {
      var allowed = false;
      try {
        final user = await SessionService().loadCurrentUser();
        allowed = (user?.isOwner ?? false) || (user?.isManager ?? false);
      } catch (_) {
        allowed = false;
      }
      if (!allowed) {
        _showMessage(
          'Not allowed',
          'Only the owner or a manager can cancel an order.',
        );
        return;
      }
    }

    isBusy.value = true;
    try {
      await _repo.changeStatus(
        orderId: orderId,
        newStatus: result.status.name,
        note: result.note,
      );
      _showMessage(
        'Status updated',
        result.notifyCustomer
            ? 'SMS and email notifications are not available yet.'
            : 'The order is now ${result.status.label}.',
      );
    } catch (e) {
      _showMessage('Could not update', describeCustomerError(e));
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> onRecordPaymentPressed() async {
    if (isBusy.value || orderId.isEmpty) return;
    final record = await RecordPaymentSheet.open(balance: balance);
    if (record == null) return;

    // "Card · 4102" -> method "Card", reference "4102".
    final parts = record.method.split(' · ');
    final method = parts.first;
    final reference = parts.length > 1 ? parts.sublist(1).join(' · ') : '';

    isBusy.value = true;
    try {
      _paymentId ??= _repo.newPaymentId(orderId);
      await _repo.recordPayment(
        orderId: orderId,
        paymentId: _paymentId!,
        amountCents: (record.amount * 100).round(),
        method: method,
        reference: reference,
        nextPaymentDate: record.nextDate,
      );
      _paymentId = null; // done: the next payment gets a new id
      _showMessage('Payment recorded', 'The payment was saved.');
    } catch (e) {
      _showMessage('Could not record the payment', describeCustomerError(e));
    } finally {
      isBusy.value = false;
    }
  }

   /// The "..." button of the order: refund.
  Future<void> onMorePressed() =>
      RefundFlow.start(orderId: orderId, order: _raw);

  void onBlueprintPressed() {
    // TODO: open the cutting blueprint PDF.
  }

  void onServiceAreaPressed() {
    // TODO: show the delivery zone on a map.
  }

  // ---------------- Invoice ----------------
  String get _fileName {
    final n = number.isEmpty ? orderId : number;
    return 'Invoice-$n';
  }

  /// Builds the invoice PDF of this order (null when it cannot be built).
  Future<Uint8List?> _buildInvoice() async {
    if (_raw.isEmpty) {
      _showMessage('Please wait', 'The order is still loading.');
      return null;
    }
    try {
      final company = await _company.load();
      _companyName = company.name;
      return await _invoice.build(
        company: company,
        order: _raw,
        payments: payments.toList(),
      );
    } catch (e) {
      _showMessage('Could not create the invoice', describeCustomerError(e));
      return null;
    }
  }

  /// The email saved for the customer of this order ('' when there is none).
  Future<String> _customerEmail() async {
    final id = (_raw['customerId'] as String?) ?? '';
    if (id.isEmpty) return '';
    try {
      final c = await CustomerRepository().watchCustomer(id).first;
      return (c?.email ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  /// Print Invoice: shows the invoice and the printers (AirPrint).
  Future<void> onPrintInvoicePressed() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final bytes = await _buildInvoice();
      if (bytes == null) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _fileName,
      );
    } catch (e) {
      _showMessage('Could not print', describeCustomerError(e));
    } finally {
      isBusy.value = false;
    }
  }

  /// Email Customer: opens the mail composer with the customer's email in
  /// "To" and the invoice PDF attached. If no mail composer can be opened,
  /// the share sheet is shown instead, so the invoice is never lost.
  Future<void> onEmailCustomerPressed() async {
    if (isBusy.value) return;
    isBusy.value = true;
    File? file;
    try {
      final bytes = await _buildInvoice();
      if (bytes == null) return;

      final to = await _customerEmail();
      if (to.isEmpty) {
        _showMessage(
          'No email saved',
          'This customer has no email. Type it in the message, or add it '
              'from the customer page (Edit).',
        );
      }

      file = File('${Directory.systemTemp.path}/$_fileName.pdf');
      await file.writeAsBytes(bytes, flush: true);

      final lines = <String>[
        'Hello ${customer.isEmpty ? '' : customer},',
        '',
        'Please find your invoice $number attached.',
        'Total: ${formatCad(total)} CAD',
        'Paid: ${formatCad(paid)} CAD',
        if (balance > 0.004) 'Balance due: ${formatCad(balance)} CAD',
        '',
        'Thank you,',
        if (_companyName.isNotEmpty) _companyName,
      ];

      try {
        await FlutterEmailSender.send(
          Email(
            recipients: to.isEmpty ? const [] : [to],
            subject: _companyName.isEmpty
                ? 'Invoice $number'
                : 'Invoice $number - $_companyName',
            body: lines.join('\n'),
            attachmentPaths: [file.path],
          ),
        );
      } catch (e) {
        // No mail composer on this device: use the share sheet.
        debugPrint('EMAIL ERROR: $e');
        await Printing.sharePdf(bytes: bytes, filename: '$_fileName.pdf');
      }
    } catch (e) {
      _showMessage('Could not email the invoice', describeCustomerError(e));
    } finally {
      try {
        await file?.delete();
      } catch (_) {}
      isBusy.value = false;
    }
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  /// Delivery team row: opens today's dispatch board.
  void onDeliveriesPressed() => Get.toNamed(AppRoutes.deliveries);

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}