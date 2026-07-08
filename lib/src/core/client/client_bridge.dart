import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../json/json.dart';

enum ClientPlatform { ios, android, other }

class ClientPlatformInfo {
  const ClientPlatformInfo({
    required this.platform,
    required this.systemVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.deviceId,
  });

  factory ClientPlatformInfo.fromMap(Map<Object?, Object?> map) {
    return ClientPlatformInfo(
      platform: _stringValue(map['platform']),
      systemVersion: _stringValue(map['systemVersion']),
      appVersion: _stringValue(map['appVersion']),
      buildNumber: _stringValue(map['buildNumber']),
      deviceId: _stringValue(map['deviceId']),
    );
  }

  final String platform;
  final String systemVersion;
  final String appVersion;
  final String buildNumber;
  final String deviceId;

  static String _stringValue(Object? value) => value?.toString() ?? '';

  @override
  bool operator ==(Object other) {
    return other is ClientPlatformInfo &&
        other.platform == platform &&
        other.systemVersion == systemVersion &&
        other.appVersion == appVersion &&
        other.buildNumber == buildNumber &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode =>
      Object.hash(platform, systemVersion, appVersion, buildNumber, deviceId);
}

class ClientProxySettings {
  const ClientProxySettings({
    required this.enabled,
    required this.host,
    required this.port,
  });

  factory ClientProxySettings.fromMap(Map<Object?, Object?> map) {
    final host = _stringValue(map['host']);
    return ClientProxySettings(
      enabled: map['enabled'] == true && host.isNotEmpty,
      host: host,
      port: _intValue(map['port']),
    );
  }

  final bool enabled;
  final String host;
  final int port;

  bool get canApply => enabled && host.isNotEmpty && port > 0;

  static String _stringValue(Object? value) => value?.toString() ?? '';

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) {
    return other is ClientProxySettings &&
        other.enabled == enabled &&
        other.host == host &&
        other.port == port;
  }

  @override
  int get hashCode => Object.hash(enabled, host, port);
}

class TrustDecisionLivenessResult {
  const TrustDecisionLivenessResult({
    required this.success,
    required this.code,
    required this.message,
    required this.image,
    required this.sequenceId,
    required this.livenessId,
    required this.raw,
  });

  final bool success;
  final int code;
  final String message;
  final String image;
  final String sequenceId;
  final String livenessId;
  final Map<String, dynamic> raw;
}

class ClientBridge {
  ClientBridge({ClientPlatform? platform, MethodChannel? channel})
    : _platform = platform ?? _currentPlatform(),
      _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'kaibigan_loan/client_bridge';

  final ClientPlatform _platform;
  final MethodChannel _channel;

  bool get supportsNativeBridge => _platform == ClientPlatform.ios;

  Future<bool> isNativeBridgeAvailable() async {
    if (!supportsNativeBridge) {
      return false;
    }

    final result = await _channel.invokeMethod<bool>('isNativeBridgeAvailable');
    return result ?? false;
  }

  Future<ClientPlatformInfo> getPlatformInfo() async {
    if (!supportsNativeBridge) {
      throw UnsupportedError('ClientBridge is currently implemented for iOS.');
    }

    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getPlatformInfo',
    );
    return ClientPlatformInfo.fromMap(result ?? const <Object?, Object?>{});
  }

  Future<ClientProxySettings> getProxySettings() async {
    if (!supportsNativeBridge) {
      throw UnsupportedError('ClientBridge is currently implemented for iOS.');
    }

    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getProxySettings',
    );
    return ClientProxySettings.fromMap(result ?? const <Object?, Object?>{});
  }

  Future<TrustDecisionLivenessResult> showTrustDecisionLiveness(
    String license,
  ) async {
    if (!supportsNativeBridge) {
      return const TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is only available on iOS.',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{},
      );
    }

    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'showTrustDecisionLiveness',
        license,
      );
      if (result == null) {
        return const TrustDecisionLivenessResult(
          success: false,
          code: -1,
          message: 'Liveness returned no result',
          image: '',
          sequenceId: '',
          livenessId: '',
          raw: <String, dynamic>{},
        );
      }
      final json = Json(result);
      return TrustDecisionLivenessResult(
        success: json['success'].boolOrNull ?? false,
        code: json['code'].intOrNull ?? -1,
        message: json['message'].stringValue,
        image: json['image'].stringValue,
        sequenceId: json['sequence_id'].stringValue,
        livenessId: json['liveness_id'].stringValue,
        raw: json['raw'].rawMapValue,
      );
    } on PlatformException catch (error) {
      return TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: error.message ?? 'Failed to start liveness verification',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{
          'code': error.code,
          if (error.details != null) 'details': error.details,
        },
      );
    } on MissingPluginException {
      return const TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is unavailable.',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{},
      );
    }
  }

  static ClientPlatform _currentPlatform() {
    if (Platform.isIOS) {
      return ClientPlatform.ios;
    }
    if (Platform.isAndroid) {
      return ClientPlatform.android;
    }
    return ClientPlatform.other;
  }
}
