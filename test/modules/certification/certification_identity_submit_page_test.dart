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
import 'package:kaibigan_loan/src/core/session/product_detail_cache.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_identity_submit_page.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late SessionStore sessionStore;
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;

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

  testWidgets('shows recognized id info and cached success prompt', (
    tester,
  ) async {
    await sessionStore.saveProductDetailCache(
      ProductDetailCache.fromJson({
        'metallurgists': {
          'prosencephalic': 'Confirm your recognized ID details.',
        },
      }),
    );

    await _pumpPage(
      tester,
      arguments: {
        'geobotanists': 'product-1',
        'cardType': 'UMID',
        'recognizedInfo': {
          'unwits': 'NAVEEN TOM VARGHESE',
          'overmanaged': '623099344111',
          'asthmas': '1993/11/23',
          'bloomeries': '',
        },
      },
    );

    expect(find.text('Identity verification'), findsOneWidget);
    expect(find.text('Confirm your recognized ID details.'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('NAVEEN TOM VARGHESE'), findsOneWidget);
    expect(find.text('ID No.'), findsOneWidget);
    expect(find.text('623099344111'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('23-11-1993'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submits edited id info to save basic info endpoint', (
    tester,
  ) async {
    apiClient.productDetailStates = {
      'grinner': {'unconfusing': 'Vesicated'},
      'metallurgists': {'periodontal': 'Start face verification.'},
      'sensitized': {'cabdrivers': 'product-2'},
    };
    await _pumpPage(
      tester,
      arguments: {
        'geobotanists': 'product-2',
        'cardType': 'PRC',
        'recognizedInfo': {
          'unwits': 'BANBU',
          'overmanaged': '387740 980198 7862',
          'asthmas': '1996/02/23',
          'bloomeries': '',
        },
      },
    );

    await tester.enterText(
      find.byKey(const Key('identityFullNameInput')),
      'JOSE CRUZ',
    );
    await tester.enterText(
      find.byKey(const Key('identityIdNoInput')),
      'ID-100200',
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.saveRequests, [
      _SaveRequest(
        asthmas: '23-02-1996',
        overmanaged: 'ID-100200',
        unwits: 'JOSE CRUZ',
        commensurate: '11',
        heirship: 'PRC',
      ),
    ]);
    expect(toastPresenter.loadingMessages, [null, null]);
    expect(toastPresenter.dismissCount, 2);
    expect(toastPresenter.messages, isEmpty);
    expect(apiClient.productDetailIds, ['product-2']);
    expect(Get.currentRoute, AppRoutes.certificationFace);
    expect(Get.arguments, {'geobotanists': 'product-2'});
  });

  testWidgets('birthday field opens birthday picker wheels when tapped', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      arguments: {
        'cardType': 'PRC',
        'recognizedInfo': {
          'unwits': 'BANBU',
          'overmanaged': '387740 980198 7862',
          'asthmas': '23-02-1996',
        },
      },
    );

    await tester.tap(find.byKey(const Key('identityBirthdayInput')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('birthdayDayWheel')), findsOneWidget);
    expect(find.byKey(const Key('birthdayMonthWheel')), findsOneWidget);
    expect(find.byKey(const Key('birthdayYearWheel')), findsOneWidget);
  });

  testWidgets('rapid birthday taps open only one picker', (tester) async {
    await _pumpPage(
      tester,
      arguments: {
        'cardType': 'PRC',
        'recognizedInfo': {'asthmas': '23-02-1996'},
      },
    );

    final birthdayInput = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('identityBirthdayInput')),
        matching: find.byType(TextField),
      ),
    );
    birthdayInput.onTap!();
    birthdayInput.onTap!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('certificationBirthdayPicker')),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('certificationBirthdayPicker')), findsNothing);
  });

  testWidgets('birthday Cancel keeps the existing value', (tester) async {
    await _pumpPage(
      tester,
      arguments: {
        'cardType': 'PRC',
        'recognizedInfo': {'asthmas': '23-02-1996'},
      },
    );

    await tester.tap(find.byKey(const Key('identityBirthdayInput')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(_birthdayText(tester), '23-02-1996');
  });

  testWidgets('birthday Done keeps and normalizes the existing value', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      arguments: {
        'cardType': 'PRC',
        'recognizedInfo': {'asthmas': '23/11/1993'},
      },
    );

    await tester.tap(find.byKey(const Key('identityBirthdayInput')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(_birthdayText(tester), '23-11-1993');
  });

  testWidgets('empty birthday Done fills today in dd-MM-yyyy format', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      arguments: {
        'cardType': 'PRC',
        'recognizedInfo': {'asthmas': ''},
      },
    );

    final beforeOpen = DateTime.now();
    await tester.tap(find.byKey(const Key('identityBirthdayInput')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final afterDone = DateTime.now();

    expect(
      _birthdayText(tester),
      isIn({_formatDate(beforeOpen), _formatDate(afterDone)}),
    );
  });

  testWidgets('shows API error when save basic info fails', (tester) async {
    apiClient.error = ApiBusinessException('save failed');

    await _pumpPage(
      tester,
      arguments: {
        'cardType': 'SSS',
        'recognizedInfo': {
          'unwits': 'BANBU',
          'overmanaged': '387740 980198 7862',
          'asthmas': '23-02-1996',
        },
      },
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(toastPresenter.dismissCount, 1);
    expect(toastPresenter.errors, ['save failed']);
  });
}

String _birthdayText(WidgetTester tester) {
  final birthdayField = find.descendant(
    of: find.byKey(const Key('identityBirthdayInput')),
    matching: find.byType(TextField),
  );
  return tester.widget<TextField>(birthdayField).controller!.text;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

Future<void> _pumpPage(WidgetTester tester, {required Object arguments}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(
          name: AppRoutes.certificationIdentitySubmit,
          page: () => const CertificationIdentitySubmitPage(),
        ),
        GetPage(
          name: AppRoutes.certificationFace,
          page: () => const SizedBox(key: Key('certificationFacePage')),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(
    AppRoutes.certificationIdentitySubmit,
    arguments: arguments,
  );
  await tester.pumpAndSettle();
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final saveRequests = <_SaveRequest>[];
  final productDetailIds = <String>[];
  Map<String, dynamic>? productDetailStates;
  Object? error;

  @override
  Future<ApiResponse> saveBasicInfo({
    required String asthmas,
    required String overmanaged,
    required String unwits,
    required String commensurate,
    required String heirship,
  }) async {
    saveRequests.add(
      _SaveRequest(
        asthmas: asthmas,
        overmanaged: overmanaged,
        unwits: unwits,
        commensurate: commensurate,
        heirship: heirship,
      ),
    );
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    return ApiResponse(code: 0, message: 'saved', states: Json(null));
  }

  @override
  Future<ApiResponse> productDetail({required String geobotanists}) async {
    productDetailIds.add(geobotanists);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(productDetailStates ?? <String, dynamic>{}),
    );
  }
}

class _SaveRequest {
  const _SaveRequest({
    required this.asthmas,
    required this.overmanaged,
    required this.unwits,
    required this.commensurate,
    required this.heirship,
  });

  final String asthmas;
  final String overmanaged;
  final String unwits;
  final String commensurate;
  final String heirship;

  @override
  bool operator ==(Object other) {
    return other is _SaveRequest &&
        other.asthmas == asthmas &&
        other.overmanaged == overmanaged &&
        other.unwits == unwits &&
        other.commensurate == commensurate &&
        other.heirship == heirship;
  }

  @override
  int get hashCode =>
      Object.hash(asthmas, overmanaged, unwits, commensurate, heirship);
}

class _FakeToastPresenter implements ToastPresenter {
  final loadingMessages = <String?>[];
  final messages = <String>[];
  final errors = <String>[];
  int dismissCount = 0;

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      dismissCount++;
      errors.add(message);
    } else {
      messages.add(message);
    }
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessages.add(message);
  }

  @override
  Future<void> dismissLoading() async {
    dismissCount++;
  }
}
