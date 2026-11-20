import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError, normalizeEmail;
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

/// Edit the store profile: the company details and the texts printed on
/// every invoice. Only the owner can save (the Firestore rules enforce it).
class StoreProfileController extends GetxController {
  StoreProfileController(this.initial);

  final CompanyInfo initial;

  // Limits (the Firestore rules enforce the same numbers).
  static const int maxName = 80;
  static const int maxAddress = 200;
  static const int maxPhone = 30;
  static const int maxEmail = 120;
  static const int maxTaxNumber = 40;
  static const int maxTitle = 30;
  static const int maxThankYou = 160;
  static const int maxTerms = 800;

  final _repo = CompanyRepository();

  // Not disposed on purpose: the closing animation of the sheet is still
  // drawing these fields (disposing them then crashes the screen).
  late final nameController = TextEditingController(text: initial.name);
  late final addressController = TextEditingController(text: initial.address);
  late final phoneController = TextEditingController(text: initial.phone);
  late final emailController = TextEditingController(text: initial.email);
  late final gstNumberController =
  TextEditingController(text: initial.gstNumber);
  late final pstNumberController =
  TextEditingController(text: initial.pstNumber);
  late final titleController =
  TextEditingController(text: initial.invoiceTitle);
  late final thankYouController =
  TextEditingController(text: initial.thankYou);
  late final termsController = TextEditingController(text: initial.terms);

  final isSaving = false.obs;

  /// A problem of one field (shown under that field), by field key.
  final errors = <String, String>{}.obs;

  /// A problem that does not belong to a field (for example no permission).
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    // Editing a field clears only its own error.
    void clearOn(TextEditingController c, String key) {
      c.addListener(() {
        if (errors.containsKey(key)) errors.remove(key);
        error.value = null;
      });
    }

    clearOn(nameController, 'name');
    clearOn(addressController, 'address');
    clearOn(phoneController, 'phone');
    clearOn(emailController, 'email');
    clearOn(gstNumberController, 'gstNumber');
    clearOn(pstNumberController, 'pstNumber');
    clearOn(titleController, 'title');
    clearOn(thankYouController, 'thankYou');
    clearOn(termsController, 'terms');
  }

  String _one(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Checks every field and shows ALL the problems at once.
  bool _validate() {
    errors.clear();

    final name = _one(nameController.text);
    if (name.isEmpty) {
      errors['name'] = 'Enter the company name.';
    } else if (name.length > maxName) {
      errors['name'] = 'The name is too long (max $maxName characters).';
    }

    if (_one(addressController.text).length > maxAddress) {
      errors['address'] = 'The address is too long (max $maxAddress characters).';
    }
    if (_one(phoneController.text).length > maxPhone) {
      errors['phone'] = 'The phone is too long (max $maxPhone characters).';
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      if (email.length > maxEmail) {
        errors['email'] = 'The email is too long (max $maxEmail characters).';
      } else if (normalizeEmail(email) == null) {
        errors['email'] = 'This email address is not valid.';
      }
    }

    if (_one(gstNumberController.text).length > maxTaxNumber) {
      errors['gstNumber'] =
      'The GST number is too long (max $maxTaxNumber characters).';
    }
    if (_one(pstNumberController.text).length > maxTaxNumber) {
      errors['pstNumber'] =
      'The PST number is too long (max $maxTaxNumber characters).';
    }

    final title = _one(titleController.text);
    if (title.isEmpty) {
      errors['title'] = 'Enter the invoice title (for example INVOICE).';
    } else if (title.length > maxTitle) {
      errors['title'] = 'The title is too long (max $maxTitle characters).';
    }

    if (_one(thankYouController.text).length > maxThankYou) {
      errors['thankYou'] = 'The text is too long (max $maxThankYou characters).';
    }
    if (termsController.text.trim().length > maxTerms) {
      errors['terms'] = 'The text is too long (max $maxTerms characters).';
    }

    return errors.isEmpty;
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps
    error.value = null;
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    // copyWith keeps the tax rates, which are not edited here.
    final info = initial.copyWith(
      name: _one(nameController.text),
      address: _one(addressController.text),
      phone: _one(phoneController.text),
      email: emailController.text.trim(),
      gstNumber: _one(gstNumberController.text),
      pstNumber: _one(pstNumberController.text),
      invoiceTitle: _one(titleController.text),
      thankYou: _one(thankYouController.text),
      terms: termsController.text.trim(),
    );

    isSaving.value = true;
    try {
      await _repo.save(info);
      Get.back(result: true);
    } catch (e) {
      error.value = describeCustomerError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Store profile. Open it with StoreProfileSheet.open().
/// Returns true when the profile was saved.
class StoreProfileSheet extends GetView<StoreProfileController> {
  const StoreProfileSheet({super.key});

  static Future<bool?> open(CompanyInfo initial) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<StoreProfileController>()) {
      Get.delete<StoreProfileController>(force: true);
    }
    Get.put(StoreProfileController(initial));
    return Get.bottomSheet<bool>(
      const StoreProfileSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  /// The red message under a field.
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

  Widget _section(String text) => Padding(
    padding: EdgeInsets.only(top: 20.h, bottom: 10.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      footer: Obx(
        () => PrimaryArrowButton(
          label: controller.isSaving.value ? 'Saving...' : 'Save Store Profile',
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
                  'Store Profile',
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
            'Printed on every invoice. Only the owner can change it.',
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
          ),
          SizedBox(height: 16.h),
          LabeledInput(
            controller: controller.nameController,
            label: 'Company name',
            hint: 'e.g. Seva Mattress',
            prefixIcon: Icons.storefront_outlined,
          ),
          _fieldError('name'),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.addressController,
            label: 'Address (optional)',
            hint: 'Street, city, postal code',
            maxLines: 2,
          ),
          _fieldError('address'),
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
            label: 'Email (optional)',
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          _fieldError('email'),
          _section('Tax numbers'),
          LabeledInput(
            controller: controller.gstNumberController,
            label: 'GST number (optional)',
            hint: 'Printed on the invoice when filled',
            prefixIcon: Icons.tag,
          ),
          _fieldError('gstNumber'),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.pstNumberController,
            label: 'PST number (optional)',
            hint: 'Printed on the invoice when filled',
            prefixIcon: Icons.tag,
          ),
          _fieldError('pstNumber'),
          _section('Invoice text'),
          LabeledInput(
            controller: controller.titleController,
            label: 'Invoice title',
            hint: 'INVOICE',
            prefixIcon: Icons.receipt_long_outlined,
          ),
          _fieldError('title'),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.thankYouController,
            label: 'Thank-you line (optional)',
            hint: 'Thank you for your business.',
          ),
          _fieldError('thankYou'),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.termsController,
            label: 'Terms, return policy, warranty (optional)',
            hint: 'Printed at the bottom of the invoice',
            maxLines: 5,
          ),
          _fieldError('terms'),
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