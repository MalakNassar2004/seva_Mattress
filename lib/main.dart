import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

// استيراد الفايربيس وملف الإعدادات المتولد
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'modules/auth/app_lock_controller.dart';

/// false = keep the Firebase session between launches. After the user swipes
///         the app away and opens it again, he uses Face ID (instead of
///         typing email + password) and then the SMS code.
/// true  = force a full email/Google sign-in on every launch.
const bool kRequireLoginOnLaunch = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kRequireLoginOnLaunch) {
    await AuthService().logout();
  }

  // قفل التطبيق بالـ Face ID (يضل شغال طول عمر التطبيق)
  Get.put(AppLockController(), permanent: true);

  runApp(const SevaApp());
}

class SevaApp extends StatelessWidget {
  const SevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) {
        return GetMaterialApp(
          title: 'Seva Mattress POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
        );
      },
    );
  }
}