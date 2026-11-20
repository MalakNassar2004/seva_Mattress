import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/utils/dates.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../customers/customer_models.dart' show formatPhone;
import '../owner_shell/owner_nav.dart';
import 'export_models.dart';

/// Data Exports (owner). Opened from the More tab.
/// CSV files are built from the real data and shared with the iPhone share
/// sheet. PDF and Excel are not built yet.
class ExportsController extends GetxController {
  static const int maxOrders = 5000;

  final _db = FirebaseFirestore.instance;

  // ---------------- State ----------------
  final dataset = ExportDataset.sales.obs;
  final format = ExportFormat.csv.obs;
  final range = ExportRange.thisMonth.obs;
  final customRange = Rxn<DateTimeRange>();
  final generating = false.obs;

  /// Exports made since the app was opened.
  final history = <ExportRecord>[].obs;

  // ---------------- Derived ----------------
  DateTimeRange get selectedRange {
    final today = dateOnly(DateTime.now());
    switch (range.value) {
      case ExportRange.thisWeek:
        return DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: today,
        );
      case ExportRange.thisMonth:
        return DateTimeRange(
          start: DateTime(today.year, today.month),
          end: today,
        );
      case ExportRange.lastQuarter:
        final q = (today.month - 1) ~/ 3; // 0..3, current quarter
        final start = DateTime(today.year, q * 3 - 2);
        final end = DateTime(today.year, q * 3 + 1, 0);
        return DateTimeRange(start: start, end: end);
      case ExportRange.custom:
        return customRange.value ??
            DateTimeRange(
              start: today.subtract(const Duration(days: 29)),
              end: today,
            );
    }
  }

  String get rangeText {
    final r = selectedRange;
    return '${range.value.label} (${formatShortDate(r.start)} – '
        '${formatDate(r.end)})';
  }

  // ---------------- Actions ----------------
  void selectDataset(ExportDataset d) => dataset.value = d;
  void selectFormat(ExportFormat f) => format.value = f;

  Future<void> selectRange(ExportRange r) async {
    if (r != ExportRange.custom) {
      range.value = r;
      return;
    }
    final picked = await showDateRangeSheet(initial: selectedRange);
    if (picked == null) return;
    customRange.value = picked;
    range.value = ExportRange.custom;
  }

  // ---------------- CSV helpers ----------------
  /// One CSV cell. Text that starts with = + - @ gets a ' in front, so a
  /// spreadsheet never runs it as a formula. Numbers are written as they are.
  String _cell(Object? v) {
    if (v == null) return '';
    if (v is num) return v is int ? '$v' : v.toStringAsFixed(2);
    var s = v.toString().replaceAll('\r', ' ');
    if (s.isNotEmpty && '=+-@'.contains(s[0])) s = "'$s";
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _csv(List<List<Object?>> rows) =>
      rows.map((r) => r.map(_cell).join(',')).join('\r\n');

  String _money(Object? cents) => (((cents as num?) ?? 0) / 100)
      .toStringAsFixed(2);

  String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  String _day(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  int _c(Object? v) => (v as num?)?.toInt() ?? 0;

  // ---------------- Datasets ----------------
  Future<List<List<Object?>>> _sales(DateTimeRange r) async {
    final from = Timestamp.fromDate(r.start);
    final to = Timestamp.fromDate(
      DateTime(r.end.year, r.end.month, r.end.day + 1),
    );
    final snap = await _db
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: from)
        .where('createdAt', isLessThan: to)
        .orderBy('createdAt')
        .limit(maxOrders)
        .get();

    final rows = <List<Object?>>[
      [
        'Order',
        'Date',
        'Customer',
        'Phone',
        'Status',
        'Subtotal',
        'Discount',
        'GST',
        'PST',
        'Total',
        'Paid',
        'Refunded',
        'Balance',
      ],
    ];
    for (final d in snap.docs) {
      final m = d.data();
      final subtotal = _c(m['subtotalCents']);
      final discount = _c(m['discountCents']);
      final tax = _c(m['taxCents']);
      int gst;
      int pst;
      if (m['gstCents'] == null) {
        gst = ((subtotal - discount) * 500 + 5000) ~/ 10000;
        pst = tax - gst;
      } else {
        gst = _c(m['gstCents']);
        pst = _c(m['pstCents']);
      }
      final total = _c(m['totalCents']);
      final paid = _c(m['paidCents']);
      final cancelled = m['status'] == 'cancelled';
      final at = (m['createdAt'] as Timestamp?)?.toDate();
      final phone = (m['customerPhone'] as String?) ?? '';
      rows.add([
        m['number'] ?? d.id,
        at == null ? '' : _stamp(at),
        m['customerName'] ?? '',
        phone.isEmpty ? '' : formatPhone(phone),
        m['status'] ?? '',
        _money(subtotal),
        _money(discount),
        _money(gst),
        _money(pst),
        _money(total),
        _money(paid),
        _money(m['refundedCents']),
        _money(cancelled ? 0 : (total - paid < 0 ? 0 : total - paid)),
      ]);
    }
    return rows;
  }

  Future<List<List<Object?>>> _customers() async {
    final snap = await _db.collection('customers').get();
    final docs = snap.docs.where((d) => d.data()['deleted'] != true).toList()
      ..sort((a, b) => ((a.data()['seq'] as num?) ?? 0)
          .compareTo((b.data()['seq'] as num?) ?? 0));
    final rows = <List<Object?>>[
      [
        'Number',
        'Name',
        'Phone',
        'Email',
        'City',
        'Address',
        'Orders',
        'Total spent',
        'Balance owing',
        'Created',
      ],
    ];
    for (final d in docs) {
      final m = d.data();
      final phone = (m['phone'] as String?) ?? '';
      final at = (m['createdAt'] as Timestamp?)?.toDate();
      rows.add([
        m['number'] ?? '',
        m['name'] ?? '',
        phone.isEmpty ? '' : formatPhone(phone),
        m['email'] ?? '',
        m['city'] ?? '',
        m['address'] ?? '',
        _c(m['orderCount']),
        _money(m['totalCents']),
        _money(m['balanceCents']),
        at == null ? '' : _day(at),
      ]);
    }
    return rows;
  }

  Future<List<List<Object?>>> _inventory() async {
    final snap = await _db.collection('products').get();

    // Cost prices: only the owner can read them.
    Map<String, double>? costs;
    try {
      final c = await _db.collection('product_costs').get();
      costs = {
        for (final d in c.docs)
          ((d.data()['productId'] as String?) ?? d.id):
              (d.data()['costPrice'] as num?)?.toDouble() ?? 0,
      };
    } catch (_) {
      costs = null;
    }

    final docs = snap.docs.where((d) => d.data()['deleted'] != true).toList()
      ..sort((a, b) => ((a.data()['name'] as String?) ?? '')
          .toLowerCase()
          .compareTo(((b.data()['name'] as String?) ?? '').toLowerCase()));

    final rows = <List<Object?>>[
      [
        'SKU',
        'Name',
        'Category',
        'Active',
        'Warehouse',
        'Showroom',
        'Damaged',
        'Retail price',
        'Retail value',
        if (costs != null) 'Unit cost',
        if (costs != null) 'Cost value',
      ],
    ];
    for (final d in docs) {
      final m = d.data();
      final warehouse = _c(m['units']);
      final showroom = _c(m['showroomUnits']);
      final price = (m['retailPrice'] as num?)?.toDouble() ?? 0;
      final sellable = warehouse + showroom;
      final cost = costs?[d.id];
      rows.add([
        m['sku'] ?? '',
        m['name'] ?? '',
        m['category'] ?? '',
        m['isActive'] == false ? 'No' : 'Yes',
        warehouse,
        showroom,
        _c(m['damagedUnits']),
        price,
        price * sellable,
        if (costs != null) cost ?? 0,
        if (costs != null) (cost ?? 0) * sellable,
      ]);
    }
    return rows;
  }

  String _details(Object? v) {
    if (v is! Map) return '';
    final parts = <String>[];
    v.forEach((k, x) {
      if (x is Map && x.containsKey('to')) {
        parts.add('$k: ${x['from'] ?? '-'} -> ${x['to'] ?? '-'}');
      } else if (x is! Map && x is! List && x != null) {
        parts.add('$k: $x');
      }
    });
    return parts.join(' | ');
  }

  Future<List<List<Object?>>> _audit(DateTimeRange r) async {
    final from = Timestamp.fromDate(r.start);
    final to = Timestamp.fromDate(
      DateTime(r.end.year, r.end.month, r.end.day + 1),
    );
    final snap = await _db
        .collection('audit_log')
        .where('at', isGreaterThanOrEqualTo: from)
        .where('at', isLessThan: to)
        .orderBy('at')
        .limit(5000)
        .get();
    final rows = <List<Object?>>[
      ['Time', 'Who', 'Type', 'Order', 'Details'],
    ];
    for (final d in snap.docs) {
      final m = d.data();
      final at = (m['at'] as Timestamp?)?.toDate();
      rows.add([
        at == null ? '' : _stamp(at),
        m['actorEmail'] ?? '',
        m['type'] ?? '',
        m['orderNumber'] ?? '',
        _details(m['details']),
      ]);
    }
    return rows;
  }

  // ---------------- Generate ----------------
  String _size(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

  String _slug(ExportDataset d) => switch (d) {
    ExportDataset.sales => 'sales-tax',
    ExportDataset.inventory => 'inventory',
    ExportDataset.customers => 'customers',
    ExportDataset.purchases => 'purchasing',
    ExportDataset.audit => 'audit-log',
  };

  Future<void> onGenerate() async {
    if (generating.value) return;
    final d = dataset.value;
    final f = format.value;

    if (f != ExportFormat.csv) {
      showDarkToast(
        '${f.label} export is not available yet. Use CSV.',
        trailing: '',
        info: true,
      );
      return;
    }
    if (d == ExportDataset.purchases) {
      showDarkToast(
        'Purchasing is not used in this app yet',
        trailing: '',
        info: true,
      );
      return;
    }

    generating.value = true;
    try {
      final user = await SessionService().loadCurrentUser();
      if (!(user?.isOwner ?? false)) {
        showDarkToast(
          'Only the owner can export data',
          trailing: '',
          info: true,
        );
        return;
      }

      final r = selectedRange;
      final rows = switch (d) {
        ExportDataset.sales => await _sales(r),
        ExportDataset.customers => await _customers(),
        ExportDataset.inventory => await _inventory(),
        ExportDataset.audit => await _audit(r),
        ExportDataset.purchases => <List<Object?>>[],
      };
      final records = rows.length - 1;

      // UTF-8 with a BOM, so Excel shows Arabic and accents correctly.
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(_csv(rows))];
      final name = '${_slug(d)}_${_day(DateTime.now())}.csv';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);

      final me = FirebaseAuth.instance.currentUser;
      try {
        await _db.collection('audit_log').add({
          'type': 'export_created',
          'name': d.label,
          'details': {
            'format': 'CSV',
            'records': records,
            if (d == ExportDataset.sales || d == ExportDataset.audit)
              'range': '${_day(r.start)} to ${_day(r.end)}',
          },
          'actorUid': me?.uid,
          'actorEmail': me?.email,
          'at': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // The file is made; the log entry is not essential here.
      }

      history.insert(
        0,
        ExportRecord(
          fileName: name,
          dataset: d,
          format: f,
          by: (user?.name.isNotEmpty ?? false)
              ? user!.name
              : (me?.email ?? 'Owner'),
          role: 'Owner',
          device: 'This phone',
          time: DateTime.now(),
          size: _size(bytes.length),
          records: records,
        ),
      );

      showDarkToast('$name is ready ($records records)');

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv', name: name)],
          subject: name,
        ),
      );
    } catch (e) {
      showDarkToast(
        'Could not export: ${e.toString().split('\n').first}',
        trailing: '',
        info: true,
      );
    } finally {
      generating.value = false;
    }
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();
  void onNavTap(int index) => OwnerNav.goToTab(index);
}