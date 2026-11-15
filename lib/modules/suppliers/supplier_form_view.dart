import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'supplier_form_controller.dart';
import 'supplier_models.dart';

/// Add / Edit Supplier.
class SupplierFormView extends GetView<SupplierFormController> {
  const SupplierFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Row(
                  children: [
                    BackPill(
                      label: c.isEdit ? 'Supplier' : 'Suppliers',
                      onTap: c.onBackPressed,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        c.isEdit ? 'Edit Supplier' : 'Add Supplier',
                        style: TextStyle(
                          fontSize: 21.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  children: [
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CardTitle(
                            icon: Icons.factory_outlined,
                            title: 'Company',
                          ),
                          SizedBox(height: 12.h),
                          _field('name', c.nameController, 'Supplier name *',
                              'e.g. Cascadia Foam & Latex Works'),
                          _field('category', c.categoryController,
                              'Materials supplied', 'e.g. Latex & Core Materials'),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CardTitle(
                            icon: Icons.person_outline,
                            title: 'Contact',
                          ),
                          SizedBox(height: 12.h),
                          _field('contact', c.contactController,
                              'Contact person *', 'Full name',
                              icon: Icons.person_outline),
                          _field('phone', c.phoneController, 'Phone *',
                              '(604) 555-0000',
                              icon: Icons.call_outlined,
                              keyboard: TextInputType.phone),
                          _field('email', c.emailController, 'Email',
                              'orders@supplier.ca',
                              icon: Icons.mail_outline,
                              keyboard: TextInputType.emailAddress),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CardTitle(
                            icon: Icons.location_on_outlined,
                            title: 'Address',
                          ),
                          SizedBox(height: 12.h),
                          _field('address', c.addressController, 'Street address',
                              'e.g. 7520 Hopcott Rd'),
                          _field('city', c.cityController, 'City, Province',
                              'e.g. Delta, BC'),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CardTitle(
                            icon: Icons.payments_outlined,
                            title: 'Payment Terms',
                          ),
                          SizedBox(height: 12.h),
                          Obx(
                            () => Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: kPaymentTerms
                                  .map((t) => ChoicePill(
                                        label: t,
                                        selected: c.terms.value == t,
                                        onTap: () => c.selectTerms(t),
                                      ))
                                  .toList(),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          LabeledInput(
                            controller: c.notesController,
                            label: 'Notes',
                            hint: 'e.g. Needs 48hr notice for custom cutouts',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    const AuditNote(
                      'Supplier changes are recorded in the audit log',
                      icon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
                child: PrimaryArrowButton(
                  label: c.isEdit ? 'Save Changes' : 'Add Supplier',
                  leadingIcon: Icons.check_circle_outline,
                  onPressed: c.onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    TextEditingController tc,
    String label,
    String hint, {
    IconData? icon,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Obx(() {
        final err = controller.errors[key];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledInput(
              controller: tc,
              label: label,
              hint: hint,
              prefixIcon: icon,
              keyboardType: keyboard,
              onChanged: (_) => controller.clearError(key),
            ),
            if (err != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  err,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
