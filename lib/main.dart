import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'src/app_routes.dart';
import 'src/core/network/api_bootstrap.dart';
import 'src/core/report/report_exports.dart';
import 'src/modules/main/main_controller.dart';
import 'src/theme/app_colors.dart';
import 'src/utils/app_toast.dart';
import 'src/utils/screen_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await bootstrapApiClient();
  ReportLifecycleObserver(ReportManager.instance).start();
  configureAppToast();
  runApp(const KaibiganLoanApp());
}

class KaibiganLoanApp extends StatelessWidget {
  const KaibiganLoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        ScreenAdapter.init(context);
        return GetMaterialApp(
          title: 'Kaibigan Loan',
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.main,
          getPages: AppPages.pages,
          routingCallback: (_) {
            if (Get.isRegistered<MainController>()) {
              Get.find<MainController>().onRouteChanged();
            }
          },
          defaultTransition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 260),
          popGesture: false,
          builder: (context, child) {
            final easyLoadingChild = EasyLoading.init()(context, child);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: easyLoadingChild,
            );
          },
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.appBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.appBackground,
              primary: AppColors.appBackground,
            ),
          ),
        );
      },
    );
  }
}
