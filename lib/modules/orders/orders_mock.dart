import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'order_models.dart';

/// Mock data for Orders & Quotes.
/// TODO(backend): delete when the API is wired.
class OrdersMock {
  OrdersMock._();

  static const int totalOrders = 28;
  static const int totalQuotes = 6;

  /// Count shown on each status filter chip.
  static const Map<OrderStatus, int> statusCounts = {
    OrderStatus.newOrder: 4,
    OrderStatus.inProduction: 8,
    OrderStatus.ready: 5,
    OrderStatus.outForDelivery: 3,
    OrderStatus.delivered: 7,
    OrderStatus.cancelled: 1,
  };

  static const List<OrderItem> orders = [
    OrderItem(
      number: '#ORD-10892',
      product: 'Custom Queen Hybrid',
      customer: 'David Thompson',
      city: 'Surrey, BC',
      status: OrderStatus.inProduction,
      isCustom: true,
      dateLabel: 'Due Oct 26, 2024',
      total: 2349,
      paid: 1200,
      footerIcon: Icons.check_circle,
      footerIconColor: AppColors.success,
      footerText: 'Firmness: Medium Plush (6.5)',
      footerRight: 'Showroom Rep: Aaron K.',
    ),
    OrderItem(
      number: '#ORD-10887',
      product: 'Cloud Rest Natural Latex',
      customer: 'Elena Rostova',
      city: 'White Rock, BC',
      status: OrderStatus.ready,
      dateLabel: 'Today, 2:00 PM - 5:00 PM',
      dateIsWindow: true,
      total: 2499,
      paid: 2499,
      footerIcon: Icons.location_on_outlined,
      footerText: 'Van 02 · Route B (South Surrey)',
      footerRight: 'White Glove Setup Included',
      footerRightAccent: true,
    ),
    OrderItem(
      number: '#ORD-10881',
      product: 'Seva Firm Pocket Coil King',
      customer: 'Priya Sandhu',
      city: 'Delta, BC',
      status: OrderStatus.outForDelivery,
      dateLabel: 'Today, 10:00 AM - 1:00 PM',
      dateIsWindow: true,
      total: 1890,
      paid: 1890,
      footerIcon: Icons.local_shipping_outlined,
      footerText: 'Truck #2 · Mike R.',
      footerRight: '18 mins away',
      footerRightAccent: true,
    ),
    OrderItem(
      number: '#ORD-10876',
      product: 'Custom RV Short Queen',
      customer: 'Tom Bradley',
      city: 'Langley, BC',
      status: OrderStatus.newOrder,
      isCustom: true,
      dateLabel: 'Due Nov 04, 2024',
      total: 1800,
      paid: 600,
      footerIcon: Icons.straighten,
      footerText: '60" × 74" · 45° corner cut',
      footerRight: 'Showroom Rep: Nina P.',
    ),
    OrderItem(
      number: '#ORD-10861',
      product: 'Comfort Plus Twin XL (x2)',
      customer: 'Grace Liu',
      city: 'Burnaby, BC',
      status: OrderStatus.delivered,
      dateLabel: 'Delivered Oct 22, 2024',
      total: 1540,
      paid: 1540,
      footerIcon: Icons.verified_outlined,
      footerIconColor: AppColors.success,
      footerText: 'Photo & E-Sig verified',
      footerRight: 'Sleep trial: 100 nights',
    ),
    OrderItem(
      number: '#ORD-10855',
      product: 'Memory Foam Double',
      customer: 'Kevin Moore',
      city: 'Richmond, BC',
      status: OrderStatus.cancelled,
      dateLabel: 'Cancelled Oct 20, 2024',
      total: 980,
      paid: 0,
      footerIcon: Icons.info_outline,
      footerText: 'Customer changed mind · no deposit',
    ),
  ];

  static const List<QuoteItem> quotes = [
    QuoteItem(
      number: '#QUO-4019',
      product: 'Dual Comfort Split King',
      customer: 'Marcus Vance',
      city: 'Langley, BC',
      total: 3180,
      validUntil: 'Nov 02, 2024',
      note: 'Includes 2x Temp-Cool Pillows',
    ),
    QuoteItem(
      number: '#QUO-4016',
      product: 'Custom Boat V-Berth',
      customer: 'Olivia Chen',
      city: 'Coquitlam, BC',
      total: 2240,
      validUntil: 'Oct 28, 2024',
      note: 'V-shape 78" × 72" · 6 in foam',
      status: QuoteStatus.expiring,
    ),
    QuoteItem(
      number: '#QUO-4012',
      product: 'Cloud Rest Natural Latex Queen',
      customer: 'Sam Patel',
      city: 'Surrey, BC',
      total: 2499,
      validUntil: 'Nov 10, 2024',
      note: 'Price match vs. online listing',
      status: QuoteStatus.draft,
    ),
  ];

  static const OrderDetail detail = OrderDetail(
    number: '#ORD-10892',
    customer: 'David Thompson',
    store: 'Surrey Flagship',
    placed: 'Placed Oct 21',
    status: OrderStatus.inProduction,
    spec: CustomSpec(
      dimensions: '72" × 80"',
      dimensionsNote: 'Custom Wide Queen',
      cutAngle: '45° Chamfered',
      cutNote: 'RV Corner Profile',
      thickness: '10.5 in Organic Latex Layered',
      notes:
          'Reinforced dual-side perimeter edging for master bedroom loft frame.',
      facility: 'Manufactured in Delta, BC Facility',
      progress: 'Cutting Complete · In Assembly',
    ),
    lines: [
      OrderLine(
        name: 'Seva Hybrid Luxury Custom Queen',
        details: 'Qty: 1 · Plush Top · Latex Blend',
        price: 2199,
        icon: Icons.bed_outlined,
      ),
      OrderLine(
        name: 'Custom Chamfer Cut Surcharge',
        details: 'Bespoke RV Corner Fabrication',
        price: 150,
        icon: Icons.content_cut,
      ),
    ],
    taxRate: 0.12,
    payments: [
      PaymentRecord(
        method: 'Visa ending in 4102',
        dateLabel: 'Oct 21, 2024 · 2:14 PM',
        kind: 'Deposit',
        amount: 1400,
        icon: Icons.credit_card,
      ),
    ],
    destination: '14288 72 Ave, Surrey, BC V3W 2R3',
    destinationNote: 'Gate code: #4092 · Customer present',
    deliveryWindow: 'Saturday, Oct 26 · 10:00 AM - 1:00 PM',
    deliveryTeam: 'Truck #2 (Surrey Local Dispatch)',
    timeline: [
      TimelineEvent(
        title: 'Order placed',
        time: 'Oct 21 · 2:02 PM',
        by: 'Aaron K. (Showroom)',
      ),
      TimelineEvent(
        title: 'Deposit received · \$1,400.00',
        time: 'Oct 21 · 2:14 PM',
        by: 'Visa •••• 4102',
      ),
      TimelineEvent(
        title: 'Sent to production',
        time: 'Oct 22 · 9:30 AM',
        by: 'Delta Facility',
      ),
      TimelineEvent(
        title: 'Cutting complete',
        time: 'Oct 23 · 4:10 PM',
        by: 'Delta Facility',
      ),
      TimelineEvent(
        title: 'Delivery scheduled',
        time: 'Sat, Oct 26',
        by: 'Surrey Local Dispatch',
        done: false,
      ),
    ],
  );

  /// Products offered on the Create Order / Quote form.
  static const List<OrderLine> catalog = [
    OrderLine(
      name: 'Seva Hybrid Luxury Queen',
      details: 'Plush Top · Latex Blend',
      price: 2199,
      icon: Icons.bed_outlined,
    ),
    OrderLine(
      name: 'Cloud Rest Natural Latex Queen',
      details: 'Medium · Organic latex',
      price: 2499,
      icon: Icons.bed_outlined,
    ),
    OrderLine(
      name: 'Dual Comfort Split King',
      details: 'Split firmness · Pocket coil',
      price: 2890,
      icon: Icons.king_bed_outlined,
    ),
    OrderLine(
      name: 'Temp-Cool Pillow',
      details: 'Gel memory foam',
      price: 145,
      icon: Icons.airline_seat_flat_outlined,
    ),
    OrderLine(
      name: 'Waterproof Protector Queen',
      details: 'Breathable · 10 yr warranty',
      price: 119,
      icon: Icons.shield_outlined,
    ),
    OrderLine(
      name: 'Custom Cut Surcharge',
      details: 'Angle / corner fabrication',
      price: 150,
      icon: Icons.content_cut,
    ),
  ];

  /// Customers offered on the Create Order / Quote form.
  static const List<(String, String, String)> customers = [
    ('DT', 'David Thompson', '(604) 555-0142 · Surrey, BC'),
    ('ER', 'Elena Rostova', '(604) 555-0199 · White Rock, BC'),
    ('MV', 'Marcus Vance', '(778) 555-0110 · Langley, BC'),
  ];
}
