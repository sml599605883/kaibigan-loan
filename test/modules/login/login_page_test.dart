import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/modules/login/login_page.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;
  late SessionStore sessionStore;

  setUp(() {
    Get.testMode = true;
    sessionStore = SessionStore.memory();
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

  testWidgets('agreement starts accepted and only policy text is tappable', (
    tester,
  ) async {
    await _pumpLogin(tester);

    expect(find.byKey(const Key('loginAgreementChecked')), findsOneWidget);
    expect(find.byKey(const Key('loginAgreementUnchecked')), findsNothing);

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Privacy Policy'),
      ),
    );
    final root = richText.text as TextSpan;
    expect(root.recognizer, isNull);
    expect((root.children![0] as TextSpan).recognizer, isNull);
    expect((root.children![1] as TextSpan).recognizer, isNotNull);
  });

  testWidgets('get code starts countdown and focuses code field', (
    tester,
  ) async {
    await _pumpLoginWithRoutes(tester);

    await tester.enterText(
      find.byKey(const Key('loginPhoneField')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('loginGetCodeButton')));
    await tester.pump();

    expect(apiClient.smsRequestCount, 1);
    expect(apiClient.lastSmsPhone, '09171234567');
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 0);
    expect(toastPresenter.messages, ['success']);
    expect(find.text('60s'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const Key('loginGetCodeButton')));
    await tester.pump();

    expect(apiClient.smsRequestCount, 1);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('59s'), findsOneWidget);
  });

  testWidgets('get code dismisses loading and shows error when request fails', (
    tester,
  ) async {
    apiClient.smsError = ApiBusinessException('bad phone');
    await _pumpLogin(tester);

    await tester.enterText(
      find.byKey(const Key('loginPhoneField')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('loginGetCodeButton')));
    await tester.pump();

    expect(apiClient.smsRequestCount, 1);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 0);
    expect(toastPresenter.messages, ['bad phone']);
    expect(find.text('60s'), findsNothing);
  });

  testWidgets('enters six digit code and logs in automatically', (
    tester,
  ) async {
    await _pumpLoginWithRoutes(tester);

    await tester.enterText(
      find.byKey(const Key('loginPhoneField')),
      '09171234567',
    );
    await tester.enterText(find.byKey(const Key('loginCodeField')), '123456');
    await tester.pumpAndSettle();

    expect(apiClient.loginRequestCount, 1);
    expect(apiClient.lastLoginPhone, '09171234567');
    expect(apiClient.lastLoginCode, '123456');
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 1);
    expect(toastPresenter.messages, isEmpty);
    expect(await sessionStore.bungee(), 'login-token');
    expect(await sessionStore.phone(), '09171234567');
    expect(await sessionStore.isLoggedIn(), isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(Get.currentRoute, isNot(AppRoutes.login));
    expect(find.byKey(const Key('homePageStub')), findsOneWidget);
    expect(_homeStubInitCount, 1);
  });

  testWidgets('clears code and refocuses when automatic login fails', (
    tester,
  ) async {
    apiClient.loginError = ApiBusinessException('bad code');
    await _pumpLogin(tester);

    await tester.enterText(
      find.byKey(const Key('loginPhoneField')),
      '09171234567',
    );
    await tester.enterText(find.byKey(const Key('loginCodeField')), '123456');
    await tester.pump();
    await tester.pump();

    expect(apiClient.loginRequestCount, 1);
    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 0);
    expect(toastPresenter.messages, ['bad code']);
    expect(await sessionStore.bungee(), '');
    expect(find.text('123456'), findsNothing);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('login page matches empty and ready states', (tester) async {
    await _pumpLogin(tester);

    expect(find.text('Hi!  Welcome'), findsOneWidget);
    expect(find.text('Please fill in your phone number'), findsOneWidget);
    expect(find.text('Send SMS verification code'), findsOneWidget);
    expect(find.text("Let's Go"), findsOneWidget);
    expect(find.byKey(const Key('loginAgreementChecked')), findsOneWidget);

    final disabledButton = tester.widget<DecoratedBox>(
      find.byKey(const Key('loginSubmitDecoration')),
    );
    expect(
      (disabledButton.decoration as BoxDecoration).color,
      AppColors.loginButtonDisabled,
    );

    await tester.enterText(
      find.byKey(const Key('loginPhoneField')),
      '8724723748234',
    );
    await tester.enterText(find.byKey(const Key('loginCodeField')), '213238');
    await tester.pump();

    expect(find.text('8724723748234'), findsOneWidget);
    expect(find.text('213238'), findsOneWidget);

    final enabledButton = tester.widget<DecoratedBox>(
      find.byKey(const Key('loginSubmitDecoration')),
    );
    expect(
      (enabledButton.decoration as BoxDecoration).color,
      AppColors.loginButtonEnabled,
    );
  });

  testWidgets('prefills remembered phone number', (tester) async {
    await sessionStore.savePhone('09175551234');

    await _pumpLogin(tester);
    await tester.pump();

    expect(find.text('09175551234'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('loginCodeField')), '123456');
    await tester.pumpAndSettle();

    expect(apiClient.loginRequestCount, 1);
    expect(apiClient.lastLoginPhone, '09175551234');
    expect(await sessionStore.phone(), '09175551234');
  });
}

Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: LoginPage()));
}

Future<void> _pumpLoginWithRoutes(WidgetTester tester) async {
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
        GetPage(name: AppRoutes.login, page: () => const LoginPage()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(AppRoutes.login);
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

  int smsRequestCount = 0;
  int loginRequestCount = 0;
  String? lastSmsPhone;
  String? lastLoginPhone;
  String? lastLoginCode;
  Object? smsError;
  Object? loginError;

  @override
  Future<ApiResponse> sendSmsCode({
    required String potline,
    required String waterbird,
  }) async {
    smsRequestCount++;
    lastSmsPhone = potline;
    if (smsError != null) {
      throw smsError!;
    }
    return ApiResponse(code: 0, message: 'success', states: Json(null));
  }

  @override
  Future<ApiResponse> smsCodeLogin({
    required String threadier,
    required String informal,
  }) async {
    loginRequestCount++;
    lastLoginPhone = threadier;
    lastLoginCode = informal;
    if (loginError != null) {
      throw loginError!;
    }
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json({'bungee': 'login-token'}),
    );
  }
}
