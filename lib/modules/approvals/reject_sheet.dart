import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'approval_models.dart';

/// Bottom sheet: confirm a rejection. A reason is required.
/// Returns the reason, or null when cancelled.
class RejectSheet extends StatefulWidget {
  const RejectSheet({super.key, required this.request, this.initialReason});

  final ApprovalRequest request;
  final String? initialReason;

  static Future<String?> open(ApprovalRequest r, {String? initialReason}) =>
      Get.bottomSheet<String>(
        RejectSheet(request: r, initialReason: initialReason),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
      );

  @override
  State<RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<RejectSheet> {
  late final _reason = TextEditingController(text: widget.initialReason);
  String? _error;

  void _submit() {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Enter a reason so the requester knows why');
      return;
    }
    Get.back(result: text);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return SheetFrame(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DangerButton(
            label: 'Reject request',
            icon: Icons.close,
            onTap: _submit,
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              label: 'Cancel',
              height: 50,
              radius: 16,
              fontSize: 14.5,
              onTap: Get.back,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reject request?',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SheetCloseButton(onTap: Get.back),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${r.type.label} from ${r.requester} · ${r.saleRef}',
            style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
          ),
          SizedBox(height: 14.h),
          LabeledInput(
            controller: _reason,
            label: 'Reason (required)',
            hint: 'Explain why this request is rejected',
            maxLines: 3,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            SizedBox(height: 6.h),
            Text(
              _error!,
              style: TextStyle(fontSize: 12.sp, color: AppColors.danger),
            ),
          ],
          SizedBox(height: 12.h),
          const AuditNote('The reason is saved in the audit log'),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
