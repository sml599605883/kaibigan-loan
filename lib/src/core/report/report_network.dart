import '../json/json.dart';
import '../network/api_client.dart';
import 'report_models.dart';

abstract interface class ReportNetwork {
  Future<void> reportLocation(ReportLocation location);
  Future<Json> reportGoogleMarket({required String idfv, required String idfa});
  Future<void> reportRiskBehavior(Map<String, dynamic> payload);
  Future<void> reportDeviceInfo(String encryptedPayload);
  Future<void> reportContacts(String encryptedPayload);
  Future<void> reportPushToken(String token);
  Future<void> reportFaceResult(FaceReportPayload payload);
}

class ApiClientReportNetwork implements ReportNetwork {
  ApiClientReportNetwork(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> reportLocation(ReportLocation location) async {
    await _apiClient.uploadLocation(
      verticil: location.province,
      phrasemongers: location.countryCode,
      callee: location.country,
      clientless: location.street,
      overtone: location.latitude,
      rhodopsins: location.longitude,
      lushest: location.city,
    );
  }

  @override
  Future<Json> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async {
    final response = await _apiClient.googleMarket(
      simplistically: idfv,
      preadjusts: idfa,
    );
    return response.states;
  }

  @override
  Future<void> reportRiskBehavior(Map<String, dynamic> payload) async {
    await _apiClient.buriedPoint(
      seamounts: '${payload['seamounts'] ?? ''}',
      complement: '${payload['complement'] ?? ''}',
      chattinesses: '${payload['chattinesses'] ?? ''}',
      ungulae: '${payload['ungulae'] ?? ''}',
      airports: '${payload['airports'] ?? ''}',
      rhodopsins: payload['rhodopsins'] ?? '',
      overtone: payload['overtone'] ?? '',
      butanones: '${payload['butanones'] ?? ''}',
      knockless: '${payload['knockless'] ?? ''}',
    );
  }

  @override
  Future<void> reportDeviceInfo(String encryptedPayload) async {
    await _apiClient.uploadDeviceInfo(fas: encryptedPayload);
  }

  @override
  Future<void> reportContacts(String encryptedPayload) async {
    await _apiClient.uploadContacts(fas: encryptedPayload);
  }

  @override
  Future<void> reportPushToken(String token) async {
    await _apiClient.uploadAppleToken(smolts: token);
  }

  @override
  Future<void> reportFaceResult(FaceReportPayload payload) async {
    await _apiClient.trustdecisionReport(
      hemolysis: payload.livenessId,
      alchemical: payload.requestId,
      dwarfishly: payload.resultCode,
      threats: payload.resultMessage,
    );
  }
}
