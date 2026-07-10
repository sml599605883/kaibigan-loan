import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../json/json.dart';
import 'report_models.dart';

abstract interface class ReportNativeBridge {
  Stream<Json> nativeEvents();
  Future<String> requestNotificationPermission();
  Future<String> requestTrackingPermission();
  Future<String> getTrackingStatus();
  Future<ReportLocation?> getLocation();
  Future<String> getPushToken();
  Future<NativeDeviceSnapshot> getDeviceSnapshot();
  Future<void> initializeAttribution(String token);
}

class MethodChannelReportNativeBridge implements ReportNativeBridge {
  MethodChannelReportNativeBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('kaibigan_loan/report_method'),
       _eventChannel =
           eventChannel ?? const EventChannel('kaibigan_loan/report_event');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<Json>? _eventStream;

  @override
  Stream<Json> nativeEvents() {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(Json.new)
        .handleError((_) {});
    return _eventStream!;
  }

  @override
  Future<String> requestNotificationPermission() {
    return _invokeString('requestNotificationPermission');
  }

  @override
  Future<String> requestTrackingPermission() {
    return _invokeString('requestTrackingPermission');
  }

  @override
  Future<String> getTrackingStatus() {
    return _invokeString('getTrackingStatus');
  }

  @override
  Future<ReportLocation?> getLocation() async {
    try {
      final result = await _methodChannel.invokeMapMethod<Object?, Object?>(
        'getLocation',
      );
      if (result == null) {
        return null;
      }
      final location = ReportLocation.fromMap(
        result.map((key, value) => MapEntry(key.toString(), value)),
      );
      return location.isValid ? location : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> getPushToken() {
    return _invokeString('getPushToken');
  }

  @override
  Future<NativeDeviceSnapshot> getDeviceSnapshot() async {
    try {
      final result = await _methodChannel.invokeMapMethod<Object?, Object?>(
        'getDeviceSnapshot',
      );
      if (result == null) {
        return _fallbackSnapshot();
      }
      return NativeDeviceSnapshot.fromMap(
        result.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return _fallbackSnapshot();
    }
  }

  @override
  Future<void> initializeAttribution(String token) async {
    if (token.trim().isEmpty) {
      return;
    }
    try {
      await _methodChannel.invokeMethod<void>('initializeAttribution', {
        'token': token.trim(),
      });
    } catch (_) {}
  }

  Future<String> _invokeString(String method) async {
    try {
      final result = await _methodChannel.invokeMethod<Object?>(method);
      return result?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  NativeDeviceSnapshot _fallbackSnapshot() {
    return NativeDeviceSnapshot(
      language: PlatformDispatcher.instance.locale.languageCode,
      timeZoneName: DateTime.now().timeZoneName,
      cpuCoreCount: Platform.numberOfProcessors,
      brand: Platform.operatingSystem,
      model: Platform.localHostname,
      deviceName: Platform.localHostname,
    );
  }
}
