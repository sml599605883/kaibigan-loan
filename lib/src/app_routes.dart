import 'package:get/get.dart';

import 'modules/detail/detail_page.dart';
import 'modules/main/main_binding.dart';
import 'modules/main/main_shell_page.dart';

abstract final class AppRoutes {
  static const main = '/';
  static const detail = '/detail';
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
      name: AppRoutes.detail,
      page: () => const DetailPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
