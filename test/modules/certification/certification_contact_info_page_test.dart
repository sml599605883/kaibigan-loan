import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_contact_info_page.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_selection_sheet.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    toastPresenter = _FakeToastPresenter();
    Get.put<ApiClient>(apiClient);
    AppToast.presenter = toastPresenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    Get.reset();
  });

  testWidgets('loads and displays documented emergency contact groups', (
    tester,
  ) async {
    apiClient.contactInfoStates = {
      'backdating': {
        'religiosities': [
          {
            'flashbulbs': 'first',
            'scenarists': '5',
            'unwits': 'Anna',
            'daybed': '86543217190',
            'hosted': [
              {'unwits': 'Friend', 'commensurate': '5'},
            ],
          },
        ],
      },
      'mourningly': 'We will protect your personal information from disclosure',
    };

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SizedBox()),
          GetPage(
            name: '/contact',
            page: () => const CertificationContactInfoPage(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    Get.toNamed<void>(
      '/contact',
      arguments: {'geobotanists': 'product-contact'},
    );
    await tester.pumpAndSettle();

    expect(apiClient.contactInfoIds, ['product-contact']);
    expect(find.text('Emergency Contacts - 1'), findsOneWidget);
    expect(find.text('Friend'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('86543217190'), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('contactInfoProgressImage')),
                  )
                  .image
              as AssetImage)
          .assetName,
      AppAssets.certificationContactProgress,
    );
    expect(
      find.byKey(const Key('contactInfoRelationshipArrow_first')),
      findsOneWidget,
    );
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('contactInfoPicker_first')),
                  )
                  .image
              as AssetImage)
          .assetName,
      AppAssets.contactPickerIcon,
    );
  });

  testWidgets('selects a relationship with the existing selection sheet', (
    tester,
  ) async {
    apiClient.contactInfoStates = _contactInfoStates();

    await _pumpPage(tester);

    await tester.tap(find.text('Friend'));
    await tester.pumpAndSettle();

    expect(find.byType(CertificationSelectionSheet<String>), findsOneWidget);
    await tester.tap(find.text('Parent'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Parent'), findsOneWidget);
  });

  testWidgets('fills name and preferred phone from the native contact picker', (
    tester,
  ) async {
    apiClient.contactInfoStates = _contactInfoStates();
    const channel = MethodChannel('flutter_native_contact_picker');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      expect(call.method, 'selectContact');
      return {
        'fullName': 'Maria Santos',
        'phoneNumbers': ['09170000000'],
        'selectedPhoneNumber': '09175551234',
      };
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await _pumpPage(tester);
    await tester.tap(find.byKey(const Key('contactInfoContact_first')));
    await tester.pumpAndSettle();

    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('09175551234'), findsOneWidget);
  });

  testWidgets('saves documented contact JSON and continues product flow', (
    tester,
  ) async {
    apiClient.contactInfoStates = _contactInfoStates();

    await _pumpPage(tester);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.saveContactInfoRequests, hasLength(1));
    expect(
      apiClient.saveContactInfoRequests.single.geobotanists,
      'product-contact',
    );
    expect(jsonDecode(apiClient.saveContactInfoRequests.single.fas), [
      {
        'daybed': '86543217190',
        'unwits': 'Anna',
        'scenarists': '5',
        'flashbulbs': 'first',
      },
    ]);
    expect(apiClient.productDetailIds, ['product-contact']);
    expect(toastPresenter.loadingMessages, [null, null]);
    expect(toastPresenter.dismissCount, 2);
  });

  testWidgets('retries contact loading after an API failure', (tester) async {
    apiClient.contactInfoError = ApiBusinessException('contact failed');

    await _pumpPage(tester);

    expect(toastPresenter.errors, ['contact failed']);
    expect(find.text('Retry'), findsOneWidget);

    apiClient.contactInfoError = null;
    apiClient.contactInfoStates = _contactInfoStates();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(apiClient.contactInfoIds, ['product-contact', 'product-contact']);
    expect(find.text('Anna'), findsOneWidget);
  });
}

Future<void> _pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(
          name: '/contact',
          page: () => const CertificationContactInfoPage(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>('/contact', arguments: {'geobotanists': 'product-contact'});
  await tester.pumpAndSettle();
}

Map<String, dynamic> _contactInfoStates() {
  return {
    'backdating': {
      'religiosities': [
        {
          'flashbulbs': 'first',
          'scenarists': '5',
          'unwits': 'Anna',
          'daybed': '86543217190',
          'hosted': [
            {'unwits': 'Parent', 'commensurate': '1'},
            {'unwits': 'Friend', 'commensurate': '5'},
          ],
        },
      ],
    },
  };
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final contactInfoIds = <String>[];
  final saveContactInfoRequests = <_SaveContactInfoRequest>[];
  final productDetailIds = <String>[];
  Map<String, dynamic> contactInfoStates = <String, dynamic>{};
  Object? contactInfoError;

  @override
  Future<ApiResponse> contactInfo({required String geobotanists}) async {
    contactInfoIds.add(geobotanists);
    final error = contactInfoError;
    if (error != null) {
      throw error;
    }
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(contactInfoStates),
    );
  }

  @override
  Future<ApiResponse> saveContactInfo({
    required String geobotanists,
    required String fas,
  }) async {
    saveContactInfoRequests.add(
      _SaveContactInfoRequest(geobotanists: geobotanists, fas: fas),
    );
    return ApiResponse(code: 0, message: 'saved', states: Json(null));
  }

  @override
  Future<ApiResponse> productDetail({required String geobotanists}) async {
    productDetailIds.add(geobotanists);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json({'wofuller': 'next step'}),
    );
  }
}

class _SaveContactInfoRequest {
  const _SaveContactInfoRequest({
    required this.geobotanists,
    required this.fas,
  });

  final String geobotanists;
  final String fas;
}

class _FakeToastPresenter implements ToastPresenter {
  final loadingMessages = <String?>[];
  final errors = <String>[];
  int dismissCount = 0;

  @override
  Future<void> dismissLoading() async {
    dismissCount++;
  }

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      errors.add(message);
    }
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessages.add(message);
  }
}
