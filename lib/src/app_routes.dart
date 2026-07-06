import 'package:get/get.dart';

import 'modules/detail/detail_page.dart';
import 'modules/login/login_page.dart';
import 'modules/main/main_binding.dart';
import 'modules/main/main_shell_page.dart';
import 'modules/settings/setting_page.dart';

abstract final class AppRoutes {
  static const main = '/';
  static const login = '/login';
  static const detail = '/detail';
  static const setting = '/setting';
}

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.main,
      page: () => const MainShellPage(),
      binding: MainBinding(),
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.detail,
      page: () => const DetailPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.setting,
      page: () => const SettingPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
