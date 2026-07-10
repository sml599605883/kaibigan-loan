import 'dart:async';

import 'package:get/get.dart' as getx;

import '../network/api_client.dart';
import '../network/api_crypto.dart';
import '../session/session_store.dart';
import 'report_attribution_initializer.dart';
import 'report_cache.dart';
import 'report_device_collector.dart';
import 'report_models.dart';
import 'report_native_bridge.dart';
import 'report_network.dart';
import 'report_payload_helper.dart';

class ReportManager {
  ReportManager({
    required ReportCache cache,
    required ReportNativeBridge nativeBridge,
    required ReportNetwork network,
    Duration startupPermissionDelay = const Duration(milliseconds: 400),
    Duration resumePermissionDelay = const Duration(milliseconds: 400),
    Duration pushTokenWaitTimeout = const Duration(seconds: 5),
    Duration locationWaitTimeout = const Duration(seconds: 3),
    DateTime Function()? now,
    ApiCrypto? crypto,
    ReportDeviceCollector? deviceCollector,
    ReportAttributionInitializer? attributionInitializer,
  }) : _cache = cache,
       _nativeBridge = nativeBridge,
       _network = network,
       _startupPermissionDelay = startupPermissionDelay,
       _resumePermissionDelay = resumePermissionDelay,
       _pushTokenWaitTimeout = pushTokenWaitTimeout,
       _locationWaitTimeout = locationWaitTimeout,
       _now = now ?? DateTime.now,
       _crypto = crypto,
       _deviceCollector = deviceCollector,
       _attributionInitializer = attributionInitializer;

  factory ReportManager.defaultInstance({
    ApiClient? apiClient,
    SessionStore? sessionStore,
    ReportNativeBridge? nativeBridge,
  }) {
    final client = apiClient ?? ApiClient.instance;
    final store = sessionStore ?? getx.Get.find<SessionStore>();
    final bridge = nativeBridge ?? MethodChannelReportNativeBridge();
    return ReportManager(
      cache: SharedPreferencesReportCache(sessionStore: store),
      nativeBridge: bridge,
      network: ApiClientReportNetwork(client),
      deviceCollector: ReportDeviceCollector(
        nativeSnapshotProvider: bridge.getDeviceSnapshot,
      ),
      attributionInitializer: AdjustReportAttributionInitializer(),
      crypto: ApiCrypto(
        key: client.config.encryptKey,
        iv: client.config.encryptIv,
      ),
    );
  }

  static ReportManager get instance {
    if (getx.Get.isRegistered<ReportManager>()) {
      return getx.Get.find<ReportManager>();
    }
    final manager = ReportManager.defaultInstance();
    getx.Get.put(manager, permanent: true);
    return manager;
  }

  final ReportCache _cache;
  final ReportNativeBridge _nativeBridge;
  final ReportNetwork _network;
  final Duration _startupPermissionDelay;
  final Duration _resumePermissionDelay;
  final Duration _pushTokenWaitTimeout;
  final Duration _locationWaitTimeout;
  final DateTime Function() _now;
  final ApiCrypto? _crypto;
  final ReportDeviceCollector? _deviceCollector;
  final ReportAttributionInitializer? _attributionInitializer;

  bool _started = false;
  bool _starting = false;
  bool _resumeHandling = false;
  bool _startupPermissionRequesting = false;
  bool _resumePermissionRequesting = false;
  bool _marketReporting = false;
  bool _pushTokenListenerAttached = false;
  bool _waitingFirstLaunchTracking = false;
  bool _attributionInitializing = false;
  String _reportingPushToken = '';
  Future<ReportLocation?>? _pendingLocationFuture;
  StreamSubscription<dynamic>? _nativeEventSubscription;

  Future<void> onAppStarted() async {
    if (_started || _starting) {
      return;
    }
    _starting = true;
    try {
      final isFirstLaunch = await _cache.markAppOpened();
      if (isFirstLaunch) {
        _waitingFirstLaunchTracking = true;
        _listenNativeEvents();
      }
      _started = true;

      unawaited(_requestStartupPermissions());
      unawaited(reportNativeLocation());
      if (!isFirstLaunch) {
        unawaited(reportGoogleMarket());
      }
      _listenPushTokenChanges();
      unawaited(reportPushToken());
    } finally {
      _starting = false;
    }
  }

  Future<void> onAppResumed() async {
    if (_resumeHandling) {
      return;
    }
    _resumeHandling = true;
    try {
      await _requestResumeTrackingPermission();
      unawaited(reportGoogleMarket());
    } finally {
      _resumeHandling = false;
    }
  }

  Future<void> onLoginSuccess() async {
    await _cache.setLoginAt(_now().millisecondsSinceEpoch);
    unawaited(reportGoogleMarket());
    unawaited(reportNativeLocation());
    unawaited(reportPushToken());
  }

  Future<void> reportNativeLocation() async {
    if (!await _cache.isLoggedIn()) {
      return;
    }
    final location = await getCurrentLocation();
    if (location != null && location.isValid) {
      try {
        await _network.reportLocation(location);
      } catch (error) {
        _log(error);
      }
    }
    if (location?.permissionStatus != 'not_determined') {
      unawaited(reportDeviceInfo());
    }
  }

  Future<void> reportGoogleMarket() async {
    final snapshot = await _nativeBridge.getDeviceSnapshot();
    final signature =
        '${ReportPayloadHelper.normalize(snapshot.idfv)}|${ReportPayloadHelper.normalize(snapshot.idfa)}';
    if (signature == '|' || signature.trim().isEmpty || _marketReporting) {
      return;
    }
    if (await _cache.getLastMarketSignature() == signature) {
      return;
    }

    _marketReporting = true;
    try {
      final response = await _network.reportGoogleMarket(
        idfv: snapshot.idfv,
        idfa: snapshot.idfa,
      );
      await _cache.setLastMarketSignature(signature);
      final token = ReportPayloadHelper.normalize(
        response['insectivore'].stringOrNull,
      );
      await _initializeAttribution(token);
    } catch (error) {
      _log(error);
    } finally {
      _marketReporting = false;
    }
  }

  Future<void> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required int startTimeSeconds,
  }) async {
    try {
      final endTimeSeconds = _now().millisecondsSinceEpoch ~/ 1000;
      final snapshot = await _collectDeviceSnapshot();
      final location = await _resolveLocationWithCacheFallback();
      final payload = ReportPayloadHelper.buildRiskPayload(
        productId: productId,
        sceneType: sceneType,
        orderNo: orderNo,
        snapshot: snapshot,
        location: location,
        startTimeSeconds: startTimeSeconds,
        endTimeSeconds: endTimeSeconds,
      );
      await _network.reportRiskBehavior(payload);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportDeviceInfo() async {
    if (!await _cache.isLoggedIn()) {
      return;
    }
    final crypto = _crypto;
    if (crypto == null) {
      return;
    }
    try {
      final snapshot = await _collectDeviceSnapshot();
      final location = await _resolveLocationWithCacheFallback();
      final encrypted = ReportPayloadHelper.buildEncryptedDevicePayload(
        snapshot: snapshot,
        location: location,
        lastLoginAtMillis: await _cache.getLoginAt(),
        crypto: crypto,
      );
      await _network.reportDeviceInfo(encrypted);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportContacts(String encryptedPayload) async {
    try {
      await _network.reportContacts(encryptedPayload);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportPushToken() async {
    var token = ReportPayloadHelper.normalize(
      await _nativeBridge.getPushToken(),
    );
    if (token.isEmpty) {
      token = await _waitPushTokenFromStream();
    }
    if (token.isEmpty ||
        _reportingPushToken == token ||
        await _cache.getLastPushToken() == token) {
      return;
    }

    _reportingPushToken = token;
    try {
      await _network.reportPushToken(token);
      await _cache.setLastPushToken(token);
    } catch (error) {
      _log(error);
    } finally {
      _reportingPushToken = '';
    }
  }

  Future<void> reportFaceResult(FaceReportPayload payload) async {
    try {
      await _network.reportFaceResult(payload);
    } catch (error) {
      _log(error);
    }
  }

  Future<ReportLocation?> getCurrentLocation() {
    final pending = _pendingLocationFuture;
    if (pending != null) {
      return pending;
    }
    final future = _loadCurrentLocation();
    _pendingLocationFuture = future;
    return future.whenComplete(() {
      _pendingLocationFuture = null;
    });
  }

  Future<ReportLocation?> _loadCurrentLocation() async {
    try {
      final location = await _nativeBridge.getLocation();
      if (location == null || !location.isValid) {
        return null;
      }
      await _cache.saveLocation(location);
      return location;
    } catch (error) {
      _log(error);
      return null;
    }
  }

  Future<ReportLocation?> _resolveLocationWithCacheFallback() async {
    try {
      final location = await getCurrentLocation().timeout(_locationWaitTimeout);
      if (location != null && location.isValid) {
        return location;
      }
    } catch (_) {}
    return _cache.getLocation();
  }

  Future<void> _requestStartupPermissions() async {
    if (_startupPermissionRequesting) {
      return;
    }
    _startupPermissionRequesting = true;
    try {
      await _delay(_startupPermissionDelay);
      await _nativeBridge.requestNotificationPermission();
      await _delay(_startupPermissionDelay);
      await _nativeBridge.requestTrackingPermission();
    } catch (error) {
      _log(error);
    } finally {
      _startupPermissionRequesting = false;
    }
  }

  Future<void> _requestResumeTrackingPermission() async {
    if (_resumePermissionRequesting) {
      return;
    }
    _resumePermissionRequesting = true;
    try {
      await _delay(_resumePermissionDelay);
      await _nativeBridge.requestTrackingPermission();
    } catch (error) {
      _log(error);
    } finally {
      _resumePermissionRequesting = false;
    }
  }

  Future<void> _initializeAttribution(String token) async {
    if (token.isEmpty ||
        _attributionInitializing ||
        await _cache.isAttributionInitialized()) {
      return;
    }
    _attributionInitializing = true;
    try {
      await _attributionInitializer?.initialize(token);
      await _cache.setAttributionInitialized(true);
      await _cache.setAttributionLastStatus('started');
    } catch (error) {
      await _cache.setAttributionLastStatus('start_failed');
      _log(error);
    } finally {
      _attributionInitializing = false;
    }
  }

  void _listenPushTokenChanges() {
    if (_pushTokenListenerAttached) {
      return;
    }
    _pushTokenListenerAttached = true;
    _listenNativeEvents();
  }

  void _listenNativeEvents() {
    _nativeEventSubscription ??= _nativeBridge.nativeEvents().listen((event) {
      final type = event['type'].stringValue;
      if (type == 'tracking_status_changed' && _waitingFirstLaunchTracking) {
        final status = event['status'].stringValue.trim();
        if (status.isEmpty ||
            status == 'not_supported' ||
            status == 'not_determined') {
          return;
        }
        _waitingFirstLaunchTracking = false;
        unawaited(reportGoogleMarket());
      }
      final token = ReportPayloadHelper.normalize(event['token'].stringOrNull);
      if (type == 'push_token' && token.isNotEmpty) {
        unawaited(reportPushToken());
      }
    });
  }

  Future<String> _waitPushTokenFromStream() async {
    try {
      final event = await _nativeBridge
          .nativeEvents()
          .firstWhere((event) {
            return event['type'].stringValue == 'push_token' &&
                ReportPayloadHelper.normalize(
                  event['token'].stringOrNull,
                ).isNotEmpty;
          })
          .timeout(_pushTokenWaitTimeout);
      return ReportPayloadHelper.normalize(event['token'].stringOrNull);
    } catch (_) {
      return '';
    }
  }

  void _log(Object error) {
    error.toString();
  }

  Future<NativeDeviceSnapshot> _collectDeviceSnapshot() {
    final collector = _deviceCollector;
    if (collector != null) {
      return collector.collect();
    }
    return _nativeBridge.getDeviceSnapshot();
  }

  Future<void> _delay(Duration duration) {
    if (duration == Duration.zero) {
      return Future<void>.value();
    }
    return Future<void>.delayed(duration);
  }
}
