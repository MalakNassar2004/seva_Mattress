/// Which sections are visible in this build.
///
/// A section that is not connected to Firestore yet shows demo numbers, so
/// it stays hidden from the client (`false`). Turn a flag on when the
/// section is connected and tested.
class FeatureFlags {
  FeatureFlags._();

  // Owner tabs.
  static const bool home = false;
  static const bool orders = false;
  static const bool reports = false;

  // More menu: Business.
  static const bool customers = true;
  static const bool suppliers = false;
  static const bool purchaseOrders = false;
  static const bool deliveries = false;

  // More menu: People.
  static const bool staff = false;
  static const bool permissions = false;

  // More menu: Control.
  static const bool approvals = false;
  static const bool exports = false;
  static const bool auditLog = false;
  static const bool settings = false;
}