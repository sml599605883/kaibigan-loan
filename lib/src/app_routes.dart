import 'package:get/get.dart';

import 'modules/account/account_list_page.dart';
import 'modules/certification/certification_bind_card_page.dart';
import 'modules/certification/certification_identity_page.dart';
import 'modules/certification/certification_identity_submit_page.dart';
import 'modules/certification/certification_face_page.dart';
import 'modules/certification/certification_contact_info_page.dart';
import 'modules/certification/certification_personal_info_page.dart';
import 'modules/certification/certification_upload_page.dart';
import 'modules/detail/detail_page.dart';
import 'modules/login/login_page.dart';
import 'modules/main/main_binding.dart';
import 'modules/main/main_shell_page.dart';
import 'modules/orders/mine_order_list_page.dart';
import 'modules/settings/setting_page.dart';
import 'modules/webview/webview_page.dart';
import 'core/json/json.dart';

abstract final class AppRoutes {
  static const main = '/';
  static const login = '/login';
  static const detail = '/detail';
  static const setting = '/setting';
  static const accountList = '/account/list';
  static const mineOrderList = '/mine/order-list';
  static const certificationIdentity = '/certification/identity';
  static const certificationIdentitySubmit = '/certification/identity-submit';
  static const certificationFace = '/certification/face';
  static const certificationPersonalInfo = '/certification/personal-info';
  static const certificationWorkInfo = '/certification/work-info';
  static const certificationContactInfo = '/certification/contact-info';
  static const certificationBindCard = '/certification/bind-card';
  static const certificationUpload = '/certification/upload';
  static const webView = '/webview';
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
      name: AppRoutes.accountList,
      page: () => const AccountListPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.mineOrderList,
      page: () => const MineOrderListPage(),
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
    GetPage(
      name: AppRoutes.certificationPersonalInfo,
      page: () => const CertificationPersonalInfoPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.webView,
      page: () {
        final arguments = Json(Get.arguments);
        return WebViewPage(
          initialUrl: arguments['url'].stringValue,
          initialTitle: arguments['title'].stringOrNull,
        );
      },
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationWorkInfo,
      page: () => const CertificationPersonalInfoPage.work(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationContactInfo,
      page: () => const CertificationContactInfoPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationBindCard,
      page: () => const CertificationBindCardPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
