import 'package:flutter/material.dart';
import 'inventory_models.dart';

/// Mock data for the Inventory & Stock page.
/// TODO(backend): delete this file once the API is connected.
class InventoryMock {
  InventoryMock._();

  static const double totalValue = 148650;
  static const String valueChange = '+4.2%';
  static const int activeUnits = 318;
  static const int lowStockCount = 4;
  static const int outOfStockCount = 1;

  static const List<String> tabLabels = [
    'Stock (142)',
    'Movements (18)',
    'Low Stock (5)',
  ];

  static const List<StockItem> items = [
    StockItem(
      name: 'Seva Hybrid Luxury Queen',
      sku: 'MAT-SEV-HYB-QN',
      warehouse: 5,
      showroom: 3,
      cost: 760,
      level: StockLevel.ok,
      showLocationIcons: true,
    ),
    StockItem(
      name: 'Cloud Rest Natural Latex King',
      sku: 'MAT-CLD-LTX-KG',
      warehouse: 1,
      showroom: 1,
      cost: 980,
      level: StockLevel.low,
      threshold: 4,
      showroomNote: '(Floor model)',
    ),
    StockItem(
      name: 'CoolSilk Organic Bamboo Pillow',
      sku: 'PIL-BAM-STD',
      warehouse: 35,
      showroom: 10,
      cost: 42,
      level: StockLevel.ok,
    ),
    StockItem(
      name: 'Seva Pure Comfort Full',
      sku: 'MAT-SEV-COM-FL',
      warehouse: 0,
      showroom: 0,
      cost: 0,
      level: StockLevel.out,
      reorderStatus: 'Reorder status: PO #PO-8812 arriving Oct 28',
    ),
  ];
}

/// Mock product shown in the Adjust Stock sheet.
/// TODO(backend): delete once the sheet receives the real product.
class AdjustStockMock {
  AdjustStockMock._();

  static const String productName = 'Seva Hybrid Luxury Queen';
  static const String sku = 'MAT-SEV-HYB-QN';
  static const double cost = 760;
  static const int baseUnits = 8;

  static const List<(String, int, IconData)> locations = [
    ('Surrey Whse', 5, Icons.warehouse_outlined),
    ('Showroom', 3, Icons.storefront_outlined),
    ('Damaged', 0, Icons.warning_amber_rounded),
  ];

  static const int initialValue = 9;
  static const String initialReason = 'Count correction (Physical cycle count)';
  static const String initialNote =
      'Weekly cycle count match - Verified pallet rack B4';
}
