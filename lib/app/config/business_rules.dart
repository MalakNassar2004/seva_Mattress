/// Numbers of the business that the owner may change later. Each one is
/// used in a single place, so changing it here is enough.
class BusinessRules {
  BusinessRules._();

  /// A customer becomes VIP when the total of his orders (taxes included,
  /// cancelled orders excluded) reaches this amount, in CAD.
  static const int vipThresholdCad = 10000;

  /// The same amount in cents (the app stores money in cents).
  static const int vipThresholdCents = vipThresholdCad * 100;
}