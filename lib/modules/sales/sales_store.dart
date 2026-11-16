import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/dates.dart';
import 'sales_mock.dart';
import 'sales_models.dart';

enum SalesPeriod { today, week, month, custom }

extension SalesPeriodInfo on SalesPeriod {
  String get label => switch (this) {
    SalesPeriod.today => 'Today',
    SalesPeriod.week => 'Week',
    SalesPeriod.month => 'Month',
    SalesPeriod.custom => 'Custom',
  };

  /// "vs yesterday", "vs last week"...
  String get compareLabel => switch (this) {
    SalesPeriod.today => 'vs yesterday',
    SalesPeriod.week => 'vs last week',
    SalesPeriod.month => 'vs last month',
    SalesPeriod.custom => 'vs previous period',
  };

  /// Date range ending today. [custom] is used for SalesPeriod.custom.
  DateTimeRange range({DateTimeRange? custom}) {
    final today = dateOnly(DateTime.now());
    return switch (this) {
      SalesPeriod.today => DateTimeRange(start: today, end: today),
      SalesPeriod.week => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      SalesPeriod.month => DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      SalesPeriod.custom => custom ?? DateTimeRange(start: today, end: today),
    };
  }
}

/// Optional product-type and payment-method filters.
class SalesFilter {
  const SalesFilter({required this.range, this.type, this.method});

  final DateTimeRange range;
  final ProductType? type;
  final PayMethod? method;

  /// Same length range just before this one (for the % change chip).
  SalesFilter get previous {
    final days = range.end.difference(range.start).inDays + 1;
    return SalesFilter(
      range: DateTimeRange(
        start: range.start.subtract(Duration(days: days)),
        end: range.start.subtract(const Duration(days: 1)),
      ),
      type: type,
      method: method,
    );
  }
}

/// Totals for a set of sales. Net = Gross − Discounts − Refunds; taxes are
/// shown separately.
class SalesStats {
  double gross = 0;
  double discounts = 0;
  double refunds = 0;
  double taxes = 0;
  double cost = 0;
  double collected = 0;
  double owing = 0;
  int units = 0;
  int sales = 0;
  int refundCount = 0;
  final byMethod = <PayMethod, double>{for (final m in PayMethod.values) m: 0};

  double get net => gross - discounts - refunds;
  double get profit => net - cost;
  bool get isEmpty => sales == 0;

  double methodShare(PayMethod m) {
    final total = byMethod.values.fold<double>(0, (a, b) => a + b);
    return total == 0 ? 0 : byMethod[m]! / total;
  }
}

/// One bar of the sales chart.
class SalesBucket {
  SalesBucket(this.label, this.start, this.end);

  final String label;
  final DateTime start;
  final DateTime end;
  double sales = 0;
  double profit = 0;
  double refunds = 0;
}

class ProductTotal {
  ProductTotal(this.name);

  final String name;
  int units = 0;
  double revenue = 0;
}

/// In-memory invoices shared by Home, Reports and Transactions.
/// TODO(backend): replace with the sales API (reports come pre-aggregated).
class SalesStore extends GetxService {
  static SalesStore get to => Get.isRegistered<SalesStore>()
      ? Get.find<SalesStore>()
      : Get.put(SalesStore(), permanent: true);

  final sales = <Sale>[...SalesMock.sales()].obs;

  Sale? byInvoice(String invoice) =>
      sales.firstWhereOrNull((s) => s.invoice == invoice);

  void save(Sale s) {
    final i = sales.indexWhere((x) => x.invoice == s.invoice);
    if (i >= 0) sales[i] = s;
  }

  // ---------------- Queries ----------------
  bool _inRange(Sale s, DateTimeRange r) {
    final d = dateOnly(s.time);
    return !d.isBefore(r.start) && !d.isAfter(r.end);
  }

  bool _matchesMethod(Sale s, PayMethod? m) =>
      m == null || s.payments.any((p) => p.method == m);

  /// Share of a sale that belongs to the product-type filter (0..1).
  double _share(Sale s, ProductType? type) {
    if (type == null || s.subtotal == 0) return 1;
    final part = s.lines
        .where((l) => l.type == type)
        .fold<double>(0, (a, l) => a + l.total);
    return part / s.subtotal;
  }

  List<Sale> _matching(SalesFilter f) => sales
      .where(
        (s) =>
            s.counts &&
            _inRange(s, f.range) &&
            _matchesMethod(s, f.method) &&
            _share(s, f.type) > 0,
      )
      .toList();

  SalesStats stats(SalesFilter f) {
    final st = SalesStats();
    for (final s in _matching(f)) {
      final k = _share(s, f.type);
      st.sales++;
      st.gross += s.subtotal * k;
      st.discounts += s.discount * k;
      st.taxes += s.taxes * k;
      st.collected += s.paid * k;
      st.owing += s.balance * k;
      st.units += s.lines
          .where((l) => f.type == null || l.type == f.type)
          .fold(0, (a, l) => a + l.qty);
      // Refunds are stored tax-inclusive; report them before tax.
      final refundShare = s.total == 0 ? 0.0 : s.refunded / s.total;
      st.refunds += s.taxable * refundShare * k;
      if (s.refunded > 0) st.refundCount++;
      st.cost +=
          s.lines
              .where((l) => f.type == null || l.type == f.type)
              .fold<double>(0, (a, l) => a + l.costTotal) *
          (1 - refundShare);
      for (final p in s.payments) {
        st.byMethod[p.method] = st.byMethod[p.method]! + p.amount * k;
      }
    }
    return st;
  }

  /// Chart buckets: hours for one day, days up to two weeks, else weeks.
  List<SalesBucket> buckets(SalesFilter f) {
    final r = f.range;
    final days = r.end.difference(r.start).inDays + 1;
    final out = <SalesBucket>[];
    if (days == 1) {
      for (var h = 10; h < 22; h += 2) {
        final start = r.start.add(Duration(hours: h));
        out.add(
          SalesBucket(
            h < 12 ? '${h}a' : '${h == 12 ? 12 : h - 12}p',
            start,
            start.add(const Duration(hours: 2)),
          ),
        );
      }
    } else if (days <= 14) {
      const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      for (var i = 0; i < days; i++) {
        final start = r.start.add(Duration(days: i));
        out.add(
          SalesBucket(
            days <= 7 ? letters[start.weekday - 1] : '${start.day}',
            start,
            start.add(const Duration(days: 1)),
          ),
        );
      }
    } else {
      var start = r.start;
      while (!start.isAfter(r.end)) {
        final end = start.add(const Duration(days: 7));
        out.add(SalesBucket(formatShortDate(start), start, end));
        start = end;
      }
    }
    for (final s in _matching(f)) {
      final b = out.firstWhereOrNull(
        (b) => !s.time.isBefore(b.start) && s.time.isBefore(b.end),
      );
      if (b == null) continue;
      final k = _share(s, f.type);
      final refundShare = s.total == 0 ? 0.0 : s.refunded / s.total;
      final net = (s.taxable - s.taxable * refundShare) * k;
      b.sales += s.taxable * k;
      b.refunds += s.taxable * refundShare * k;
      b.profit += net - s.cost * k * (1 - refundShare);
    }
    return out;
  }

  List<ProductTotal> topProducts(SalesFilter f, {int limit = 5}) {
    final map = <String, ProductTotal>{};
    for (final s in _matching(f)) {
      for (final l in s.lines) {
        if (f.type != null && l.type != f.type) continue;
        final t = map.putIfAbsent(l.name, () => ProductTotal(l.name));
        t.units += l.qty;
        t.revenue += l.total;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return list.take(limit).toList();
  }

  // ---------------- Actions ----------------
  /// Records a refund. It stays "pending" until the payment provider
  /// confirms. TODO(backend): POST /sales/{id}/refunds.
  void refund(Sale s, {required double amount, required bool full}) {
    save(
      s.copyWith(
        refunded: s.refunded + amount,
        refundState: RefundState.pending,
        status: full ? SaleStatus.refunded : s.status,
        timeline: [
          ...s.timeline,
          SaleEvent(
            full ? 'Full refund requested' : 'Partial refund requested',
            'Owner',
            DateTime.now(),
            icon: Icons.undo,
          ),
        ],
      ),
    );
  }

  /// TODO(backend): POST /sales/{id}/void.
  void voidSale(Sale s) {
    save(
      s.copyWith(
        status: SaleStatus.voided,
        timeline: [
          ...s.timeline,
          SaleEvent('Voided', 'Owner', DateTime.now(), icon: Icons.block),
        ],
      ),
    );
  }
}
