import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'customer_models.dart';

/// Add / edit a customer. Used from the Customers list, the customer detail
/// page and the order form.
///
/// Every problem is shown under the field that has it (phone, email, name,
/// city), so the user sees exactly what to fix.
class CustomerFormController extends GetxController {
  CustomerFormController({this.editing, this.initialPhone = ''});

  final CustomerItem? editing;

  /// Pre-filled phone when adding (for example one the cashier just typed).
  final String initialPhone;

  bool get isEdit => editing != null;

  // Limits (the Firestore rules enforce the same numbers).
  static const int maxName = 80;
  static const int maxEmail = 120;
  static const int minCity = 2;
  static const int maxCity = 60;
  static const int maxAddress = 200;
  static const int maxNotes = 1000;

  final _repo = CustomerRepository();

  /// Created ONCE for this sheet, so a double tap on Save (or a retry on a
  /// bad connection) can never create two customers.
  late final String _newId = _repo.newId();

  // Not disposed on purpose (see the Login controller note).
  late final nameController = TextEditingController(text: editing?.name ?? '');
  late final phoneController =
  TextEditingController(text: editing?.phone ?? initialPhone);
  late final emailController =
  TextEditingController(text: editing?.email ?? '');
  late final cityController = TextEditingController(text: editing?.city ?? '');
  late final addressController =
  TextEditingController(text: editing?.address ?? '');
  late final notesController =
  TextEditingController(text: editing?.notes ?? '');

  final isSaving = false.obs;

  /// A problem that belongs to one field (shown under that field).
  final nameError = RxnString();
  final phoneError = RxnString();
  final emailError = RxnString();
  final cityError = RxnString();
  final addressError = RxnString();
  final notesError = RxnString();

  /// A problem that does not belong to a field (for example no connection).
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    // Editing a field clears only its own error.
    nameController.addListener(() => nameError.value = null);
    phoneController.addListener(() => phoneError.value = null);
    emailController.addListener(() => emailError.value = null);
    cityController.addListener(() => cityError.value = null);
    addressController.addListener(() => addressError.value = null);
    notesController.addListener(() => notesError.value = null);
    for (final c in [
      nameController,
      phoneController,
      emailController,
      cityController,
      addressController,
      notesController,
    ]) {
      c.addListener(() => error.value = null);
    }
  }

  String _clean(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  void _clearErrors() {
    nameError.value = null;
    phoneError.value = null;
    emailError.value = null;
    cityError.value = null;
    addressError.value = null;
    notesError.value = null;
    error.value = null;
  }

  /// Checks every field and shows ALL the problems at once.
  /// Returns true when everything is fine.
  bool _validate() {
    var ok = true;

    final name = _clean(nameController.text);
    if (name.isEmpty) {
      nameError.value = 'Enter the customer name.';
      ok = false;
    } else if (name.length > maxName) {
      nameError.value = 'The name is too long (max $maxName characters).';
      ok = false;
    }

    final phoneText = phoneController.text.trim();
    if (phoneText.isEmpty) {
      phoneError.value = 'Enter the phone number.';
      ok = false;
    } else if (normalizePhone(phoneText) == null) {
      phoneError.value = 'This phone number is not valid. Use 7 to 15 digits. '
          'Outside Canada and the US, include the country code '
          '(for example +20 109 746 9537).';
      ok = false;
    }

    final city = _clean(cityController.text);
    if (city.length < minCity) {
      cityError.value = 'Enter the city.';
      ok = false;
    } else if (city.length > maxCity) {
      cityError.value = 'The city is too long (max $maxCity characters).';
      ok = false;
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      if (email.length > maxEmail) {
        emailError.value = 'The email is too long (max $maxEmail characters).';
        ok = false;
      } else if (normalizeEmail(email) == null) {
        emailError.value = 'This email address is not valid.';
        ok = false;
      }
    }

    if (_clean(addressController.text).length > maxAddress) {
      addressError.value =
      'The address is too long (max $maxAddress characters).';
      ok = false;
    }
    if (notesController.text.trim().length > maxNotes) {
      notesError.value = 'The notes are too long (max $maxNotes characters).';
      ok = false;
    }

    return ok;
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps

    _clearErrors();
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final name = _clean(nameController.text);
    final phoneKey = normalizePhone(phoneController.text)!;
    final email = emailController.text.trim();
    final city = _clean(cityController.text);
    final address = _clean(addressController.text);
    final notes = notesController.text.trim();

    isSaving.value = true;
    try {
      final CustomerItem saved;
      if (isEdit) {
        saved = await _repo.update(
          editing!.id,
          name: name,
          phoneKey: phoneKey,
          email: email,
          city: city,
          address: address,
          notes: notes,
        );
      } else {
        saved = await _repo.create(
          _newId,
          name: name,
          phoneKey: phoneKey,
          email: email,
          city: city,
          address: address,
          notes: notes,
        );
      }
      Get.back(result: saved);
    } on CustomerConflictException catch (e) {
      // Already used by another customer: show it under its own field.
      if (e.phoneTaken) {
        phoneError.value =
        'This phone number is already used by ${e.phoneOwner}.';
      }
      if (e.emailTaken) {
        emailError.value = 'This email is already used by ${e.emailOwner}.';
      }
    } catch (e) {
      error.value = describeCustomerError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: New / Edit Customer. Open it with CustomerFormSheet.open().
/// Returns the saved customer, or null when it was closed without saving.
class CustomerFormSheet extends GetView<CustomerFormController> {
  const CustomerFormSheet({super.key});

  static Future<CustomerItem?> open({
    CustomerItem? editing,
    String initialPhone = '',
  }) {
    // A previous sheet may still be registered: the controller is NOT
    // deleted when a sheet closes, because the closing animation is still
    // drawing it (deleting it then crashes). The next open() replaces it.
    if (Get.isRegistered<CustomerFormController>()) {
      Get.delete<CustomerFormController>(force: true);
    }
    Get.put(CustomerFormController(
      editing: editing,
      initialPhone: initialPhone,
    ));
    return Get.bottomSheet<CustomerItem>(
      const CustomerFormSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  /// The red message under a field (nothing when there is no problem).
  Widget _fieldError(RxnString message) {
    return Obx(() {
      final text = message.value;
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
    return SheetFrame(
      footer: Obx(
        () => PrimaryArrowButton(
          label: controller.isSaving.value
              ? 'Saving...'
              : (controller.isEdit ? 'Save Changes' : 'Save Customer'),
          leadingIcon:
              controller.isEdit ? Icons.check : Icons.person_add_alt_1_outlined,
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
                  controller.isEdit ? 'Edit Customer' : 'New Customer',
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
          SizedBox(height: 16.h),
          LabeledInput(
            controller: controller.nameController,
            label: 'Full name',
            hint: 'e.g. David Thompson',
            prefixIcon: Icons.person_outline,
          ),
          _fieldError(controller.nameError),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.phoneController,
            label: 'Phone (identifies the customer)',
            hint: '(604) 555-0192',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _fieldError(controller.phoneError),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.cityController,
            label: 'City',
            hint: 'e.g. Surrey',
            prefixIcon: Icons.location_city_outlined,
          ),
          _fieldError(controller.cityError),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.emailController,
            label: 'Email (optional)',
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          _fieldError(controller.emailError),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.addressController,
            label: 'Delivery address (optional)',
            hint: 'Street, city, postal code, gate code...',
            maxLines: 2,
          ),
          _fieldError(controller.addressError),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.notesController,
            label: 'Notes (optional)',
            hint: 'e.g. Prefers weekend deliveries',
            maxLines: 3,
          ),
          _fieldError(controller.notesError),
          // A problem that does not belong to a field (for example no
          // connection).
          _fieldError(controller.error),
          SizedBox(height: 12.h),
          const AuditNote(
            'Customer changes are recorded in the audit log',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}