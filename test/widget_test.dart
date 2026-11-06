import 'package:flutter_test/flutter_test.dart';
import 'package:seva_mattress/app/routes/app_pages.dart';
import 'package:seva_mattress/app/routes/app_routes.dart';
import 'package:seva_mattress/modules/products/product_item.dart';

void main() {
  test('every route constant has a page', () {
    final names = AppPages.pages.map((p) => p.name).toSet();
    expect(
      names,
      containsAll(<String>[
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.pin,
        AppRoutes.forgotPassword,
        AppRoutes.owner,
        AppRoutes.products,
        AppRoutes.productAdd,
        AppRoutes.productEdit,
      ]),
    );
  });

  test('formatMoney adds separators and cents', () {
    expect(formatMoney(1899), r'$1,899.00');
    expect(formatMoney(149), r'$149.00');
  });
}
