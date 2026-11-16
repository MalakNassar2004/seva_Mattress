import 'export_models.dart';

/// Demo export history.
/// TODO(backend): remove when the history is loaded from the API.
class ExportsMock {
  ExportsMock._();

  static DateTime _ago(int days, int hour, int minute) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - days, hour, minute);
  }

  static List<ExportRecord> history() => [
    ExportRecord(
      fileName: 'Sales & Tax Ledger.csv',
      dataset: ExportDataset.sales,
      format: ExportFormat.csv,
      by: 'Sara Lee',
      role: 'Store Manager',
      device: 'Surrey POS Terminal 1',
      time: _ago(0, 8, 12),
      size: '1.4 MB',
      records: 482,
    ),
    ExportRecord(
      fileName: 'Inventory Valuation.xlsx',
      dataset: ExportDataset.inventory,
      format: ExportFormat.excel,
      by: 'Owner',
      role: 'PIN #OWN-001',
      device: 'Owner Mobile',
      time: _ago(6, 14, 5),
      size: '3.2 MB',
      records: 1120,
    ),
    ExportRecord(
      fileName: 'Customer Master.pdf',
      dataset: ExportDataset.customers,
      format: ExportFormat.pdf,
      by: 'Sara Lee',
      role: 'Store Manager',
      device: 'Surrey POS Terminal 2',
      time: _ago(12, 10, 40),
      size: '840 KB',
      records: 842,
    ),
    ExportRecord(
      fileName: 'Purchase Orders.csv',
      dataset: ExportDataset.purchases,
      format: ExportFormat.csv,
      by: 'Arjun Patel',
      role: 'Warehouse Lead',
      device: 'Warehouse Terminal 1',
      time: _ago(20, 16, 22),
      size: '96 KB',
      records: 64,
    ),
  ];
}
