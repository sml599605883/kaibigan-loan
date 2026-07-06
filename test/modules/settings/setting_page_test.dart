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
import 'package:kaibigan_loan/src/modules/settings/setting_page.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;
  late SessionStore sessionStore;

  setUp(() async {
    Get.testMode = true;
    sessionStore = SessionStore.memory();
    await sessionStore.setLoggedIn(true);
    await sessionStore.saveBungee('token');
    apiClient = _FakeApiClient();
    toastPresenter = _FakeToastPresenter();
    Get.put<SessionStore>(sessionStore);
    Get.put<ApiClient>(apiClient);
    AppToast.presenter = toastPresenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    Get.reset();
  });

  testWidgets('logout calls API and returns to existing app home', (
    tester,
  ) async {
    await _pumpSettingWithRoutes(tester);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(apiClient.logoutRequestCount, 1);
    expect(apiClient.deleteRequestCount, 0);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 1);
    expect(toastPresenter.messages, isEmpty);
    expect(await sessionStore.isLoggedIn(), isFalse);
    expect(await sessionStore.bungee(), '');
    expect(Get.find<MainController>().selectedIndex.value, 0);
    expect(Get.currentRoute, AppRoutes.main);
    expect(find.byKey(const Key('homePageStub')), findsOneWidget);
    expect(_homeStubInitCount, 1);
  });

  testWidgets('deactivate calls delete API and returns to existing app home', (
    tester,
  ) async {
    await _pumpSettingWithRoutes(tester);

    await tester.tap(find.text('Deactivate Account'));
    await tester.pumpAndSettle();

    expect(apiClient.deleteRequestCount, 1);
    expect(apiClient.logoutRequestCount, 0);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 1);
    expect(toastPresenter.messages, isEmpty);
    expect(await sessionStore.isLoggedIn(), isFalse);
    expect(Get.find<MainController>().selectedIndex.value, 0);
    expect(Get.currentRoute, AppRoutes.main);
    expect(find.byKey(const Key('homePageStub')), findsOneWidget);
    expect(_homeStubInitCount, 1);
  });

  testWidgets('logout failure keeps setting page and shows API error', (
    tester,
  ) async {
    apiClient.logoutError = ApiBusinessException('logout failed');
    await _pumpSettingWithRoutes(tester);

    await tester.tap(find.text('Logout'));
    await tester.pump();

    expect(apiClient.logoutRequestCount, 1);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 0);
    expect(toastPresenter.messages, ['logout failed']);
    expect(await sessionStore.isLoggedIn(), isTrue);
    expect(Get.currentRoute, AppRoutes.setting);
    expect(find.text('Setting'), findsOneWidget);
  });
}

Future<void> _pumpSettingWithRoutes(WidgetTester tester) async {
  _homeStubInitCount = 0;
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.main,
      getPages: [
        GetPage(name: AppRoutes.main, page: () => const _HomePageStub()),
        GetPage(name: AppRoutes.setting, page: () => const SettingPage()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  if (!Get.isRegistered<MainController>()) {
    Get.put<MainController>(MainController());
  }
  Get.find<MainController>().selectedIndex.value = 2;
  Get.toNamed<void>(AppRoutes.setting);
  await tester.pumpAndSettle();
}

int _homeStubInitCount = 0;

class _HomePageStub extends StatefulWidget {
  const _HomePageStub();

  @override
  State<_HomePageStub> createState() => _HomePageStubState();
}

class _HomePageStubState extends State<_HomePageStub> {
  @override
  void initState() {
    super.initState();
    _homeStubInitCount++;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('homePageStub'));
  }
}

class _FakeToastPresenter implements ToastPresenter {
  final List<String> messages = <String>[];
  int showLoadingCount = 0;
  int dismissLoadingCount = 0;

  @override
  Future<void> show(String message, {required bool isError}) async {
    messages.add(message);
  }

  @override
  Future<void> showLoading(String? message) async {
    showLoadingCount++;
  }

  @override
  Future<void> dismissLoading() async {
    dismissLoadingCount++;
  }
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  int logoutRequestCount = 0;
  int deleteRequestCount = 0;
  Object? logoutError;

  @override
  Future<ApiResponse> logout() async {
    logoutRequestCount++;
    if (logoutError != null) {
      throw logoutError!;
    }
    return ApiResponse(code: 0, message: 'success', states: Json(null));
  }

  @override
  Future<ApiResponse> userDelete() async {
    deleteRequestCount++;
    return ApiResponse(code: 0, message: 'success', states: Json(null));
  }
}
