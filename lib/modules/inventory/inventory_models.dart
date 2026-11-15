enum StockLevel { ok, low, out }

/// Display model for one row of the Stock tab.
/// TODO(backend): replace with the real stock model.
class StockItem {
  const StockItem({
    required this.name,
    required this.sku,
    required this.warehouse,
    required this.showroom,
    required this.cost,
    required this.level,
    this.threshold,
    this.showroomNote,
    this.reorderStatus,
    this.showLocationIcons = false,
  });

  final String name;
  final String sku;
  final int warehouse;
  final int showroom;
  final double cost;
  final StockLevel level;
  final int? threshold;
  final String? showroomNote;
  final String? reorderStatus;
  final bool showLocationIcons;

  int get units => warehouse + showroom;
  double get value => cost * units;
}
