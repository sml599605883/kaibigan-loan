import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../json/json.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'api_signature.dart';

class ApiClient {
  ApiClient(this.config, {Dio? dio}) : dio = dio ?? Dio() {
    this.dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20)
      ..contentType = Headers.formUrlEncodedContentType
      ..validateStatus = (_) => true;
  }

  final ApiConfig config;
  final Dio dio;
  bool _handlingAuthExpired = false;
  String? _proxyHost;
  int? _proxyPort;

  String? get proxyHost => _proxyHost;
  int? get proxyPort => _proxyPort;

  void setProxy({
    required String host,
    required int port,
    bool allowBadCertificates = false,
  }) {
    _proxyHost = host;
    _proxyPort = port;
    dio.httpClientAdapter.close(force: true);
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient()..findProxy = (_) => 'PROXY $host:$port;';
        if (allowBadCertificates) {
          client.badCertificateCallback = (certificate, host, port) => true;
        }
        return client;
      },
    );
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic> params = const <String, dynamic>{},
  }) async {
    final query = await ApiSignature(
      config,
    ).buildSignedQuery(path: _clearPath(path), extraQuery: params);
    final response = await dio.get<dynamic>(_url(path), queryParameters: query);
    return _handleResponse(response.data);
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> query = const <String, dynamic>{},
    Options? options,
  }) async {
    final signedQuery = await ApiSignature(
      config,
    ).buildSignedQuery(path: _clearPath(path), extraQuery: query);
    final response = await dio.post<dynamic>(
      _url(path),
      queryParameters: signedQuery,
      data: data,
      options: options,
    );
    return _handleResponse(response.data);
  }

  Future<ApiResponse> upload(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> query = const <String, dynamic>{},
    bool fallbackToPostWhenMissing = false,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      if (fallbackToPostWhenMissing) {
        return post(path, data: data, query: query);
      }
      throw ApiBusinessException('Upload file does not exist');
    }

    final signedQuery = await ApiSignature(
      config,
    ).buildSignedQuery(path: _clearPath(path), extraQuery: query);
    final formData = FormData.fromMap({
      ...data,
      fileField: await MultipartFile.fromFile(file.path),
    });
    final response = await dio.post<dynamic>(
      _url(path),
      queryParameters: signedQuery,
      data: formData,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return _handleResponse(response.data);
  }

  Future<ApiResponse> postEncrypted(
    String path, {
    required String encryptedField,
    required String encryptedValue,
    Map<String, dynamic> query = const <String, dynamic>{},
    Options? options,
  }) {
    return post(
      path,
      query: query,
      data: {encryptedField: encryptedValue},
      options: options,
    );
  }

  Future<void> bootstrapBaseUrls({
    String defaultProbePath = '/',
    String? remoteConfigUrl,
  }) async {
    try {
      final response = await dio.get<dynamic>(_url(defaultProbePath));
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 400) {
        return;
      }
    } catch (_) {
      // Fall through to remote config.
    }

    final configUrl = remoteConfigUrl ?? config.remoteConfigUrl;
    if (configUrl.isEmpty) {
      return;
    }

    try {
      final response = await dio.get<dynamic>(configUrl);
      final body = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      final parsed = _parseRemoteConfig(body);
      final api = parsed['api'].stringValue;
      final web = parsed['web'].stringValue;
      if (api.isNotEmpty) {
        config.apiBaseUrl = api;
      }
      if (web.isNotEmpty) {
        config.webBaseUrl = web;
      }
    } catch (_) {
      return;
    }
  }

  Future<ApiResponse> _handleResponse(dynamic raw) async {
    final response = ApiResponse.fromRaw(raw);
    if (response.isAuthExpired) {
      await _handleAuthExpired();
    }
    return response.ensureSuccess();
  }

  Future<void> _handleAuthExpired() async {
    if (_handlingAuthExpired) {
      throw ApiBusinessException('Login expired', code: '-2');
    }
    _handlingAuthExpired = true;
    try {
      await config.authExpiredHandler?.call();
    } finally {
      _handlingAuthExpired = false;
    }
    throw ApiBusinessException('Login expired', code: '-2');
  }

  Json _parseRemoteConfig(String body) {
    var parsed = Json.parse(body);
    if (parsed.mapOrNull != null) {
      return parsed;
    }
    try {
      parsed = Json.parse(utf8.decode(base64Decode(body.trim())));
    } catch (_) {
      return Json(null);
    }
    return parsed;
  }

  String _url(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${config.apiBaseUrl}${path.startsWith('/') ? path : '/$path'}';
  }

  String _clearPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null || !uri.hasScheme) {
      return path;
    }
    return uri.path;
  }
}
