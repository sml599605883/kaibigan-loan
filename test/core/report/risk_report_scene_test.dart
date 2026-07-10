import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/report/report_cache.dart';
import 'package:kaibigan_loan/src/core/report/report_manager.dart';
import 'package:kaibigan_loan/src/core/report/report_models.dart';
import 'package:kaibigan_loan/src/core/report/report_native_bridge.dart';
import 'package:kaibigan_loan/src/core/report/report_network.dart';
import 'package:kaibigan_loan/src/core/report/risk_report_scene.dart';
import 'package:kaibigan_loan/src/core/session/product_detail_cache.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test('skips when report manager is not registered', () async {
    RiskReportScene.report(
      productId: 'product-1',
      sceneType: '1',
      startTimeSeconds: 11,
    );

    await Future<void>.delayed(Duration.zero);

    expect(Get.isRegistered<ReportManager>(), isFalse);
  });

  test('reports scene with cached order number fallback', () async {
    final store = SessionStore.memory();
    await store.saveProductDetailCache(
      ProductDetailCache.fromJson({
        'sensitized': {'chattinesses': 'ORDER-1'},
      }),
    );
    final manager = _RecordingReportManager();
    Get.put<SessionStore>(store);
    Get.put<ReportManager>(manager);

    RiskReportScene.report(
      productId: ' product-1 ',
      sceneType: ' 5 ',
      startTimeSeconds: 11,
    );
    await Future<void>.delayed(Duration.zero);

    expect(manager.riskReports, [
      {
        'productId': 'product-1',
        'sceneType': '5',
        'orderNo': 'ORDER-1',
        'startTimeSeconds': 11,
      },
    ]);
  });
}

class _RecordingReportManager extends ReportManager {
  _RecordingReportManager()
    : super(
        cache: _FakeReportCache(),
        nativeBridge: _FakeReportNativeBridge(),
        network: _FakeReportNetwork(),
      );

  final riskReports = <Map<String, Object>>[];

  @override
  Future<void> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required int startTimeSeconds,
  }) async {
    riskReports.add({
      'productId': productId,
      'sceneType': sceneType,
      'orderNo': orderNo,
      'startTimeSeconds': startTimeSeconds,
    });
  }
}

class _FakeReportCache implements ReportCache {
  @override
  Future<void> clearSessionReportState() async {}

  @override
  Future<String> getAttributionLastStatus() async => '';

  @override
  Future<String> getLastMarketSignature() async => '';

  @override
  Future<String> getLastPushToken() async => '';

  @override
  Future<int> getLoginAt() async => 0;

  @override
  Future<ReportLocation?> getLocation() async => null;

  @override
  Future<bool> isAttributionInitialized() async => false;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<bool> markAppOpened() async => false;

  @override
  Future<void> saveLocation(ReportLocation location) async {}

  @override
  Future<void> setAttributionInitialized(bool value) async {}

  @override
  Future<void> setAttributionLastStatus(String value) async {}

  @override
  Future<void> setLastMarketSignature(String signature) async {}

  @override
  Future<void> setLastPushToken(String token) async {}

  @override
  Future<void> setLoginAt(int millis) async {}
}

class _FakeReportNativeBridge implements ReportNativeBridge {
  @override
  Future<NativeDeviceSnapshot> getDeviceSnapshot() async {
    return const NativeDeviceSnapshot();
  }

  @override
  Future<ReportLocation?> getLocation() async => null;

  @override
  Future<String> getPushToken() async => '';

  @override
  Future<String> getTrackingStatus() async => '';

  @override
  Future<void> initializeAttribution(String token) async {}

  @override
  Stream<Json> nativeEvents() => const Stream<Json>.empty();

  @override
  Future<String> requestNotificationPermission() async => '';

  @override
  Future<String> requestTrackingPermission() async => '';
}

class _FakeReportNetwork implements ReportNetwork {
  @override
  Future<void> reportContacts(String encryptedPayload) async {}

  @override
  Future<void> reportDeviceInfo(String encryptedPayload) async {}

  @override
  Future<void> reportFaceResult(FaceReportPayload payload) async {}

  @override
  Future<Json> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async {
    return Json(null);
  }

  @override
  Future<void> reportLocation(ReportLocation location) async {}

  @override
  Future<void> reportPushToken(String token) async {}

  @override
  Future<void> reportRiskBehavior(Map<String, dynamic> payload) async {}
}
