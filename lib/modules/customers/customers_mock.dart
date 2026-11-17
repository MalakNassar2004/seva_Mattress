import 'package:flutter/material.dart';
import 'customer_models.dart';

/// Mock data for the Customers list.
/// TODO(backend): delete this file once the API is connected.
class CustomersMock {
  CustomersMock._();

  static const int totalClients = 1248;

  static const List<CustomerItem> customers = [
    CustomerItem(
      initials: 'DT',
      name: 'David Thompson',
      phone: '(604) 555-0192',
      city: 'Surrey',
      ordersLabel: '3 Orders · \$5,847.00 CAD',
      note: 'Warranty active until Oct 2034',
      noteIcon: Icons.verified_user_outlined,
      isVip: true,
    ),
    CustomerItem(
      initials: 'PS',
      name: 'Priya Sandhu',
      phone: '(778) 555-0147',
      city: 'Delta',
      ordersLabel: '1 Order · \$2,499.00 CAD',
      note: 'Delivery scheduled Sat, Nov 15 · 9-11 AM',
      noteIcon: Icons.local_shipping_outlined,
      noteIsAccent: true,
      balanceOwing: 1249.50,
    ),
    CustomerItem(
      initials: 'ML',
      name: 'Michael Leung',
      phone: '(604) 555-0133',
      city: 'Burnaby',
      ordersLabel: '2 Orders · \$1,548.00 CAD',
      note: 'Day 42 of 100-Night Comfort Guarantee',
      noteIcon: Icons.nightlight_outlined,
    ),
    CustomerItem(
      initials: 'SC',
      name: 'Sarah Chen',
      phone: '(236) 555-0178',
      city: 'Langley',
      ordersLabel: '1 Order · \$429.00 CAD',
      note: 'Layaway plan · next payment Nov 30',
      noteIcon: Icons.event_outlined,
      balanceOwing: 214.50,
    ),
  ];
}

/// Mock customer shown on the Customer detail page.
/// TODO(backend): delete once the page loads the selected customer.
class CustomerDetailMock {
  CustomerDetailMock._();

  static const String name = 'David Thompson';
  static const String customerId = '#CUST-0842';
  static const String phone = '(604) 555-0192';
  static const String email = 'd.thompson@shaw.ca';

  static const List<String> tabLabels = [
    'Orders (3)',
    'Notes (2)',
    'Warranty & Care (1)',
  ];
}