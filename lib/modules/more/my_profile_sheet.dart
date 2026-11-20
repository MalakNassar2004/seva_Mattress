import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show normalizeEmail;
import 'package:seva_mattress/data/repositories/profile_repository.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

/// Edit my own profile: name, phone and sign-in email, and ask for a password
/// reset email. The role cannot be changed here.
class MyProfileController extends GetxController {
  MyProfileController(this.initial);

  final MyProfile initial;

  final _repo = ProfileRepository();

  // Not disposed on purpose: the closing animation of the sheet is still
  // drawing these fields (disposing them then crashes the screen).
  late final nameController = TextEditingController(text: initial.name);
  late final phoneController = TextEditingController(text: initial.phone);
  late final emailController = TextEditingController(text: initial.email);
  final passwordController = TextEditingController();

  final isSaving = false.obs;
  final isSendingReset = false.obs;

  /// Shown when Firebase asks for the current password to confirm a new email.
  final needsPassword = false.obs;

  /// A problem of one field, by field key.
  final errors = <String, String>{}.obs;

  /// A problem that does not belong to a field.
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    void clearOn(TextEditingController c, String key) {
      c.addListener(() {
        if (errors.containsKey(key)) errors.remove(key);
        error.value = null;
      });
    }

    clearOn(nameController, 'name');
    clearOn(phoneController, 'phone');
    clearOn(emailController, 'email');
    clearOn(passwordController, 'password');
  }

  String _one(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  bool _validate() {
    errors.clear();

    final name = _one(nameController.text);
    if (name.isEmpty) {
      errors['name'] = 'Enter your name.';
    } else if (name.length > 80) {
      errors['name'] = 'The name is too long (max 80 characters).';
    }

    final phone = _one(phoneController.text);
    if (phone.isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'\D'), '').length;
      if (phone.length > 30 || digits < 7 || digits > 15) {
        errors['phone'] = 'Enter a valid phone number.';
      }
    }

    final email = emailController.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Enter your email.';
    } else if (normalizeEmail(email) == null) {
      errors['email'] = 'This email address is not valid.';
    }

    if (needsPassword.value && passwordController.text.isEmpty) {
      errors['password'] = 'Enter your current password.';
    }
    return errors.isEmpty;
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps
    error.value = null;
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final name = _one(nameController.text);
    final phone = _one(phoneController.text);
    final newEmail = normalizeEmail(emailController.text) ?? '';
    final emailChanged =
        newEmail.isNotEmpty && newEmail != initial.email.trim().toLowerCase();

    isSaving.value = true;
    try {
      await _repo.saveNamePhone(name: name, phone: phone);
      if (emailChanged) {
        await _repo.requestEmailChange(
          newEmail: newEmail,
          password: needsPassword.value ? passwordController.text : null,
        );
        Get.back(
          result: 'Check $newEmail and open the link to confirm your new '
              'sign-in email.',
        );
        return;
      }
      Get.back(result: 'Profile saved');
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        needsPassword.value = true;
      }
      error.value = describeProfileError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> onSendReset() async {
    if (isSendingReset.value) return;
    error.value = null;
    isSendingReset.value = true;
    try {
      await _repo.sendPasswordReset();
      Get.back(result: 'Password reset link sent to ${initial.email}');
    } catch (e) {
      error.value = describeProfileError(e);
    } finally {
      isSendingReset.value = false;
    }
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: My profile. Open it with MyProfileSheet.show().
class MyProfileSheet extends GetView<MyProfileController> {
  const MyProfileSheet({super.key});

  /// Loads the profile, opens the sheet, and shows the result as a toast.
  static Future<void> show() async {
    final MyProfile current;
    try {
      current = await ProfileRepository().loadMine();
    } catch (_) {
      showDarkToast('Could not load your profile', trailing: '', info: true);
      return;
    }

    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next show() replaces it.
    if (Get.isRegistered<MyProfileController>()) {
      Get.delete<MyProfileController>(force: true);
    }
    Get.put(MyProfileController(current));
    final message = await Get.bottomSheet<String>(
      const MyProfileSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    if (message != null) showDarkToast(message);
  }

  Widget _fieldError(String key) {
    return Obx(() {
      final text = controller.errors[key];
      if (text == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(top: 6.h, left: 4.w),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = controller.initial.role;
    final roleLabel =
        role.isEmpty ? 'Staff' : role[0].toUpperCase() + role.substring(1);
    return SheetFrame(
      footer: Obx(
        () => PrimaryArrowButton(
          label: controller.isSaving.value ? 'Saving...' : 'Save Profile',
          leadingIcon: Icons.check,
          onPressed: controller.onSave,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SheetCloseButton(onTap: controller.onClosePressed),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Role: $roleLabel (it cannot be changed here)',
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
          ),
          SizedBox(height: 16.h),
          LabeledInput(
            controller: controller.nameController,
            label: 'Full name',
            hint: 'Your name',
            prefixIcon: Icons.person_outline,
          ),
          _fieldError('name'),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.phoneController,
            label: 'Phone (optional)',
            hint: '(604) 555-0100',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _fieldError('phone'),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.emailController,
            label: 'Sign-in email',
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          _fieldError('email'),
          SizedBox(height: 6.h),
          Text(
            'If you change the email, a confirmation link is sent to the new '
            'address. The email changes when you open it.',
            style: TextStyle(
              fontSize: 11.5.sp,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          Obx(() {
            if (!controller.needsPassword.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                  _fieldError('password'),
                ],
              ),
            );
          }),
          Obx(() {
            final err = controller.error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Text(
                err,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            );
          }),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              label: 'Send password reset email',
              icon: Icons.lock_reset,
              height: 46,
              radius: 14,
              fontSize: 13.5,
              onTap: controller.onSendReset,
            ),
          ),
          SizedBox(height: 12.h),
          const AuditNote(
            'Changes are recorded in the audit log',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}