import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'product_item.dart';

/// UI state only (mock data). Backend wiring is marked with TODO(backend).
class ProductsController extends GetxController {
  static const int totalSkus = 142;

  final categories = const [
    ProductCategory('All', 142),
    ProductCategory('Mattresses', 38),
    ProductCategory('Pillows', 24),
    ProductCategory('Protectors', 31),
    ProductCategory('Accessories', 33),
    ProductCategory('Custom-size', 16),
  ];

  static const List<String> sortOptions = [
    'High stock first',
    'Low stock first',
    'Price: high to low',
    'Price: low to high',
    'Name A-Z',
  ];

  final selectedCategory = 0.obs;
  final sortLabel = 'High stock first'.obs;

  // TODO(backend): load products from the API.
  final products = <ProductItem>[
    const ProductItem(
      name: 'Seva Hybrid Luxury Queen',
      model: 'SV-HYB-2024',
      sku: 'MAT-SEV-HYB-QN',
      price: 1899,
      status: StockStatus.inStock,
      units: 8,
    ),
    const ProductItem(
      name: 'Cloud Rest Natural Latex King',
      model: 'CR-LTX-900',
      sku: 'MAT-CLD-LTX-KG',
      price: 2499,
      status: StockStatus.low,
      units: 2,
      customSize: true,
    ),
    const ProductItem(
      name: 'CoolSilk Organic Bamboo Pillow',
      model: 'CS-BAM-02',
      sku: 'PIL-BAM-STD',
      price: 149,
      status: StockStatus.inStock,
      units: 45,
      kind: ProductKind.pillow,
    ),
    const ProductItem(
      name: 'Seva Pure Comfort Full (Double)',
      model: 'SV-COM-10',
      sku: 'MAT-SEV-PC-FL',
      price: 1399,
      status: StockStatus.out,
      units: 0,
      reorderPo: '#PO-8812',
    ),
    const ProductItem(
      name: 'Organic Latex Pillow Top Topper',
      model: 'TOP-ORG-01',
      sku: 'ACC-TOP-LX-QN',
      price: 429,
      status: StockStatus.inStock,
      units: 14,
    ),
  ].obs;

  void selectCategory(int index) {
    selectedCategory.value = index;
    // TODO(backend): filter by category
  }

  void selectSort(String label) {
    sortLabel.value = label;
    // TODO(backend): sort the list
  }

  void onSearchChanged(String query) {
    // TODO(backend): search by name, SKU, model or size
  }

  void onFilterPressed() {
    // TODO: open filters
  }

  /// Inside the Owner shell, Products is a tab (not a pushed route), so
  /// going back switches to the Home tab instead of popping the root route.
  void onBackPressed() {
    if (Get.currentRoute == AppRoutes.owner &&
        Get.isRegistered<OwnerShellController>()) {
      Get.find<OwnerShellController>().changeTab(OwnerShellController.homeTab);
    } else {
      Get.back();
    }
  }

  void onAddProductPressed() => Get.toNamed(AppRoutes.productAdd);

  // TODO(backend): pass the product (or its id) so the form loads its data.
  void onEditProduct(ProductItem product) =>
      Get.toNamed(AppRoutes.productEdit);

  void deleteProduct(ProductItem product) {
    // TODO(backend): delete the product. Past sales must be kept.
    products.remove(product);
  }
}
