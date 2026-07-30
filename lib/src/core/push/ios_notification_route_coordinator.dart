import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../navigation_helper.dart';
import '../json/json.dart';
import '../report/report_native_bridge.dart';

typedef NativeNotificationEvents = Stream<Json> Function();
typedef NavigationReady = bool Function();
typedef NotificationRouteOpener = Future<void> Function(String route);
typedef RouteDrainDeferrer = void Function(VoidCallback callback);

class IosNotificationRouteCoordinator {
  IosNotificationRouteCoordinator({
    NativeNotificationEvents? events,
    NavigationReady? navigationReady,
    NotificationRouteOpener? openRoute,
    RouteDrainDeferrer? defer,
  }) : _events = events ?? MethodChannelReportNativeBridge.shared.nativeEvents,
       _navigationReady = navigationReady ?? _isNavigationReady,
       _openRoute = openRoute ?? NavigationHelper.navigateRawTarget,
       _defer = defer ?? _deferUntilNextFrame;

  static final instance = IosNotificationRouteCoordinator();

  final NativeNotificationEvents _events;
  final NavigationReady _navigationReady;
  final NotificationRouteOpener _openRoute;
  final RouteDrainDeferrer _defer;
  final ListQueue<String> _routes = ListQueue<String>();

  StreamSubscription<Json>? _subscription;
  bool _draining = false;
  bool _retryPending = false;

  @visibleForTesting
  int get queuedRouteCount => _routes.length;

  void start() {
    _subscription ??= _events().listen(_accept);
    unawaited(_drain());
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _routes.clear();
    _draining = false;
    _retryPending = false;
  }

  void _accept(Json event) {
    if (event['type'].stringValue != 'push_route') {
      return;
    }
    final route = event['url'].stringValue.trim();
    if (route.isEmpty) {
      return;
    }
    _routes.addLast(route);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining || _routes.isEmpty) {
      return;
    }
    if (!_navigationReady()) {
      _scheduleRetry();
      return;
    }
    _draining = true;
    try {
      while (_routes.isNotEmpty && _navigationReady()) {
        final route = _routes.removeFirst();
        try {
          await _openRoute(route);
        } catch (_) {}
      }
      if (_routes.isNotEmpty) {
        _scheduleRetry();
      }
    } finally {
      _draining = false;
    }
  }

  void _scheduleRetry() {
    if (_retryPending) {
      return;
    }
    _retryPending = true;
    _defer(() {
      _retryPending = false;
      unawaited(_drain());
    });
  }

  static bool _isNavigationReady() => Get.context?.mounted ?? false;

  static void _deferUntilNextFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }
}
