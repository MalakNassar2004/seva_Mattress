enum StockLevel { ok, low, out }

/// Display model for one row of the Stock tab.
class StockItem {
  const StockItem({
    this.id = '',
    required this.name,
    required this.sku,
    required this.warehouse,
    required this.showroom,
    this.damaged = 0,
    this.category = '',
    required this.cost,
    required this.level,
    this.threshold,
    this.showroomNote,
    this.reorderStatus,
    this.showLocationIcons = false,
  });

  /// Firestore id of the product ('' only for design mock data).
  final String id;
  final String name;
  final String sku;
  final int warehouse;
  final int showroom;
  final int damaged;
  final String category;

  /// Cost per unit. 0 when the signed-in employee cannot see costs.
  final double cost;
  final StockLevel level;
  final int? threshold;
  final String? showroomNote;
  final String? reorderStatus;
  final bool showLocationIcons;

  /// Units that can be sold (damaged ones do not count).
  int get units => warehouse + showroom;
  double get value => cost * units;
}

/// One row of the Movements tab (built from the audit log).
class StockMovement {
  const StockMovement({
    required this.id,
    required this.at,
    required this.productName,
    required this.sku,
    required this.location,
    required this.from,
    required this.to,
    required this.reason,
    this.note = '',
    this.actor = '',
  });

  final String id;
  final DateTime at;
  final String productName;
  final String sku;

  /// 'warehouse' | 'showroom' | 'damaged'
  final String location;
  final int from;
  final int to;
  final String reason;
  final String note;
  final String actor;

  int get delta => to - from;

  String get locationLabel {
    switch (location) {
      case 'showroom':
        return 'Showroom';
      case 'damaged':
        return 'Damaged';
      default:
        return 'Warehouse';
    }
  }
}