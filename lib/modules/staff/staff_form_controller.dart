import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/shared_widgets.dart';
import 'deactivate_staff_sheet.dart';
import 'permissions_controller.dart';
import 'staff_models.dart';
import 'staff_store.dart';

/// Add / Edit Staff. Arguments: staff id (edit) or nothing (add).
/// UI state only. Backend wiring is marked with TODO(backend).
class StaffFormController extends GetxController {
  final store = StaffStore.to;

  late final StaffMember? editing = Get.arguments is String
      ? store.byId(Get.arguments as String)
      : null;

  bool get isEdit => editing != null;

  late final nameController = TextEditingController(text: editing?.name);
  late final emailController = TextEditingController(text: editing?.email);
  late final phoneController = TextEditingController(text: editing?.phone);

  // ---------------- State ----------------
  late final role = (editing?.role ?? StaffRole.cashier).obs;
  late final pin = _randomPin().obs;
  final pinVisible = false.obs;
  late final active = (editing?.active ?? true).obs;
  late final permissions = <String>{
    ...(editing?.permissions ?? StaffRole.cashier.template.permissions),
  }.obs;
  late final discountCap =
      (editing?.discountCap ?? StaffRole.cashier.template.discountCap).obs;

  /// True once the owner edits permissions by hand, so changing the role no
  /// longer overwrites them.
  late bool _customized = isEdit;

  /// Set after "Create account" succeeds; shows the handover card.
  final created = Rxn<StaffMember>();

  /// Field key -> error text.
  final errors = <String, String>{}.obs;

  /// First granted permissions shown as chips on the preview card.
  List<Permission> get previewPermissions => PermissionCatalog.all
      .where((p) => permissions.contains(p.id))
      .take(4)
      .toList();

  String get credentials =>
      '${emailController.text.trim()} · PIN: ${pin.value}';

  // ---------------- Actions ----------------
  void clearError(String key) => errors.remove(key);

  void selectRole(StaffRole r) {
    role.value = r;
    if (!_customized) {
      permissions.assignAll(r.template.permissions);
      discountCap.value = r.template.discountCap;
    }
  }

  void generatePin() {
    pin.value = _randomPin();
    pinVisible.value = true;
  }

  void togglePinVisible() => pinVisible.toggle();

  void toggleActive(bool v) => active.value = v;

  Future<void> onCustomizePermissions() async {
    final draft = StaffMember(
      id: editing?.id ?? store.nextId(),
      name: nameController.text.trim().isEmpty
          ? 'New Employee'
          : nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      role: role.value,
      title: editing?.title ?? role.value.label,
      active: active.value,
      lastActive: editing?.lastActive ?? 'Never',
      location: editing?.location ?? '—',
      permissions: {...permissions},
      discountCap: discountCap.value,
    );
    final result = await Get.toNamed(
      AppRoutes.permissions,
      arguments: PermissionsArgs(draft, persist: isEdit),
    );
    if (result is PermissionsResult) {
      permissions.assignAll(result.permissions);
      discountCap.value = result.discountCap;
      _customized = true;
    }
  }

  Future<void> onCopyCredentials() async {
    await Clipboard.setData(ClipboardData(text: credentials));
    showDarkToast('Credentials copied');
  }

  bool _validate() {
    final e = <String, String>{};
    if (nameController.text.trim().isEmpty) e['name'] = 'Enter the full name';
    final email = emailController.text.trim();
    if (!GetUtils.isEmail(email)) e['email'] = 'Enter a valid work email';
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) e['phone'] = 'Enter a 10-digit phone number';
    errors.assignAll(e);
    return e.isEmpty;
  }

  void onSubmit() {
    if (created.value != null) {
      Get.back();
      return;
    }
    if (!_validate()) return;
    final base = editing;
    final roleChanged = base != null && base.role != role.value;
    final member = base == null
        ? StaffMember(
            id: store.nextId(),
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            role: role.value,
            title: role.value.label,
            active: active.value,
            lastActive: 'Never',
            location: '—',
            permissions: {...permissions},
            discountCap: discountCap.value,
            deactivatedOn: active.value ? null : 'Never activated',
          )
        : base.copyWith(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            role: role.value,
            title: roleChanged ? role.value.label : base.title,
            active: active.value,
            permissions: {...permissions},
            discountCap: discountCap.value,
          );
    // TODO(backend): POST / PATCH the employee and the temporary PIN.
    store.save(member);
    if (isEdit) {
      Get.back();
      showDarkToast('${member.name} updated');
    } else {
      pinVisible.value = true;
      created.value = member;
      showDarkToast('Account created for ${member.name}');
    }
  }

  Future<void> onDeactivatePressed() async {
    final m = editing;
    if (m == null) return;
    final ok = await DeactivateStaffSheet.open(store.byId(m.id) ?? m);
    if (!ok) return;
    // TODO(backend): POST /staff/{id}/deactivate (revokes all sessions).
    store.setActive(m.id, false);
    Get.back();
    showDarkToast('${m.name} deactivated and signed out');
  }

  void onBackPressed() => Get.back();

  static String _randomPin() {
    final r = Random.secure();
    return List.generate(6, (_) => r.nextInt(10)).join();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
