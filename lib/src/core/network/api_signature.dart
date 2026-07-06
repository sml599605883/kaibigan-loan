import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../client/client_bridge.dart';
import 'api_config.dart';

class ApiSignature {
  ApiSignature(this.config);

  final ApiConfig config;

  Future<Map<String, dynamic>> buildSignedQuery({
    required String path,
    Map<String, dynamic> extraQuery = const <String, dynamic>{},
  }) async {
    final common = await _commonParams();
    return _buildSignedQuery(
      path: path,
      common: common,
      extraQuery: extraQuery,
    );
  }

  Future<Map<String, dynamic>> _commonParams() async {
    final platformInfo = await _getPlatformInfo();
    final storedDeviceName = await config.sessionStore.gyrofrequency();
    final bungee = await config.sessionStore.bungee();
    return <String, dynamic>{
      'hereat': platformInfo?.appVersion ?? '',
      'gyrofrequency': storedDeviceName,
      'uncurling': platformInfo?.deviceId ?? '',
      'wrongness': platformInfo?.systemVersion ?? '',
      'justing': 'appstore-ph-kaibigan-loan-ios',
      'bungee': bungee,
      'killicks': platformInfo?.deviceId ?? '',
    };
  }

  Future<ClientPlatformInfo?> _getPlatformInfo() async {
    final bridge = config.clientBridge;
    if (!bridge.supportsNativeBridge) {
      return null;
    }

    try {
      return await bridge.getPlatformInfo();
    } on PlatformException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }

  Map<String, dynamic> _buildSignedQuery({
    required String path,
    required Map<String, dynamic> common,
    required Map<String, dynamic> extraQuery,
  }) {
    final mapped = Map<String, dynamic>.from(common);
    mapped['curveballed'] =
        '${config.timestampProvider?.call() ?? DateTime.now().millisecondsSinceEpoch}';

    final signInput = <String, dynamic>{...mapped, 'sublimers': path};
    final query = <String, dynamic>{
      ...mapped,
      ...extraQuery,
      'terrific': _randomDigits(6),
      'feoffer': sign(signInput, config.signatureSecret),
    };
    return query;
  }

  static String sign(Map<String, dynamic> params, String secret) {
    final keys = params.keys.toList()..sort();
    final source = keys.map((key) => '$key${params[key] ?? ''}').join();
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(source)).toString();
  }

  String _randomDigits(int length) {
    final provider = config.randomDigitsProvider;
    if (provider != null) {
      return provider(length);
    }
    return randomDigits(length);
  }

  static String randomDigits(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }
}
