import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_colors.dart';

void main() {
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
