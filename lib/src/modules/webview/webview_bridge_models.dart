import 'dart:convert';

import '../../core/json/json.dart';

class WebViewBridgeRequest {
  const WebViewBridgeRequest({
    required this.action,
    required this.callbackId,
    required this.data,
    required this.rawData,
  });

  factory WebViewBridgeRequest.fromRawMessage(String rawMessage) {
    return WebViewBridgeRequest.fromRawObject(Json.parse(rawMessage).value);
  }

  factory WebViewBridgeRequest.fromRawObject(Object? rawObject) {
    final source = Json(rawObject).rawMapValue;
    final rawData = source['data'] ?? source['payload'] ?? source['params'];
    return WebViewBridgeRequest(
      action: _readString(source, const <String>['action', 'name']),
      callbackId: _readString(source, const <String>[
        'callbackId',
        'callback',
        'id',
      ]),
      data: _readData(rawData),
      rawData: rawData,
    );
  }

  final String action;
  final String callbackId;
  final Map<String, dynamic> data;
  final Object? rawData;

  bool get expectsCallback => callbackId.isNotEmpty;

  String get rawDataString {
    final raw = rawData;
    if (raw is String) {
      return raw.trim();
    }
    return Json(raw).stringOrNull?.trim() ?? '';
  }

  static String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = Json(source[key]).stringOrNull?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static Map<String, dynamic> _readData(Object? rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    if (rawData is Map) {
      return rawData.map(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    if (rawData is String && rawData.trim().isNotEmpty) {
      return Json.parse(rawData).rawMapValue;
    }
    return <String, dynamic>{};
  }
}

class WebViewBridgeResult {
  const WebViewBridgeResult({
    required this.code,
    required this.message,
    this.data = const <String, dynamic>{},
  });

  factory WebViewBridgeResult.success([
    Map<String, dynamic> data = const <String, dynamic>{},
  ]) {
    return WebViewBridgeResult(code: 0, message: 'success', data: data);
  }

  factory WebViewBridgeResult.failure(
    String message, {
    int code = -1,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    return WebViewBridgeResult(code: code, message: message, data: data);
  }

  final int code;
  final String message;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'message': message,
    'data': data,
  };

  String encode() => jsonEncode(toJson());
}
