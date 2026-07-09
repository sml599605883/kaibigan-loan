import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get/get.dart' as getx;

import '../json/json.dart';
import 'api_config.dart';
import 'api_endpoints.dart';
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

  static ApiClient get instance => getx.Get.find<ApiClient>();

  final ApiConfig config;
  final Dio dio;
  bool _handlingAuthExpired = false;
  String? _proxyHost;
  int? _proxyPort;

  String? get proxyHost => _proxyHost;
  int? get proxyPort => _proxyPort;

  Future<ApiResponse> homePage() {
    return get(
      ApiEndpoints.homePage,
      params: {'ghastful': _randomDigits(6), 'lairs': _randomDigits(6)},
    );
  }

  Future<ApiResponse> getDeviceName({required String unwits}) {
    return post(
      ApiEndpoints.getDeviceName,
      data: {'unwits': unwits, 'stoups': _randomDigits(6)},
    );
  }

  Future<ApiResponse> sendSmsCode({
    required String potline,
    required String waterbird,
  }) {
    return post(
      ApiEndpoints.sendSmsCode,
      data: {
        'potline': potline,
        'waterbird': waterbird,
        'footbaths': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> supportDeliveryChannels({required String potline}) {
    return post(
      ApiEndpoints.supportDeliveryChannels,
      data: {
        'potline': potline,
        'barned': _randomDigits(6),
        'royalmast': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> smsCodeLogin({
    required String threadier,
    required String informal,
  }) {
    return post(
      ApiEndpoints.smsCodeLogin,
      data: {
        'threadier': threadier,
        'informal': informal,
        'barned': _randomDigits(6),
        'royalmast': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> logout() {
    return get(
      ApiEndpoints.logout,
      params: {'stones': _randomDigits(6), 'viruliferous': _randomDigits(6)},
    );
  }

  Future<ApiResponse> userDelete() {
    return get(ApiEndpoints.userDelete, params: {'archway': _randomDigits(6)});
  }

  Future<ApiResponse> personalCenter() {
    return get(
      ApiEndpoints.personalCenter,
      params: {'deniable': _randomDigits(6)},
    );
  }

  Future<ApiResponse> dialog({required int loungy}) {
    return get(ApiEndpoints.dialog, params: {'loungy': loungy});
  }

  Future<ApiResponse> bannerClickRecord({required String mesial}) {
    return post(
      ApiEndpoints.bannerClickRecord,
      data: {'mesial': mesial, 'stoups': _randomDigits(6)},
    );
  }

  Future<ApiResponse> uploadImage({
    required String commensurate,
    required String gams,
    required String filePath,
    required String fileField,
    String? heirship,
    String? scolloped,
    String? arrests,
    String? clevises,
    String? intemperances,
  }) {
    return upload(
      ApiEndpoints.uploadImage,
      filePath: filePath,
      fileField: fileField,
      data: {
        'commensurate': commensurate,
        'gams': gams,
        'heirship': heirship,
        'scolloped': scolloped,
        'arrests': arrests,
        'clevises': clevises,
        'intemperances': intemperances,
      },
    );
  }

  Future<ApiResponse> reCredit() {
    return get(ApiEndpoints.reCredit, params: {'douzeper': _randomDigits(6)});
  }

  Future<ApiResponse> productApply({
    required String geobotanists,
    String succumbs = '0',
  }) {
    return post(
      ApiEndpoints.productApply,
      data: {
        'enates': '1001',
        'nonfeasance': '1000',
        'chad': '1000',
        'geobotanists': geobotanists,
        'succumbs': succumbs,
        'fib': _randomDigits(6),
        'dyable': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> productDetail({required String geobotanists}) {
    return post(
      ApiEndpoints.productDetail,
      data: {
        'geobotanists': geobotanists,
        'futhorcs': _randomDigits(6),
        'discount': _randomDigits(6),
        'constantans': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> basicPersonInfo({required String geobotanists}) {
    return get(
      ApiEndpoints.basicPersonInfo,
      params: {'geobotanists': geobotanists, 'cosponsored': _randomDigits(6)},
    );
  }

  Future<ApiResponse> saveBasicInfo({
    required String asthmas,
    required String overmanaged,
    required String unwits,
    required String commensurate,
    required String heirship,
  }) {
    return post(
      ApiEndpoints.saveBasicInfo,
      data: {
        'asthmas': asthmas,
        'overmanaged': overmanaged,
        'unwits': unwits,
        'commensurate': commensurate,
        'heirship': heirship,
        'terrific': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> checkBasicInfo({required String geobotanists}) {
    return post(
      ApiEndpoints.checkBasicInfo,
      data: {
        'geobotanists': geobotanists,
        'chutists': _randomDigits(6),
        'spinels': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> personalInfo({required String geobotanists}) {
    return post(
      ApiEndpoints.personalInfo,
      data: {'geobotanists': geobotanists, 'utopians': _randomDigits(6)},
    );
  }

  Future<ApiResponse> getFaceToken({
    required String dodgy,
    required String commensurate,
  }) {
    return post(
      ApiEndpoints.getFaceToken,
      data: {
        'dodgy': dodgy,
        'commensurate': commensurate,
        'absolutest': _randomDigits(6),
        'carjackers': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> savePersonalInfo({required Map<String, dynamic> data}) {
    return post(
      ApiEndpoints.savePersonalInfo,
      data: {
        ...data,
        'enemies': _randomDigits(6),
        'cryophytes': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> jobInfo({required String geobotanists}) {
    return get(
      ApiEndpoints.jobInfo,
      params: {'geobotanists': geobotanists, 'utopians': _randomDigits(6)},
    );
  }

  Future<ApiResponse> saveJobInfo({required Map<String, dynamic> data}) {
    return post(
      ApiEndpoints.saveJobInfo,
      data: {
        ...data,
        'komondors': _randomDigits(6),
        'noncertified': _randomDigits(6),
        'tradescantias': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> contactInfo({required String geobotanists}) {
    return get(
      ApiEndpoints.contactInfo,
      params: {'geobotanists': geobotanists, 'kielbasy': _randomDigits(6)},
    );
  }

  Future<ApiResponse> saveContactInfo({
    required String geobotanists,
    required String fas,
  }) {
    return post(
      ApiEndpoints.saveContactInfo,
      data: {
        'geobotanists': geobotanists,
        'fas': fas,
        'enfranchises': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> bankInfo({required String geobotanists}) {
    return get(
      ApiEndpoints.bankInfo,
      params: {
        'geobotanists': geobotanists,
        'flowerers': _randomDigits(6),
        'multivariate': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> saveBankInfo({
    required String geobotanists,
    required String attach,
  }) {
    return post(
      ApiEndpoints.saveBankInfo,
      data: {'geobotanists': geobotanists, 'attach': attach},
    );
  }

  Future<ApiResponse> userAccountList({required String geobotanists}) {
    return post(
      ApiEndpoints.userAccountList,
      data: {
        'geobotanists': geobotanists,
        'menisci': _randomDigits(6),
        'welders': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> changeOrderAccount({
    required String dodgy,
    required String smokehouse,
  }) {
    return post(
      ApiEndpoints.changeOrderAccount,
      data: {
        'dodgy': dodgy,
        'smokehouse': smokehouse,
        'contextual': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> retainPopup({
    required String bellyache,
    required String seamounts,
  }) {
    return post(
      ApiEndpoints.retainPopup,
      data: {
        'bellyache': bellyache,
        'seamounts': seamounts,
        'cornets': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> trustdecisionReport({
    required String hemolysis,
    required String alchemical,
    required String dwarfishly,
    required String threats,
  }) {
    return post(
      ApiEndpoints.trustdecisionReport,
      data: {
        'hemolysis': hemolysis,
        'alchemical': alchemical,
        'dwarfishly': dwarfishly,
        'threats': threats,
      },
    );
  }

  Future<ApiResponse> appReport({
    required String pontifically,
    required String infamy,
  }) {
    return post(
      ApiEndpoints.uploadAndroidTag,
      data: {
        'pontifically': pontifically,
        'infamy': infamy,
        'gaols': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> orderRedirect({
    required String dodgy,
    required String ecumenicalism,
    required String desertifying,
    required String tythes,
  }) {
    return post(
      ApiEndpoints.orderRedirect,
      data: {
        'dodgy': dodgy,
        'ecumenicalism': ecumenicalism,
        'desertifying': desertifying,
        'tythes': tythes,
        'woods': _randomDigits(6),
        'anlagen': _randomDigits(6),
        'anga': _randomDigits(6),
        'expectorating': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> orderList({
    required String mummies,
    String dissipaters = '1',
    String bewaring = '50',
  }) {
    return post(
      ApiEndpoints.orderList,
      data: {
        'mummies': mummies,
        'dissipaters': dissipaters,
        'bewaring': bewaring,
      },
    );
  }

  Future<ApiResponse> originalCardRetry({required String chattinesses}) {
    return post(
      ApiEndpoints.originalCardRetry,
      data: {'chattinesses': chattinesses},
    );
  }

  Future<ApiResponse> uploadLocation({
    required String phrasemongers,
    required String callee,
    required String clientless,
    required String overtone,
    required String rhodopsins,
    required String lushest,
    String? verticil,
  }) {
    return post(
      ApiEndpoints.uploadLocation,
      data: {
        'verticil': verticil,
        'phrasemongers': phrasemongers,
        'callee': callee,
        'clientless': clientless,
        'overtone': overtone,
        'rhodopsins': rhodopsins,
        'lushest': lushest,
        'embordered': _randomDigits(6),
        'satellites': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> googleMarket({
    required String simplistically,
    required String preadjusts,
  }) {
    return post(
      ApiEndpoints.googleMarket,
      data: {
        'simplistically': simplistically,
        'preadjusts': preadjusts,
        'chickpea': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> buriedPoint({
    required String seamounts,
    required String complement,
    required String chattinesses,
    required String ungulae,
    required String airports,
    required dynamic rhodopsins,
    required dynamic overtone,
    required String butanones,
    required String knockless,
  }) {
    return post(
      ApiEndpoints.buriedPoint,
      data: {
        'seamounts': seamounts,
        'complement': complement,
        'chattinesses': chattinesses,
        'ungulae': ungulae,
        'airports': airports,
        'rhodopsins': rhodopsins,
        'overtone': overtone,
        'butanones': butanones,
        'knockless': knockless,
        'flowerers': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> uploadDeviceInfo({required String fas}) {
    return post(ApiEndpoints.uploadDeviceInfo, data: {'fas': fas});
  }

  Future<ApiResponse> uploadContacts({
    required String fas,
    String commensurate = '3',
  }) {
    return post(
      ApiEndpoints.uploadContacts,
      data: {
        'commensurate': commensurate,
        'fas': fas,
        'crampit': _randomDigits(6),
        'otoplasties': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> uploadAppleToken({required String smolts}) {
    return post(ApiEndpoints.uploadAppleToken, data: {'smolts': smolts});
  }

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

  String _randomDigits(int length) {
    final provider = config.randomDigitsProvider;
    if (provider != null) {
      return provider(length);
    }
    return ApiSignature.randomDigits(length);
  }
}
