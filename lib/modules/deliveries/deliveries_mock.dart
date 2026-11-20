import 'delivery_models.dart';

/// Mock data for Deliveries.
/// The date strip is real. The drivers below are still demo data.
/// TODO(backend): delete when the drivers are wired.
class DeliveriesMock {
  DeliveriesMock._();

  // The date strip: 2 days back, today, and 27 days ahead.
  static const int todayIndex = 2;
  static const int dayCount = 30;

  static final DateTime firstDay = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - todayIndex);
  }();

  /// The date of the day at [i] on the strip (local midnight).
  static DateTime dateOf(int i) =>
      DateTime(firstDay.year, firstDay.month, firstDay.day + i);

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static final List<DispatchDay> days = List.generate(dayCount, (i) {
    final d = dateOf(i);
    return DispatchDay(
      _weekdays[d.weekday - 1],
      d.day,
      _months[d.month - 1],
      isToday: i == todayIndex,
    );
  });

  /// Counts on the summary chips for today (whole fleet, not just the
  /// cards loaded below).
  static const Map<DeliveryStatus, int> todayCounts = {
    DeliveryStatus.pending: 4,
    DeliveryStatus.scheduled: 6,
    DeliveryStatus.outForDelivery: 3,
    DeliveryStatus.delivered: 8,
    DeliveryStatus.failed: 1,
  };

  static const List<String> windows = [
    '8:00 AM - 11:00 AM',
    '10:00 AM - 1:00 PM',
    '2:00 PM - 5:00 PM',
    '5:00 PM - 8:00 PM',
  ];

  static const List<String> failReasons = [
    'Customer not home',
    'Gate locked',
    'Wrong address',
    'No elevator access',
    'Item damaged',
    'Customer requested',
    'Weather / road',
  ];

  static const Driver mike = Driver(
    initials: 'MR',
    name: 'Mike Reynolds',
    shortName: 'Mike R.',
    vehicle: 'Truck #2 (Surrey Heavy Dispatch)',
    done: 3,
    capacity: 5,
    state: DriverState.onRoute,
    note: 'On Route (Near White Rock)',
    phone: '(604) 555-0131',
    recommended: true,
  );

  static const Driver garry = Driver(
    initials: 'GS',
    name: 'Garry Singh',
    shortName: 'Garry S.',
    vehicle: 'Van #1 (Express Fleet)',
    done: 4,
    capacity: 4,
    state: DriverState.full,
    note: 'Shift ends 4:00 PM',
    phone: '(604) 555-0177',
  );

  static const Driver arjun = Driver(
    initials: 'AP',
    name: 'Arjun Patel',
    shortName: 'Arjun P.',
    vehicle: 'Truck #1 (Main Freight)',
    done: 0,
    capacity: 5,
    state: DriverState.available,
    note: 'Standby at Surrey Warehouse',
    phone: '(778) 555-0122',
  );

  static const List<Driver> drivers = [mike, garry, arjun];

  static const List<Delivery> deliveries = [
    Delivery(
      id: 'DLV-5521',
      orderNumber: '#ORD-10892',
      customer: 'David Thompson',
      phone: '(604) 555-0142',
      address: '14288 72 Ave, Surrey, BC V3W 2R3',
      itemSummary: '1x Custom Queen Hybrid 72"x80", 2x Pillows',
      productName: 'Custom Queen Hybrid',
      productTag: 'HYBRID Q',
      amount: 2450,
      dayIndex: todayIndex,
      window: '10:00 AM - 1:00 PM',
      status: DeliveryStatus.outForDelivery,
      driver: mike,
      eta: '18 mins away',
      gateCode: '#4092',
      accessNote: 'Customer present',
      weightLbs: 128,
      twoPersonLift: true,
      driverNotes: [
        'Loaded 8:40 AM · wrapped & strapped',
        'Customer asked to call 10 min before arrival',
      ],
    ),
    Delivery(
      id: 'DLV-5524',
      orderNumber: '#ORD-10887',
      customer: 'Elena Rostova',
      phone: '(604) 555-0199',
      address: '15243 16 Ave, White Rock, BC V4A 1R6',
      itemSummary: '1x Cloud Rest Natural Latex Mattress',
      productName: 'Cloud Rest Natural Latex Queen',
      productTag: 'LATEX Q',
      amount: 3120,
      dayIndex: todayIndex,
      window: '2:00 PM - 5:00 PM',
      status: DeliveryStatus.scheduled,
      gateCode: '#4920',
      accessNote: '2nd floor delivery',
      weightLbs: 142,
      twoPersonLift: true,
      whiteGlove: true,
    ),
    Delivery(
      id: 'DLV-5517',
      orderNumber: '#ORD-10842',
      customer: 'Marcus Vance',
      phone: '(778) 555-0110',
      address: '8840 204 St, Langley, BC V1M 2Y3',
      itemSummary: '1x Dual Comfort Split King, 2x Temp-Cool Pillows',
      productName: 'Dual Comfort Split King',
      productTag: 'SPLIT K',
      amount: 1890,
      dayIndex: todayIndex,
      window: '8:00 AM - 11:00 AM',
      status: DeliveryStatus.delivered,
      driver: garry,
      timeLabel: '9:15 AM',
      weightLbs: 165,
      proofVerified: true,
      driverNotes: [
        'Old mattress hauled away',
        'Set up in master bedroom, customer signed',
      ],
    ),
    Delivery(
      id: 'DLV-5498',
      orderNumber: '#ORD-10815',
      customer: 'Sara Lee',
      phone: '(604) 555-0188',
      address: '13888 104 Ave, Surrey, BC',
      itemSummary: '1x Memory Foam Double',
      productName: 'Memory Foam Double',
      productTag: 'FOAM D',
      amount: 1420,
      dayIndex: todayIndex,
      window: '2:00 PM - 5:00 PM',
      status: DeliveryStatus.failed,
      driver: garry,
      timeLabel: 'Yesterday 4:30 PM',
      failReason: 'Customer not home / Gate locked',
      weightLbs: 74,
      driverNotes: [
        'Called twice, no answer',
        'Gate locked, left door hanger',
      ],
    ),
    Delivery(
      id: 'DLV-5530',
      orderNumber: '#ORD-10876',
      customer: 'Tom Bradley',
      phone: '(604) 555-0163',
      address: '20180 56 Ave, Langley, BC V3A 3Y6',
      itemSummary: '1x Custom RV Short Queen 60"x74"',
      productName: 'Custom RV Short Queen',
      productTag: 'RV SQ',
      amount: 1800,
      dayIndex: todayIndex,
      window: 'Time slot not set',
      status: DeliveryStatus.pending,
      weightLbs: 58,
      paidInFull: false,
    ),
    Delivery(
      id: 'DLV-5533',
      orderNumber: '#ORD-10881',
      customer: 'Priya Sandhu',
      phone: '(604) 555-0151',
      address: '11020 84 Ave, Delta, BC V4C 2L7',
      itemSummary: '1x Seva Firm Pocket Coil King',
      productName: 'Seva Firm Pocket Coil King',
      productTag: 'COIL K',
      amount: 1890,
      dayIndex: todayIndex + 1,
      window: '10:00 AM - 1:00 PM',
      status: DeliveryStatus.scheduled,
      driver: arjun,
      weightLbs: 120,
    ),
    Delivery(
      id: 'DLV-5490',
      orderNumber: '#ORD-10861',
      customer: 'Grace Liu',
      phone: '(604) 555-0170',
      address: '4700 Kingsway, Burnaby, BC V5H 4M1',
      itemSummary: '2x Comfort Plus Twin XL',
      productName: 'Comfort Plus Twin XL',
      productTag: 'TWIN XL',
      amount: 1540,
      dayIndex: todayIndex - 1,
      window: '10:00 AM - 1:00 PM',
      status: DeliveryStatus.delivered,
      driver: mike,
      timeLabel: '11:40 AM',
      weightLbs: 96,
      proofVerified: true,
      driverNotes: ['Delivered to front lobby, concierge signed'],
    ),
  ];
}