import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_crypto.dart';
import 'package:kaibigan_loan/src/core/report/report_attribution_initializer.dart';
import 'package:kaibigan_loan/src/core/report/report_cache.dart';
import 'package:kaibigan_loan/src/core/report/report_device_collector.dart';
import 'package:kaibigan_loan/src/core/report/report_manager.dart';
import 'package:kaibigan_loan/src/core/report/report_models.dart';
import 'package:kaibigan_loan/src/core/report/report_native_bridge.dart';
import 'package:kaibigan_loan/src/core/report/report_network.dart';

void main() {
  late _MemoryReportCache cache;
  late _FakeReportNativeBridge bridge;
  late _FakeReportNetwork network;
  late _FakeAttributionInitializer attributionInitializer;
  late ReportManager manager;

  setUp(() {
    cache = _MemoryReportCache();
    bridge = _FakeReportNativeBridge();
    network = _FakeReportNetwork();
    attributionInitializer = _FakeAttributionInitializer();
    manager = ReportManager(
      cache: cache,
      nativeBridge: bridge,
      network: network,
      attributionInitializer: attributionInitializer,
      startupPermissionDelay: Duration.zero,
      resumePermissionDelay: Duration.zero,
      pushTokenWaitTimeout: const Duration(milliseconds: 20),
      locationWaitTimeout: const Duration(milliseconds: 20),
      now: () => DateTime.fromMillisecondsSinceEpoch(22000),
    );
  });

  test(
    'startup entry is idempotent and starts first-launch listeners',
    () async {
      await manager.onAppStarted();
      await manager.onAppStarted();
      await Future<void>.delayed(Duration.zero);

      expect(cache.hasOpened, isTrue);
      expect(bridge.notificationPermissionRequests, 1);
      expect(bridge.trackingPermissionRequests, 1);
      expect(bridge.nativeEventListenCount, 2);
    },
  );

  test('first final tracking status triggers market report once', () async {
    bridge.snapshot = const NativeDeviceSnapshot(idfv: 'idfv', idfa: 'idfa');

    await manager.onAppStarted();
    bridge.emit({
      'type': 'tracking_status_changed',
      'status': 'not_determined',
    });
    bridge.emit({'type': 'tracking_status_changed', 'status': 'authorized'});
    bridge.emit({'type': 'tracking_status_changed', 'status': 'denied'});
    await Future<void>.delayed(Duration.zero);

    expect(network.googleMarketCalls, 1);
    expect(cache.lastMarketSignature, isEmpty);
    expect(attributionInitializer.tokens, ['adjust-token']);
  });

  test(
    'reports Google market for each invocation with the same device IDs',
    () async {
      bridge.snapshot = const NativeDeviceSnapshot(idfv: 'idfv', idfa: 'idfa');

      await manager.reportGoogleMarket();
      await manager.reportGoogleMarket();

      expect(network.googleMarketCalls, 2);
      expect(cache.lastMarketSignature, isEmpty);
    },
  );

  test(
    'device report uses collector-enriched snapshot before encryption',
    () async {
      cache.loginAt = 1700000000000;
      final crypto = ApiCrypto(
        key: '0123456789abcdef',
        iv: 'fedcba9876543210',
      );
      manager = ReportManager(
        cache: cache,
        nativeBridge: bridge,
        network: network,
        crypto: crypto,
        deviceCollector: ReportDeviceCollector(
          nativeSnapshotProvider: () async {
            return const NativeDeviceSnapshot(idfv: 'idfv');
          },
          packageInfoProvider: () async {
            return const ReportPackageSnapshot(
              packageName: 'loan.kaibigan.app',
              appVersion: '1.2.3',
              buildNumber: '45',
            );
          },
          deviceInfoProvider: () async {
            return <String, dynamic>{
              'systemVersion': '17.5',
              'model': 'iPhone',
              'name': 'User iPhone',
              'utsname': {'machine': 'iPhone15,3'},
            };
          },
        ),
      );

      await manager.reportDeviceInfo();

      final decoded = Json.parse(
        crypto.decryptText(network.devicePayloads.single),
      );
      expect(decoded['chewers'].stringValue, 'loan.kaibigan.app');
      expect(decoded['chlorines'].stringValue, '17.5');
      expect(decoded['blunderer']['multimegawatts'].stringValue, 'iPhone15,3');
    },
  );

  test(
    'location requests reuse one pending native future and cache success',
    () async {
      final completer = Completer<ReportLocation?>();
      bridge.locationFuture = completer.future;

      final first = manager.getCurrentLocation();
      final second = manager.getCurrentLocation();
      completer.complete(
        const ReportLocation(
          fullAddress: 'Makati',
          countryCode: 'PH',
          country: 'Philippines',
          street: 'Ayala',
          latitude: '14.55',
          longitude: '121.02',
          city: 'Makati',
        ),
      );

      expect(await first, same(await second));
      expect(bridge.locationCalls, 1);
      expect(cache.cachedLocation?.city, 'Makati');
    },
  );

  test(
    'risk report falls back to cached location when live location times out',
    () async {
      cache.cachedLocation = const ReportLocation(
        fullAddress: 'Cached',
        countryCode: 'PH',
        country: 'Philippines',
        street: 'Cached Street',
        latitude: '10',
        longitude: '20',
        city: 'Cached City',
      );
      bridge.locationFuture = Completer<ReportLocation?>().future;
      bridge.snapshot = const NativeDeviceSnapshot(
        idfa: 'idfa',
        riskDeviceId: 'risk',
      );

      await manager.reportRiskBehavior(
        productId: '1001',
        sceneType: 'apply',
        orderNo: 'ORD-1',
        startTimeSeconds: 11,
      );

      expect(network.riskPayloads.single['rhodopsins'], '20');
      expect(network.riskPayloads.single['overtone'], '10');
      expect(network.riskPayloads.single['knockless'], '22');
    },
  );

  test(
    'push token upload waits for stream and reports every invocation',
    () async {
      await manager.reportPushToken();
      expect(network.pushTokens, isEmpty);

      final uploadFuture = manager.reportPushToken();
      await Future<void>.delayed(Duration.zero);
      bridge.emit({'type': 'push_token', 'token': 'token-1'});
      bridge.directPushToken = 'token-1';
      await uploadFuture;

      await manager.reportPushToken();

      expect(network.pushTokens, ['token-1', 'token-1']);
      expect(cache.lastPushToken, isEmpty);
    },
  );
}

class _MemoryReportCache implements ReportCache {
  bool hasOpened = false;
  int loginAt = 0;
  bool attributionInitialized = false;
  String attributionLastStatus = '';
  ReportLocation? cachedLocation;
  String lastMarketSignature = '';
  String lastPushToken = '';
  bool loggedIn = true;

  @override
  Future<bool> markAppOpened() async {
    final firstLaunch = !hasOpened;
    hasOpened = true;
    return firstLaunch;
  }

  @override
  Future<void> setLoginAt(int millis) async => loginAt = millis;

  @override
  Future<int> getLoginAt() async => loginAt;

  @override
  Future<bool> isAttributionInitialized() async => attributionInitialized;

  @override
  Future<void> setAttributionInitialized(bool value) async {
    attributionInitialized = value;
  }

  @override
  Future<void> setAttributionLastStatus(String value) async {
    attributionLastStatus = value;
  }

  @override
  Future<String> getAttributionLastStatus() async => attributionLastStatus;

  @override
  Future<void> saveLocation(ReportLocation location) async {
    cachedLocation = location;
  }

  @override
  Future<ReportLocation?> getLocation() async => cachedLocation;

  @override
  Future<String> getLastMarketSignature() async => lastMarketSignature;

  @override
  Future<void> setLastMarketSignature(String signature) async {
    lastMarketSignature = signature;
  }

  @override
  Future<String> getLastPushToken() async => lastPushToken;

  @override
  Future<void> setLastPushToken(String token) async {
    lastPushToken = token;
  }

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<void> clearSessionReportState() async {
    cachedLocation = null;
  }
}

class _FakeReportNativeBridge implements ReportNativeBridge {
  final controller = StreamController<Json>.broadcast();
  int notificationPermissionRequests = 0;
  int trackingPermissionRequests = 0;
  int nativeEventListenCount = 0;
  int locationCalls = 0;
  NativeDeviceSnapshot snapshot = const NativeDeviceSnapshot();
  Future<ReportLocation?>? locationFuture;
  String directPushToken = '';

  void emit(Map<String, dynamic> event) {
    controller.add(Json(event));
  }

  @override
  Stream<Json> nativeEvents() {
    nativeEventListenCount++;
    return controller.stream;
  }

  @override
  Future<String> requestNotificationPermission() async {
    notificationPermissionRequests++;
    return 'granted';
  }

  @override
  Future<String> requestTrackingPermission() async {
    trackingPermissionRequests++;
    return 'authorized';
  }

  @override
  Future<String> getTrackingStatus() async => 'authorized';

  @override
  Future<ReportLocation?> getLocation() {
    locationCalls++;
    return locationFuture ?? Future<ReportLocation?>.value(null);
  }

  @override
  Future<String> getPushToken() async => directPushToken;

  @override
  Future<NativeDeviceSnapshot> getDeviceSnapshot() async => snapshot;

  @override
  Future<void> initializeAttribution(String token) async {}
}

class _FakeReportNetwork implements ReportNetwork {
  int googleMarketCalls = 0;
  final riskPayloads = <Map<String, dynamic>>[];
  final pushTokens = <String>[];
  final devicePayloads = <String>[];

  @override
  Future<Json> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async {
    googleMarketCalls++;
    return Json({'insectivore': 'adjust-token'});
  }

  @override
  Future<void> reportLocation(ReportLocation location) async {}

  @override
  Future<void> reportRiskBehavior(Map<String, dynamic> payload) async {
    riskPayloads.add(payload);
  }

  @override
  Future<void> reportDeviceInfo(String encryptedPayload) async {
    devicePayloads.add(encryptedPayload);
  }

  @override
  Future<void> reportContacts(String encryptedPayload) async {}

  @override
  Future<void> reportPushToken(String token) async {
    pushTokens.add(token);
  }

  @override
  Future<void> reportFaceResult(FaceReportPayload payload) async {}
}

class _FakeAttributionInitializer implements ReportAttributionInitializer {
  final tokens = <String>[];

  @override
  Future<void> initialize(String token) async {
    tokens.add(token);
  }
}
