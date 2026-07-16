import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_contact_info_page.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_face_page.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_identity_page.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_personal_info_page.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_upload_page.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_retention_guard.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() {
    CertificationRetentionGuard.resetPresenter();
    Get.reset();
  });

  testWidgets('certification page back requests matching retention type', (
    tester,
  ) async {
    final calls = <Map<String, String>>[];
    CertificationRetentionGuard.presenter =
        ({required type, required productId, required onExit}) async {
          calls.add({'type': type, 'productId': productId});
          return false;
        };

    final scenarios = <_RetentionScenario>[
      _RetentionScenario(
        routeName: AppRoutes.certificationIdentity,
        page: () => const CertificationIdentityPage(),
        expectedType: '0',
      ),
      _RetentionScenario(
        routeName: AppRoutes.certificationFace,
        page: () => const CertificationFacePage(),
        expectedType: '1',
      ),
      _RetentionScenario(
        routeName: AppRoutes.certificationPersonalInfo,
        page: () => const CertificationPersonalInfoPage(),
        expectedType: '2',
      ),
      _RetentionScenario(
        routeName: AppRoutes.certificationWorkInfo,
        page: () => const CertificationPersonalInfoPage.work(),
        expectedType: '3',
      ),
      _RetentionScenario(
        routeName: AppRoutes.certificationContactInfo,
        page: () => const CertificationContactInfoPage(),
        expectedType: '4',
      ),
    ];
    Get.put<ApiClient>(_FakeApiClient());
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SizedBox()),
          for (final scenario in scenarios)
            GetPage(name: scenario.routeName, page: scenario.page),
        ],
      ),
    );
    await tester.pumpAndSettle();

    for (final scenario in scenarios) {
      Get.toNamed<void>(
        scenario.routeName,
        arguments: {'geobotanists': 'product-1'},
      );
      await tester.pumpAndSettle();

      await tester.tap(find.image(const AssetImage(AppAssets.loginBack)).first);
      await tester.pumpAndSettle();

      expect(calls.last, {
        'type': scenario.expectedType,
        'productId': 'product-1',
      });
      expect(Get.currentRoute, '/');
    }
  });

  testWidgets('identity upload uses default back without retention request', (
    tester,
  ) async {
    final calls = <Map<String, String>>[];
    CertificationRetentionGuard.presenter =
        ({required type, required productId, required onExit}) async {
          calls.add({'type': type, 'productId': productId});
          return false;
        };
    Get.put<ApiClient>(_FakeApiClient());
    await _pumpPage(
      tester,
      AppRoutes.certificationUpload,
      () => const CertificationUploadPage(),
    );

    await tester.tap(find.image(const AssetImage(AppAssets.loginBack)).first);
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(Get.currentRoute, '/');
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  String routeName,
  Widget Function() page,
) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(name: routeName, page: page),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(routeName, arguments: {'geobotanists': 'product-1'});
  await tester.pumpAndSettle();
}

class _RetentionScenario {
  const _RetentionScenario({
    required this.routeName,
    required this.page,
    required this.expectedType,
  });

  final String routeName;
  final Widget Function() page;
  final String expectedType;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  ApiResponse get _emptyResponse =>
      ApiResponse(code: 0, message: 'success', states: Json(null));

  @override
  Future<ApiResponse> basicPersonInfo({required String geobotanists}) async {
    return _emptyResponse;
  }

  @override
  Future<ApiResponse> personalInfo({required String geobotanists}) async {
    return _emptyResponse;
  }

  @override
  Future<ApiResponse> jobInfo({required String geobotanists}) async {
    return _emptyResponse;
  }

  @override
  Future<ApiResponse> contactInfo({required String geobotanists}) async {
    return _emptyResponse;
  }
}
