/// The payment methods the store accepts. The owner turns them on or off in
/// Settings. This holds the last list that was read from the store settings,
/// so the order, payment and refund screens can show only the enabled ones.
class PaymentMethodsConfig {
  PaymentMethodsConfig._();

  static const List<String> all = ['Card', 'Cash', 'E-Transfer', 'Financing'];

  /// The enabled methods, in the order above (at least one).
  static List<String> enabled = List<String>.of(all);

  static void apply(List<String> names) {
    final list = [
      for (final m in all)
        if (names.contains(m)) m,
    ];
    enabled = list.isEmpty ? List<String>.of(all) : list;
  }
}