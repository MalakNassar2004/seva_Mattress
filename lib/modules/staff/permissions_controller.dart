import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/widgets/shared_widgets.dart';
import '../audit/audit_models.dart';
import '../audit/audit_store.dart';
import 'confirm_permissions_sheet.dart';
import 'staff_models.dart';
import 'staff_store.dart';

/// Arguments of the Permissions Manager route.
class PermissionsArgs {
  const PermissionsArgs(this.member, {this.persist = true});

  /// The employee (or the unsaved draft from Add Employee).
  final StaffMember member;

  /// true = save to the store on apply (existing employee).
  /// false = only return the result (new employee not created yet).
  final bool persist;
}

/// Returned to the caller with Get.back(result: ...).
class PermissionsResult {
  const PermissionsResult(this.permissions, this.discountCap);

  final Set<String> permissions;
  final int discountCap;
}

enum DiffKind { granted, revoked, modified }

/// One line of the "Confirm Permission Changes" sheet.
class PermissionDiff {
  const PermissionDiff({
    required this.permission,
    required this.kind,
    required this.from,
    required this.to,
  });

  final Permission permission;
  final DiffKind kind;
  final String from;
  final String to;
}

/// Permissions Manager. Arguments: PermissionsArgs.
/// UI state only. Backend wiring is marked with TODO(backend).
class PermissionsController extends GetxController {
  final store = StaffStore.to;

  late final PermissionsArgs args = Get.arguments as PermissionsArgs;
  StaffMember get member => args.member;

  late final Set<String> _original = {...member.permissions};
  late final int _originalCap = member.discountCap;

  // ---------------- State ----------------
  late final granted = <String>{..._original}.obs;
  late final discountCap = _originalCap.obs;
  late final template = Rxn<PermissionTemplate>(member.role.template);

  /// Expanded group titles. The first two start open.
  final expanded = <String>{
    PermissionCatalog.groups[0].title,
    PermissionCatalog.groups[1].title,
  }.obs;

  late final capController = TextEditingController(
    text: '${member.discountCap}',
  );

  // ---------------- Derived ----------------
  bool isOn(String id) => granted.contains(id);

  bool isChanged(Permission p) {
    if (_original.contains(p.id) != granted.contains(p.id)) return true;
    return p.hasDiscountCap &&
        granted.contains(p.id) &&
        _original.contains(p.id) &&
        discountCap.value != _originalCap;
  }

  int activeIn(PermissionGroup g) =>
      g.items.where((p) => granted.contains(p.id)).length;

  List<PermissionDiff> get diffs {
    final out = <PermissionDiff>[];
    for (final p in PermissionCatalog.all) {
      final was = _original.contains(p.id);
      final now = granted.contains(p.id);
      if (!was && now) {
        out.add(
          PermissionDiff(
            permission: p,
            kind: DiffKind.granted,
            from: 'Disabled',
            to: p.hasDiscountCap
                ? 'Granted (up to ${discountCap.value}%)'
                : 'Granted',
          ),
        );
      } else if (was && !now) {
        out.add(
          PermissionDiff(
            permission: p,
            kind: DiffKind.revoked,
            from: 'Enabled',
            to: 'Access restricted',
          ),
        );
      } else if (was && now && isChanged(p)) {
        out.add(
          PermissionDiff(
            permission: p,
            kind: DiffKind.modified,
            from: '$_originalCap% max discount',
            to: '${discountCap.value}% max discount',
          ),
        );
      }
    }
    return out;
  }

  int get pendingCount => diffs.length;

  // ---------------- Actions ----------------
  void toggleGroup(PermissionGroup g) {
    if (!expanded.remove(g.title)) expanded.add(g.title);
  }

  void toggle(Permission p, bool on) {
    on ? granted.add(p.id) : granted.remove(p.id);
    template.value = null;
  }

  void onCapChanged(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'\D'), '')) ?? 0;
    discountCap.value = n.clamp(0, 100);
    template.value = null;
  }

  void applyTemplate(PermissionTemplate t) {
    granted.assignAll(t.permissions);
    discountCap.value = t.discountCap;
    capController.text = '${t.discountCap}';
    template.value = t;
  }

  void onReset() {
    granted.assignAll(_original);
    discountCap.value = _originalCap;
    capController.text = '$_originalCap';
    template.value = member.role.template;
  }

  Future<void> onSave() async {
    final changes = diffs;
    if (changes.isEmpty) return;
    final ok = await ConfirmPermissionsSheet.open(member, changes);
    if (!ok) return;
    final result = PermissionsResult({...granted}, discountCap.value);
    if (args.persist) {
      // TODO(backend): PUT /staff/{id}/permissions — pushed to live sessions.
      final current = store.byId(member.id) ?? member;
      store.save(
        current.copyWith(
          permissions: result.permissions,
          discountCap: result.discountCap,
        ),
      );
      final first = changes.first;
      AuditStore.to.record(
        action: AuditAction.permissionChange,
        sentence: changes.length == 1
            ? 'Permission changed for ${member.name}: '
                  '${first.permission.label}'
            : '${changes.length} permissions changed for ${member.name}',
        oldValue: changes.length == 1 ? first.from : null,
        newValue: changes.length == 1 ? first.to : '${changes.length} changes',
      );
    }
    Get.back(result: result);
    showDarkToast(
      '${changes.length} permission change${changes.length == 1 ? '' : 's'} '
      'applied',
    );
  }

  void onBackPressed() => Get.back();

  @override
  void onClose() {
    capController.dispose();
    super.onClose();
  }
}
