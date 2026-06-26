import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'src/app_routes.dart';
import 'src/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  runApp(const KaibiganLoanApp());
}

class KaibiganLoanApp extends StatelessWidget {
  const KaibiganLoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kaibigan Loan',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.main,
      getPages: AppPages.pages,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      popGesture: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.appBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.appBackground,
          primary: AppColors.appBackground,
        ),
      ),
    );
  }
}
