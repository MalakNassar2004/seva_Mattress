/// Mock product used to prefill the Edit Product form.
/// TODO(backend): delete once /product-edit loads the real product.
class ProductFormMock {
  ProductFormMock._();

  static const String code = '4102';
  static const String name = 'Seva Hybrid Luxury';
  static const String model = 'SV-HYB-2024';
  static const String description =
      'Multi-layered organic latex and pocket coil hybrid mattress '
      'engineered for temperature regulation and ergonomic spinal support.';
  static const String sku = 'MAT-SEV-HYB-QN';
  static const String retail = '1,899.00';
  static const String cost = '760.00';
  static const String stock = '8';
  static const String dimensions = 'Min: 28" × 50" — Max: 84" × 96"';
  static const String category = 'Mattresses';
  static const List<String> thicknesses = ['10" (Standard)'];
  static const String pricingFormula = 'Surcharge + \$18.50 / sq ft';
  static const int photoCount = 2;
}
