enum StockStatus { inStock, low, out }

enum ProductKind { mattress, pillow }

class ProductCategory {
  const ProductCategory(this.label, this.count);
  final String label;
  final int count;
}

/// A product is "low stock" when it has this many units or fewer.
const int kLowStockThreshold = 5;

StockStatus stockStatusFor(int units) {
  if (units <= 0) return StockStatus.out;
  if (units <= kLowStockThreshold) return StockStatus.low;
  return StockStatus.inStock;
}

/// A product as stored in Firestore (collection `products`) and shown in
/// the Products list. The cost price is NOT here: it is stored separately
/// and only the owner can read it.
class ProductItem {
  const ProductItem({
    this.id = '',
    required this.name,
    required this.model,
    required this.sku,
    required this.price,
    required this.status,
    required this.units,
    this.customSize = false,
    this.kind = ProductKind.mattress,
    this.reorderPo,
    this.category = 'Mattresses',
    this.description = '',
    this.dimensions = '',
    this.size = 'Queen',
    this.thicknesses = const [],
    this.cuts = const [],
    this.pricingFormula,
    this.notesRequired = false,
    this.isActive = true,
    this.photoUrls = const [],
  });

  /// Builds a product from a Firestore document.
  factory ProductItem.fromMap(String id, Map<String, dynamic> m) {
    final units = (m['units'] as num?)?.toInt() ?? 0;
    final category = (m['category'] as String?) ?? 'Mattresses';
    return ProductItem(
      id: id,
      name: (m['name'] as String?) ?? '',
      model: (m['model'] as String?) ?? '',
      sku: (m['sku'] as String?) ?? '',
      price: (m['retailPrice'] as num?)?.toDouble() ?? 0,
      status: stockStatusFor(units),
      units: units,
      customSize: m['customSize'] == true,
      kind: category == 'Pillows' ? ProductKind.pillow : ProductKind.mattress,
      reorderPo: m['reorderPo'] as String?,
      category: category,
      description: (m['description'] as String?) ?? '',
      dimensions: (m['dimensions'] as String?) ?? '',
      size: (m['size'] as String?) ?? 'Queen',
      thicknesses: List<String>.from(m['thicknesses'] ?? const <String>[]),
      cuts: List<String>.from(m['cuts'] ?? const <String>[]),
      pricingFormula: m['pricingFormula'] as String?,
      notesRequired: m['notesRequired'] == true,
      isActive: m['isActive'] != false,
      photoUrls: List<String>.from(m['photoUrls'] ?? const <String>[]),
    );
  }

  /// Firestore document id ('' for a product that is not saved yet).
  final String id;
  final String name;
  final String model;
  final String sku;

  /// Retail price.
  final double price;
  final StockStatus status;
  final int units;
  final bool customSize;
  final ProductKind kind;
  final String? reorderPo;

  final String category;
  final String description;
  final String dimensions;
  final String size;
  final List<String> thicknesses;
  final List<String> cuts;
  final String? pricingFormula;
  final bool notesRequired;
  final bool isActive;
  final List<String> photoUrls;
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