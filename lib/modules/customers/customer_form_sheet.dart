import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'customer_models.dart';

/// Add / edit a customer. Used from the Customers list, the customer detail
/// page and (later) from the order form.
class CustomerFormController extends GetxController {
  CustomerFormController({this.editing, this.initialPhone = ''});

  final CustomerItem? editing;

  /// Pre-filled phone when adding (for example one the cashier just typed).
  final String initialPhone;

  bool get isEdit => editing != null;

  // Limits (the Firestore rules enforce the same numbers).
  static const int maxName = 80;
  static const int maxEmail = 120;
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
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
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

  String? _validate() {
    final name = _clean(nameController.text);
    if (name.isEmpty) return 'The customer name is required.';
    if (name.length > maxName) {
      return 'The name is too long (max $maxName characters).';
    }
    if (normalizePhone(phoneController.text) == null) {
      return 'Enter a valid 10-digit phone number (for example 604 555 0192).';
    }
    final email = emailController.text.trim();
    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      return 'Enter a valid email address, or leave it empty.';
    }
    if (email.length > maxEmail) return 'The email is too long.';
    if (_clean(cityController.text).length > maxCity) {
      return 'The city is too long (max $maxCity characters).';
    }
    if (_clean(addressController.text).length > maxAddress) {
      return 'The address is too long (max $maxAddress characters).';
    }
    if (notesController.text.trim().length > maxNotes) {
      return 'The notes are too long (max $maxNotes characters).';
    }
    return null;
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps

    final problem = _validate();
    if (problem != null) {
      error.value = problem;
      return;
    }
    error.value = null;
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
  }) async {
    if (Get.isRegistered<CustomerFormController>()) {
      Get.delete<CustomerFormController>(force: true);
    }
    Get.put(CustomerFormController(
      editing: editing,
      initialPhone: initialPhone,
    ));
    final result = await Get.bottomSheet<CustomerItem>(
      const CustomerFormSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    Get.delete<CustomerFormController>(force: true);
    return result;
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
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.phoneController,
            label: 'Phone (identifies the customer)',
            hint: '(604) 555-0192',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.emailController,
            label: 'Email (optional)',
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.cityController,
            label: 'City (optional)',
            hint: 'e.g. Surrey',
            prefixIcon: Icons.location_city_outlined,
          ),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.addressController,
            label: 'Delivery address (optional)',
            hint: 'Street, city, postal code, gate code...',
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.notesController,
            label: 'Notes (optional)',
            hint: 'e.g. Prefers weekend deliveries',
            maxLines: 3,
          ),
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
            'Customer changes are recorded in the audit log',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}