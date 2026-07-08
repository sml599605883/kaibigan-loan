import 'package:get/get.dart';

import 'modules/certification/certification_identity_page.dart';
import 'modules/certification/certification_identity_submit_page.dart';
import 'modules/certification/certification_face_page.dart';
import 'modules/certification/certification_upload_page.dart';
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
  static const certificationIdentity = '/certification/identity';
  static const certificationIdentitySubmit = '/certification/identity-submit';
  static const certificationFace = '/certification/face';
  static const certificationUpload = '/certification/upload';
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
    GetPage(
      name: AppRoutes.certificationIdentity,
      page: () => const CertificationIdentityPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationUpload,
      page: () => const CertificationUploadPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationIdentitySubmit,
      page: () => const CertificationIdentitySubmitPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationFace,
      page: () => const CertificationFacePage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
