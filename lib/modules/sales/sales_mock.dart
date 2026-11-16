import 'package:flutter/material.dart';
import 'sales_models.dart';

/// Demo invoices, dated relative to today so Today / Week / Month always
/// have data. The first few match the designs; the rest are generated with
/// a fixed seed so numbers stay the same between runs.
/// TODO(backend): remove when sales are loaded from the API.
class SalesMock {
  SalesMock._();

  static DateTime _at(int daysAgo, int hour, int minute) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - daysAgo, hour, minute);
  }

  // ---------------- Catalog ----------------
  static const hybridQueen = SaleLine(
    name: 'Seva Hybrid Luxury Queen',
    size: 'Queen 60×80',
    qty: 1,
    price: 1899,
    cost: 680,
    type: ProductType.mattress,
  );
  static const latexKing = SaleLine(
    name: 'Cloud Rest Latex King',
    size: 'King 76×80',
    qty: 1,
    price: 2199,
    cost: 910,
    type: ProductType.mattress,
  );
  static const bambooPillow = SaleLine(
    name: 'Cloud Bamboo Pillow',
    size: 'Standard',
    qty: 2,
    price: 225.25,
    cost: 70,
    type: ProductType.pillow,
  );
  static const gelPillow = SaleLine(
    name: 'Cooling Gel Contour Pillow',
    size: 'Standard',
    qty: 1,
    price: 133,
    cost: 41,
    type: ProductType.pillow,
  );
  static const protectorQueen = SaleLine(
    name: 'Cloud Mattress Protector',
    size: 'Queen',
    qty: 1,
    price: 149,
    cost: 38,
    type: ProductType.protector,
  );
  static const woolTopper = SaleLine(
    name: 'Organic Wool Mattress Topper',
    size: 'Double 54×75',
    qty: 1,
    price: 758,
    cost: 290,
    type: ProductType.accessory,
  );
  static const customRv = SaleLine(
    name: 'Custom RV Short Queen',
    size: 'Custom 60×74',
    qty: 1,
    price: 1640,
    cost: 720,
    type: ProductType.customSize,
  );

  static const _catalog = [
    hybridQueen,
    latexKing,
    bambooPillow,
    gelPillow,
    protectorQueen,
    woolTopper,
    customRv,
  ];

  static const _customers = [
    'Marcus Vance',
    'Elena Rostova',
    'David Chen',
    'Sophia Patel',
    'Noah Williams',
    'Ava Thompson',
    'Liam Gill',
    'Mia Johal',
    'Ethan Brown',
    'Olivia Singh',
    'Lucas Martin',
    'Chloe Wong',
  ];
  static const _cashiers = [
    'Sara Lee',
    'Marcus Vance',
    'Daniel Kim',
    'Liam Bennett',
  ];

  static SalePayment _card(double amount, String last4) => SalePayment(
    method: PayMethod.card,
    label: 'Visa •••• $last4',
    reference: 'AUTH-${last4}7Q',
    amount: amount,
  );

  static List<Sale> sales() {
    final list = <Sale>[
      _make(
        invoice: 'SM-10482',
        customer: 'Marcus Vance',
        cashier: 'Sara Lee',
        time: _at(0, 14, 15),
        lines: const [hybridQueen, bambooPillow],
        note: 'Walk-in VIP · Express Surrey delivery',
        pay: (t) => [_card(t, '4892')],
      ),
      _make(
        invoice: 'SM-10481',
        customer: 'Elena Rostova',
        cashier: 'Marcus Vance',
        time: _at(0, 11, 40),
        lines: const [latexKing],
        note: 'Scheduled delivery · custom foundation',
        status: SaleStatus.deposit,
        pay: (t) => const [
          SalePayment(
            method: PayMethod.other,
            label: 'Interac Debit',
            reference: 'INT-55120',
            amount: 1000,
          ),
        ],
      ),
      _make(
        invoice: 'SM-10480',
        customer: 'Noah Williams',
        cashier: 'Daniel Kim',
        time: _at(0, 10, 25),
        lines: const [protectorQueen, gelPillow],
        pay: (t) => [
          SalePayment(
            method: PayMethod.cash,
            label: 'Cash',
            reference: 'Drawer #1',
            amount: t,
          ),
        ],
      ),
      _make(
        invoice: 'SM-10479',
        customer: 'David Chen',
        cashier: 'Sara Lee',
        time: _at(1, 16, 20),
        lines: const [gelPillow],
        note: '100-night comfort trial',
        status: SaleStatus.refunded,
        refundAll: true,
        pay: (t) => [_card(t, '3910')],
      ),
      _make(
        invoice: 'SM-10478',
        customer: 'Sophia Patel',
        cashier: 'Sara Lee',
        time: _at(1, 13, 15),
        lines: const [woolTopper],
        note: 'In-store pick-up',
        pay: (t) => [
          SalePayment(
            method: PayMethod.card,
            label: 'Mastercard •••• 1042',
            reference: 'AUTH-10427Q',
            amount: t,
          ),
        ],
      ),
    ];

    // Generated history for the last 5 weeks.
    var seed = 7;
    int next(int max) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed % max;
    }

    var number = 10477;
    for (var day = 1; day <= 34; day++) {
      final count = 1 + next(3);
      for (var i = 0; i < count; i++) {
        final a = _catalog[next(_catalog.length)];
        final lines = <SaleLine>[a];
        if (next(3) == 0) {
          final b = _catalog[2 + next(3)];
          if (b.name != a.name) lines.add(b);
        }
        final method = PayMethod.values[next(10) < 7 ? 0 : (next(2) + 1)];
        final voided = next(25) == 0;
        list.add(
          _make(
            invoice: 'SM-${number--}',
            customer: _customers[next(_customers.length)],
            cashier: _cashiers[next(_cashiers.length)],
            time: _at(day, 10 + next(9), next(60)),
            lines: lines,
            discount: next(4) == 0 ? 50.0 * (1 + next(3)) : 0,
            status: voided ? SaleStatus.voided : SaleStatus.paid,
            pay: (t) => voided
                ? const []
                : [
                    switch (method) {
                      PayMethod.card => _card(t, '${1000 + next(9000)}'),
                      PayMethod.cash => SalePayment(
                        method: PayMethod.cash,
                        label: 'Cash',
                        reference: 'Drawer #1',
                        amount: t,
                      ),
                      PayMethod.other => SalePayment(
                        method: PayMethod.other,
                        label: 'Financing',
                        reference: 'FIN-${next(90000)}',
                        amount: t,
                      ),
                    },
                  ],
          ),
        );
      }
    }
    return list;
  }

  static Sale _make({
    required String invoice,
    required String customer,
    required String cashier,
    required DateTime time,
    required List<SaleLine> lines,
    required List<SalePayment> Function(double total) pay,
    SaleStatus status = SaleStatus.paid,
    double discount = 0,
    String? note,
    bool refundAll = false,
  }) {
    final draft = Sale(
      invoice: invoice,
      customer: customer,
      cashier: cashier,
      time: time,
      lines: lines,
      payments: const [],
      status: status,
      timeline: const [],
      discount: discount,
      note: note,
    );
    final total = draft.total;
    final payments = pay(total);
    final timeline = <SaleEvent>[
      SaleEvent('Created', cashier, time, icon: Icons.receipt_long_outlined),
      if (payments.isNotEmpty)
        SaleEvent(
          status == SaleStatus.deposit ? 'Deposit paid' : 'Paid',
          cashier,
          time.add(const Duration(minutes: 3)),
          icon: Icons.payments_outlined,
        ),
      if (refundAll)
        SaleEvent(
          'Refunded in full',
          'Sara Lee',
          time.add(const Duration(hours: 2)),
          icon: Icons.undo,
        ),
      if (status == SaleStatus.voided)
        SaleEvent(
          'Voided',
          'Owner',
          time.add(const Duration(minutes: 10)),
          icon: Icons.block,
        ),
    ];
    return Sale(
      invoice: invoice,
      customer: customer,
      cashier: cashier,
      time: time,
      lines: lines,
      payments: payments,
      status: status,
      timeline: timeline,
      discount: discount,
      note: note,
      refunded: refundAll ? total : 0,
      refundState: refundAll ? RefundState.completed : RefundState.none,
    );
  }
}
