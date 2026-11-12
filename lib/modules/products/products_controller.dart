import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import 'product_item.dart';
import 'products_mock.dart';

/// Products catalogue (/products, opened from the Inventory tab).
/// UI state only. Backend wiring is marked with TODO(backend).
class ProductsController extends GetxController {
  // ---------------- State ----------------
  static const List<String> sortOptions = [
    'High stock first',
    'Low stock first',
    'Price: high to low',
    'Price: low to high',
    'Name A-Z',
  ];

  final selectedCategory = 0.obs;
  final sortLabel = 'High stock first'.obs;

  // ---------------- Mock data ----------------
  // TODO(backend): load the categories and products from the API.
  static const int totalSkus = ProductsMock.totalSkus;

  final categories = ProductsMock.categories;

  final products = <ProductItem>[...ProductsMock.products].obs;

  // ---------------- Actions ----------------
  void selectCategory(int index) {
    selectedCategory.value = index;
    // TODO(backend): filter by category.
  }

  void selectSort(String label) {
    sortLabel.value = label;
    // TODO(backend): sort the list.
  }

  void onSearchChanged(String query) {
    // TODO(backend): search by name, SKU, model or size.
  }

  void onFilterPressed() {
    // TODO(backend): open the filters (not designed yet) and apply them.
  }

  void deleteProduct(ProductItem product) {
    // TODO(backend): delete the product. Past sales must be kept.
    products.remove(product);
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onAddProductPressed() => Get.toNamed(AppRoutes.productAdd);

  // TODO(backend): pass the product (or its id) so the form loads its data.
  void onEditProduct(ProductItem product) =>
      Get.toNamed(AppRoutes.productEdit);

  void onNavTap(int index) => OwnerNav.goToTab(index);
}
