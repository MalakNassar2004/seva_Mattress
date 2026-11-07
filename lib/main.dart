import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. استيراد الفايربيس وملف الإعدادات المتولد
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/routes/app_pages.dart';
import 'app/theme/app_colors.dart';
import 'data/services/auth_service.dart';
import 'modules/auth/app_lock_controller.dart';

/// false = keep the Firebase session between launches. After the user swipes
///         the app away and opens it again, he uses Face ID (instead of
///         typing email + password) and then the SMS code.
/// true  = force a full email/Google sign-in on every launch.
const bool kRequireLoginOnLaunch = false;

void main() async {
  // 2. ضمان تجهيز الـ Bindings قبل العمليات اللاتزامنية
  WidgetsFlutterBinding.ensureInitialized();

  // 3. تهيئة الفايربيس
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kRequireLoginOnLaunch) {
    await AuthService().logout();
  }

  // قفل التطبيق بالـ Face ID (يضل شغال طول عمر التطبيق)
  Get.put(AppLockController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Seva Mattress',
          theme: ThemeData(
            primaryColor: AppColors.primaryBlue,
            scaffoldBackgroundColor: AppColors.white,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
            useMaterial3: true,
          ),
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
        );
      },
    );
  }
}