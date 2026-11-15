import 'product_item.dart';

/// Mock data for the Products catalogue.
/// TODO(backend): delete this file once the API is connected.
class ProductsMock {
  ProductsMock._();

  static const int totalSkus = 142;

  static const List<ProductCategory> categories = [
    ProductCategory('All', 142),
    ProductCategory('Mattresses', 38),
    ProductCategory('Pillows', 24),
    ProductCategory('Protectors', 31),
    ProductCategory('Accessories', 33),
    ProductCategory('Custom-size', 16),
  ];

  static const List<ProductItem> products = [
    ProductItem(
      name: 'Seva Hybrid Luxury Queen',
      model: 'SV-HYB-2024',
      sku: 'MAT-SEV-HYB-QN',
      price: 1899,
      status: StockStatus.inStock,
      units: 8,
    ),
    ProductItem(
      name: 'Cloud Rest Natural Latex King',
      model: 'CR-LTX-900',
      sku: 'MAT-CLD-LTX-KG',
      price: 2499,
      status: StockStatus.low,
      units: 2,
      customSize: true,
    ),
    ProductItem(
      name: 'CoolSilk Organic Bamboo Pillow',
      model: 'CS-BAM-02',
      sku: 'PIL-BAM-STD',
      price: 149,
      status: StockStatus.inStock,
      units: 45,
      kind: ProductKind.pillow,
    ),
    ProductItem(
      name: 'Seva Pure Comfort Full (Double)',
      model: 'SV-COM-10',
      sku: 'MAT-SEV-PC-FL',
      price: 1399,
      status: StockStatus.out,
      units: 0,
      reorderPo: '#PO-8812',
    ),
    ProductItem(
      name: 'Organic Latex Pillow Top Topper',
      model: 'TOP-ORG-01',
      sku: 'ACC-TOP-LX-QN',
      price: 429,
      status: StockStatus.inStock,
      units: 14,
    ),
  ];
}
