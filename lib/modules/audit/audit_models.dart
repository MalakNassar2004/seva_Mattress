import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';

enum AuditAction {
  login,
  refund,
  priceChange,
  permissionChange,
  export,
  stockAdjustment,
  approval,
}

extension AuditActionInfo on AuditAction {
  String get label => switch (this) {
    AuditAction.login => 'Logins',
    AuditAction.refund => 'Refunds',
    AuditAction.priceChange => 'Price changes',
    AuditAction.permissionChange => 'Permissions',
    AuditAction.export => 'Exports',
    AuditAction.stockAdjustment => 'Stock adjustments',
    AuditAction.approval => 'Approvals',
  };

  IconData get icon => switch (this) {
    AuditAction.login => Icons.login,
    AuditAction.refund => Icons.undo,
    AuditAction.priceChange => Icons.sell_outlined,
    AuditAction.permissionChange => Icons.admin_panel_settings_outlined,
    AuditAction.export => Icons.download_outlined,
    AuditAction.stockAdjustment => Icons.inventory_2_outlined,
    AuditAction.approval => Icons.verified_user_outlined,
  };

  /// Colors of the old → new value chip: (text, background, border).
  (Color, Color, Color) get chipColors => switch (this) {
    AuditAction.refund => (
      AppColors.danger,
      AppColorsExtra.dangerSoft,
      AppColorsExtra.dangerBorder,
    ),
    AuditAction.priceChange => (
      AppColors.success,
      AppColorsExtra.successSoft,
      AppColorsExtra.successBorder,
    ),
    AuditAction.export => (
      AppColors.deepBlue,
      AppColorsExtra.infoBg,
      AppColorsExtra.infoBorder,
    ),
    AuditAction.login => (
      AppColors.grey,
      AppColorsExtra.panelGrey,
      AppColorsExtra.panelBorder,
    ),
    _ => (
      AppColorsExtra.amberText,
      AppColorsExtra.amberSoft,
      AppColorsExtra.amberBorder,
    ),
  };
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.actor,
    required this.actorRole,
    required this.actorInitials,
    required this.action,
    required this.sentence,
    required this.time,
    required this.terminal,
    required this.device,
    required this.network,
    required this.location,
    required this.address,
    required this.authorization,
    required this.hash,
    this.employeeId,
    this.isOwner = false,
    this.oldValue,
    this.newValue,
    this.context,
    this.note,
  });

  final String id;
  final String actor;
  final String actorRole;
  final String actorInitials;
  final String? employeeId;
  final bool isOwner;
  final AuditAction action;

  /// Plain-language sentence ("Issued customer refund for Order #SM-10482").
  final String sentence;
  final String? oldValue;
  final String? newValue;
  final DateTime time;

  /// Short context after the time ("Terminal #01 · Reason: comfort return").
  final String? context;
  final String terminal;
  final String device;
  final String network;
  final String location;
  final String address;
  final String authorization;
  final String hash;
  final String? note;
}
