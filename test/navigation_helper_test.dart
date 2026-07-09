import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/main/main_controller.dart';
import 'package:kaibigan_loan/src/modules/orders/order_list_models.dart';
import 'package:kaibigan_loan/src/navigation_helper.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    toastPresenter = _FakeToastPresenter();
    Get.put<SessionStore>(SessionStore.memory());
    Get.put<ApiClient>(apiClient);
    AppToast.presenter = toastPresenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    NavigationHelper.rawTargetLauncher =
        NavigationHelper.defaultRawTargetLauncher;
    NavigationHelper.logger = NavigationHelper.defaultLogger;
    Get.reset();
  });

  testWidgets('pushes supported app pages through named routes', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    NavigationHelper.toDetail<void>(arguments: 'product-1');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.detail);
    expect(Get.arguments, 'product-1');

    NavigationHelper.toSetting<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.setting);
  });

  testWidgets('routes configured app route names through helper', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    NavigationHelper.toNamed<void>(AppRoutes.setting);
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.setting);
  });

  testWidgets('pushes mine order list with initial status argument', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    NavigationHelper.toMineOrderList<void>(
      initialStatus: OrderListStatus.outstanding,
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.mineOrderList);
    expect(Get.arguments, {'initialStatus': '7'});
  });

  testWidgets('does not push duplicate login route', (tester) async {
    await _pumpRoutes(tester);

    NavigationHelper.toLogin<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(_loginBuildCount, 1);

    final duplicateResult = NavigationHelper.toLogin<void>();
    await tester.pumpAndSettle();

    expect(duplicateResult, isNull);
    expect(Get.currentRoute, AppRoutes.login);
    expect(_loginBuildCount, 1);
  });

  testWidgets('returns to main route and restores home tab', (tester) async {
    await _pumpRoutes(tester);
    final controller = MainController();
    Get.put<MainController>(controller);
    controller.selectedIndex.value = 2;

    NavigationHelper.toDetail<void>();
    await tester.pumpAndSettle();

    NavigationHelper.offAllToMain<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.main);
    expect(controller.selectedIndex.value, 0);
    expect(find.byKey(const Key('detailPageStub')), findsNothing);
    expect(find.byKey(const Key('mainPageStub')), findsOneWidget);
  });

  testWidgets('routes documented kaibigan scheme targets', (tester) async {
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AmoxicillinHistamines',
    );
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.setting);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=product-9',
      arguments: 'stale-product-detail',
    );
    await tester.pumpAndSettle();
    expect(apiClient.productDetailIds, ['product-9']);
    expect(Get.currentRoute, AppRoutes.detail);
    expect(Get.arguments, {
      'geobotanists': 'product-9',
      'scolloped': 'Kaibigan Loan',
    });

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/Peacefulnesses',
    );
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.main);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/ImpleadExpositing',
    );
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.login);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/orderList',
    );
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.mineOrderList);
  });

  testWidgets('product detail public step opens identity verification', (
    tester,
  ) async {
    apiClient.productDetailStates = {
      'grinner': {'unconfusing': 'MistermEncystment'},
      'metallurgists': {'aimless': 'Upload product-10 ID front.'},
      'sensitized': {
        'ecumenicalism': '3000',
        'cabdrivers': 'product-10',
        'chattinesses': 'ORDER010',
        'joyriding': 'loan-name',
        'desertifying': '91',
        'tythes': '1',
      },
    };
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=product-10',
    );
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-10']);
    expect(Get.currentRoute, AppRoutes.certificationIdentity);
    expect(Get.arguments, {'geobotanists': 'product-10'});
    expect(SessionStore.instance.productDetailCache()!.productid, 'product-10');
    expect(
      SessionStore.instance.productDetailCache()!.note['base'],
      'Upload product-10 ID front.',
    );
  });

  testWidgets('product detail face step opens face verification', (
    tester,
  ) async {
    apiClient.productDetailStates = {
      'grinner': {'unconfusing': 'Vesicated'},
      'metallurgists': {'periodontal': 'Start live face verification.'},
      'sensitized': {'cabdrivers': 'product-face'},
    };
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=product-face',
    );
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-face']);
    expect(Get.currentRoute, AppRoutes.certificationFace);
    expect(Get.arguments, {'geobotanists': 'product-face'});
    expect(
      SessionStore.instance.productDetailCache()!.note['face'],
      'Start live face verification.',
    );
  });

  testWidgets('product detail personal step opens personal information', (
    tester,
  ) async {
    apiClient.productDetailStates = {
      'grinner': {'unconfusing': 'Penalization'},
      'sensitized': {'cabdrivers': 'product-personal'},
    };
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=product-personal',
    );
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-personal']);
    expect(Get.currentRoute, AppRoutes.certificationPersonalInfo);
    expect(Get.arguments, {'geobotanists': 'product-personal'});
  });

  testWidgets('product detail work step opens work information', (
    tester,
  ) async {
    apiClient.productDetailStates = {
      'grinner': {'unconfusing': 'Suppressive'},
      'sensitized': {'cabdrivers': 'product-work'},
    };
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=product-work',
    );
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-work']);
    expect(Get.currentRoute, AppRoutes.certificationWorkInfo);
    expect(Get.arguments, {'geobotanists': 'product-work'});
  });

  testWidgets('product detail flow reads product fields from cache', (
    tester,
  ) async {
    apiClient.productDetailStates = {
      'threats': 200,
      'ecumenicalism': '5000',
      'cabdrivers': 'cached-product',
      'chattinesses': 'ORDER-CACHED',
      'desertifying': '14',
      'tythes': '2',
    };
    apiClient.orderRedirectStates = {
      'bloomeries': 'https://h5.example.test/cached-confirm',
    };
    final launchedUris = <Uri>[];
    NavigationHelper.rawTargetLauncher = (uri) async {
      launchedUris.add(uri);
      return true;
    };
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=cached-product',
    );
    await tester.pumpAndSettle();

    expect(apiClient.orderRedirectRequests, [
      {
        'dodgy': 'ORDER-CACHED',
        'ecumenicalism': '5000',
        'desertifying': '14',
        'tythes': '2',
      },
    ]);
    expect(launchedUris.map((uri) => uri.toString()), [
      'https://h5.example.test/cached-confirm',
    ]);
  });

  testWidgets('product detail scheme handles grinner unconfusing first', (
    tester,
  ) async {
    final logs = <String>[];
    NavigationHelper.logger = logs.add;
    final launchedUris = <Uri>[];
    NavigationHelper.rawTargetLauncher = (uri) async {
      launchedUris.add(uri);
      return true;
    };
    apiClient.productDetailStates = {
      'threats': 200,
      'grinner': {'unconfusing': 'CocoShorting'},
      'sensitized': {'cabdrivers': 'product-10', 'chattinesses': 'ORDER001'},
    };
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=product-10',
    );
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-10']);
    expect(apiClient.orderRedirectRequests, isEmpty);
    expect(launchedUris, isEmpty);
    expect(Get.currentRoute, AppRoutes.main);
    expect(logs, [
      'product detail next step: code=CocoShorting, routeKey=bank, productId=product-10',
    ]);
  });

  testWidgets(
    'product detail scheme fetches order redirect for successful detail',
    (tester) async {
      final launchedUris = <Uri>[];
      NavigationHelper.rawTargetLauncher = (uri) async {
        launchedUris.add(uri);
        return true;
      };
      apiClient.productDetailStates = {
        'threats': 200,
        'sensitized': {
          'chattinesses': 'ORDER002',
          'ecumenicalism': '3000',
          'desertifying': '91',
          'tythes': '1',
        },
      };
      apiClient.orderRedirectStates = {
        'bloomeries': 'https://h5.example.test/confirm',
      };
      await _pumpRoutes(tester);

      await NavigationHelper.navigateRawTarget(
        'ph://kaibigan-loan/ios/AlderwomenProtozoology?geobotanists=product-11',
      );
      await tester.pumpAndSettle();

      expect(apiClient.productDetailIds, ['product-11']);
      expect(apiClient.orderRedirectRequests, [
        {
          'dodgy': 'ORDER002',
          'ecumenicalism': '3000',
          'desertifying': '91',
          'tythes': '1',
        },
      ]);
      expect(launchedUris.map((uri) => uri.toString()), [
        'https://h5.example.test/confirm',
      ]);
      expect(Get.currentRoute, AppRoutes.main);
    },
  );

  testWidgets('fetches product detail before opening detail page', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    await NavigationHelper.toProductDetail('product-1');
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-1']);
    expect(apiClient.productApplyIds, isEmpty);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 1);
    expect(toastPresenter.errors, isEmpty);
    expect(Get.currentRoute, AppRoutes.detail);
    expect(Get.arguments, {
      'geobotanists': 'product-1',
      'scolloped': 'Kaibigan Loan',
    });
  });

  testWidgets('apply product follows returned bloomeries before detail', (
    tester,
  ) async {
    final launchedUris = <Uri>[];
    NavigationHelper.rawTargetLauncher = (uri) async {
      launchedUris.add(uri);
      return true;
    };
    apiClient.applyStates = {
      'geobotanists': 'product-2',
      'threats': 302,
      'bloomeries': 'https://h5.example.test/apply-result',
    };
    await _pumpRoutes(tester);

    await NavigationHelper.applyProduct('product-2', succumbs: '7');
    await tester.pumpAndSettle();

    expect(apiClient.productApplyIds, ['product-2']);
    expect(apiClient.productApplySuccumbs, ['7']);
    expect(apiClient.productDetailIds, isEmpty);
    expect(launchedUris.map((uri) => uri.toString()), [
      'https://h5.example.test/apply-result',
    ]);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 1);
    expect(toastPresenter.errors, isEmpty);
    expect(Get.currentRoute, AppRoutes.main);
  });

  testWidgets(
    'apply product falls back to detail request when threats is success',
    (tester) async {
      apiClient.applyStates = <String, dynamic>{'threats': 200};
      await _pumpRoutes(tester);

      await NavigationHelper.applyProduct('product-3');
      await tester.pumpAndSettle();

      expect(apiClient.productApplyIds, ['product-3']);
      expect(apiClient.productApplySuccumbs, ['0']);
      expect(apiClient.productDetailIds, ['product-3']);
      expect(Get.currentRoute, AppRoutes.detail);
      expect(Get.arguments, {
        'geobotanists': 'product-3',
        'scolloped': 'Kaibigan Loan',
      });
    },
  );

  testWidgets('apply product shows response message on failed admission', (
    tester,
  ) async {
    apiClient.applyStates = <String, dynamic>{
      'threats': 505,
      'wofuller': 'apply failed',
    };
    await _pumpRoutes(tester);

    await NavigationHelper.applyProduct('product-5');
    await tester.pumpAndSettle();

    expect(apiClient.productApplyIds, ['product-5']);
    expect(apiClient.productDetailIds, isEmpty);
    expect(toastPresenter.calls, ['loading', 'toast:apply failed', 'dismiss']);
    expect(Get.currentRoute, AppRoutes.main);
  });

  testWidgets('shows API error and stays on current page when detail fails', (
    tester,
  ) async {
    apiClient.productDetailError = ApiBusinessException('detail failed');
    await _pumpRoutes(tester);

    await NavigationHelper.toProductDetail('product-4');
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-4']);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 1);
    expect(toastPresenter.errors, ['detail failed']);
    expect(toastPresenter.calls, ['loading', 'error:detail failed']);
    expect(Get.currentRoute, AppRoutes.main);
  });
}

Future<void> _pumpRoutes(WidgetTester tester) async {
  _loginBuildCount = 0;
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.main,
      getPages: [
        GetPage(name: AppRoutes.main, page: () => const _MainPageStub()),
        GetPage(name: AppRoutes.login, page: () => const _LoginPageStub()),
        GetPage(name: AppRoutes.detail, page: () => const _DetailPageStub()),
        GetPage(name: AppRoutes.setting, page: () => const _SettingPageStub()),
        GetPage(
          name: AppRoutes.mineOrderList,
          page: () => const _MineOrderListPageStub(),
        ),
        GetPage(
          name: AppRoutes.certificationIdentity,
          page: () => const _CertificationIdentityPageStub(),
        ),
        GetPage(
          name: AppRoutes.certificationFace,
          page: () => const _CertificationFacePageStub(),
        ),
        GetPage(
          name: AppRoutes.certificationPersonalInfo,
          page: () => const _CertificationPersonalInfoPageStub(),
        ),
        GetPage(
          name: AppRoutes.certificationWorkInfo,
          page: () => const _CertificationWorkInfoPageStub(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

int _loginBuildCount = 0;

class _MainPageStub extends StatelessWidget {
  const _MainPageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('mainPageStub'));
  }
}

class _LoginPageStub extends StatelessWidget {
  const _LoginPageStub();

  @override
  Widget build(BuildContext context) {
    _loginBuildCount++;
    return const SizedBox(key: Key('loginPageStub'));
  }
}

class _DetailPageStub extends StatelessWidget {
  const _DetailPageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('detailPageStub'));
  }
}

class _SettingPageStub extends StatelessWidget {
  const _SettingPageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('settingPageStub'));
  }
}

class _MineOrderListPageStub extends StatelessWidget {
  const _MineOrderListPageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('mineOrderListPageStub'));
  }
}

class _CertificationIdentityPageStub extends StatelessWidget {
  const _CertificationIdentityPageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('certificationIdentityPageStub'));
  }
}

class _CertificationFacePageStub extends StatelessWidget {
  const _CertificationFacePageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('certificationFacePageStub'));
  }
}

class _CertificationPersonalInfoPageStub extends StatelessWidget {
  const _CertificationPersonalInfoPageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('certificationPersonalInfoPageStub'));
  }
}

class _CertificationWorkInfoPageStub extends StatelessWidget {
  const _CertificationWorkInfoPageStub();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('certificationWorkInfoPageStub'));
  }
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final productApplyIds = <String>[];
  final productApplySuccumbs = <String>[];
  final productDetailIds = <String>[];
  final orderRedirectRequests = <Map<String, String>>[];
  Map<String, dynamic> applyStates = <String, dynamic>{};
  Map<String, dynamic>? productDetailStates;
  Map<String, dynamic> orderRedirectStates = <String, dynamic>{};
  Object? productDetailError;

  @override
  Future<ApiResponse> productApply({
    required String geobotanists,
    String succumbs = '0',
  }) async {
    productApplyIds.add(geobotanists);
    productApplySuccumbs.add(succumbs);
    return ApiResponse(code: 0, message: 'success', states: Json(applyStates));
  }

  @override
  Future<ApiResponse> productDetail({required String geobotanists}) async {
    productDetailIds.add(geobotanists);
    final error = productDetailError;
    if (error != null) {
      throw error;
    }
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(
        productDetailStates ??
            {'geobotanists': geobotanists, 'scolloped': 'Kaibigan Loan'},
      ),
    );
  }

  @override
  Future<ApiResponse> orderRedirect({
    required String dodgy,
    required String ecumenicalism,
    required String desertifying,
    required String tythes,
  }) async {
    orderRedirectRequests.add({
      'dodgy': dodgy,
      'ecumenicalism': ecumenicalism,
      'desertifying': desertifying,
      'tythes': tythes,
    });
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(orderRedirectStates),
    );
  }
}

class _FakeToastPresenter implements ToastPresenter {
  final errors = <String>[];
  final calls = <String>[];
  int showLoadingCount = 0;
  int dismissLoadingCount = 0;

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      dismissLoadingCount++;
      errors.add(message);
      calls.add('error:$message');
      return;
    }
    calls.add('toast:$message');
  }

  @override
  Future<void> showLoading(String? message) async {
    showLoadingCount++;
    calls.add('loading');
  }

  @override
  Future<void> dismissLoading() async {
    dismissLoadingCount++;
    calls.add('dismiss');
  }
}
