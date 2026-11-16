import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/dates.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../audit/audit_models.dart';
import '../audit/audit_store.dart';
import '../owner_shell/owner_nav.dart';
import 'export_models.dart';
import 'exports_mock.dart';

/// Data Exports (owner). Opened from the More tab.
/// UI state only. Backend wiring is marked with TODO(backend).
class ExportsController extends GetxController {
  // ---------------- State ----------------
  final dataset = ExportDataset.sales.obs;
  final format = ExportFormat.csv.obs;
  final range = ExportRange.thisMonth.obs;
  final customRange = Rxn<DateTimeRange>();
  final generating = false.obs;
  final history = <ExportRecord>[...ExportsMock.history()].obs;

  // ---------------- Derived ----------------
  DateTimeRange get selectedRange {
    final today = dateOnly(DateTime.now());
    switch (range.value) {
      case ExportRange.thisWeek:
        return DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: today,
        );
      case ExportRange.thisMonth:
        return DateTimeRange(
          start: DateTime(today.year, today.month),
          end: today,
        );
      case ExportRange.lastQuarter:
        final q = (today.month - 1) ~/ 3; // 0..3, current quarter
        final start = DateTime(today.year, q * 3 - 2);
        final end = DateTime(today.year, q * 3 + 1, 0);
        return DateTimeRange(start: start, end: end);
      case ExportRange.custom:
        return customRange.value ??
            DateTimeRange(
              start: today.subtract(const Duration(days: 29)),
              end: today,
            );
    }
  }

  String get rangeText {
    final r = selectedRange;
    return '${range.value.label} (${formatShortDate(r.start)} – '
        '${formatDate(r.end)})';
  }

  // ---------------- Actions ----------------
  void selectDataset(ExportDataset d) => dataset.value = d;
  void selectFormat(ExportFormat f) => format.value = f;

  Future<void> selectRange(ExportRange r) async {
    if (r != ExportRange.custom) {
      range.value = r;
      return;
    }
    final picked = await showDateRangeSheet(initial: selectedRange);
    if (picked == null) return;
    customRange.value = picked;
    range.value = ExportRange.custom;
  }

  Future<void> onGenerate() async {
    if (generating.value) return;
    generating.value = true;
    // TODO(backend): POST /exports and download the file.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final d = dataset.value;
    final f = format.value;
    final record = ExportRecord(
      fileName: '${d.label} (${range.value.label}).${f.extension}',
      dataset: d,
      format: f,
      by: 'Owner',
      role: 'PIN #OWN-001',
      device: 'Owner Mobile',
      time: DateTime.now(),
      size: f == ExportFormat.pdf ? '620 KB' : '1.1 MB',
      records: d.mockRecords,
    );
    history.insert(0, record);
    AuditStore.to.record(
      action: AuditAction.export,
      sentence: 'Exported ${d.label} report',
      newValue: '${f.label} · ${d.mockRecords} records',
    );
    generating.value = false;
    showDarkToast('${record.fileName} is ready');
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();
  void onNavTap(int index) => OwnerNav.goToTab(index);
}
