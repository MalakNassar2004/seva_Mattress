enum StockStatus { inStock, low, out }

enum ProductKind { mattress, pillow }

class ProductCategory {
  const ProductCategory(this.label, this.count);
  final String label;
  final int count;
}

/// Display model for the Products list.
/// TODO(backend): replace with the real product model.
class ProductItem {
  const ProductItem({
    required this.name,
    required this.model,
    required this.sku,
    required this.price,
    required this.status,
    required this.units,
    this.customSize = false,
    this.kind = ProductKind.mattress,
    this.reorderPo,
  });

  final String name;
  final String model;
  final String sku;
  final double price;
  final StockStatus status;
  final int units;
  final bool customSize;
  final ProductKind kind;
  final String? reorderPo;
}

/// 1899 -> $1,899.00
String formatMoney(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '\$$whole.${parts[1]}';
}
