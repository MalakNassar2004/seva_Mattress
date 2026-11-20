import 'package:flutter/material.dart';

enum ExportDataset { sales, inventory, customers, purchases, audit }

extension ExportDatasetInfo on ExportDataset {
  String get label => switch (this) {
    ExportDataset.sales => 'Sales & Tax',
    ExportDataset.inventory => 'Inventory & Valuation',
    ExportDataset.customers => 'Customers',
    ExportDataset.purchases => 'Purchasing & POs',
    ExportDataset.audit => 'Audit Log',
  };

  String get subtitle => switch (this) {
    ExportDataset.sales => 'Receipts, tender breakdowns, GST/PST',
    ExportDataset.inventory => 'SKUs, stock on hand, landed costs',
    ExportDataset.customers => 'Accounts, lifetime spend, notes',
    ExportDataset.purchases => 'Vendor ledger, open POs, receipts',
        ExportDataset.audit => 'Every change, with who and when',
  };

  IconData get icon => switch (this) {
    ExportDataset.sales => Icons.receipt_long_outlined,
    ExportDataset.inventory => Icons.inventory_2_outlined,
    ExportDataset.customers => Icons.people_outline,
    ExportDataset.purchases => Icons.local_shipping_outlined,
    ExportDataset.audit => Icons.shield_outlined,
  };

  /// Contains financial data or customer personal information.
  bool get sensitive => this != ExportDataset.inventory;

  /// Mock record count used for the history line.
  // TODO(backend): the API returns the real count.
  int get mockRecords => switch (this) {
    ExportDataset.sales => 482,
    ExportDataset.inventory => 1120,
    ExportDataset.customers => 842,
    ExportDataset.purchases => 64,
    ExportDataset.audit => 128,
  };
}

enum ExportFormat { pdf, csv, excel }

extension ExportFormatInfo on ExportFormat {
  String get label => switch (this) {
    ExportFormat.pdf => 'PDF',
    ExportFormat.csv => 'CSV',
    ExportFormat.excel => 'Excel',
  };

  String get subtitle => switch (this) {
    ExportFormat.pdf => 'Formatted',
    ExportFormat.csv => 'Spreadsheet',
    ExportFormat.excel => '.xlsx',
  };

  String get extension => switch (this) {
    ExportFormat.pdf => 'pdf',
    ExportFormat.csv => 'csv',
    ExportFormat.excel => 'xlsx',
  };

  IconData get icon => switch (this) {
    ExportFormat.pdf => Icons.picture_as_pdf_outlined,
    ExportFormat.csv => Icons.description_outlined,
    ExportFormat.excel => Icons.grid_on_outlined,
  };
}

enum ExportRange { thisWeek, thisMonth, lastQuarter, custom }

extension ExportRangeLabel on ExportRange {
  String get label => switch (this) {
    ExportRange.thisWeek => 'This Week',
    ExportRange.thisMonth => 'This Month',
    ExportRange.lastQuarter => 'Last Quarter',
    ExportRange.custom => 'Custom',
  };
}

/// One row of the export history.
class ExportRecord {
  const ExportRecord({
    required this.fileName,
    required this.dataset,
    required this.format,
    required this.by,
    required this.role,
    required this.device,
    required this.time,
    required this.size,
    required this.records,
  });

  final String fileName;
  final ExportDataset dataset;
  final ExportFormat format;
  final String by;
  final String role;
  final String device;
  final DateTime time;
  final String size;
  final int records;
}
