import 'dart:convert';

import '../network/api_crypto.dart';
import 'report_models.dart';

class ReportPayloadHelper {
  const ReportPayloadHelper._();

  static String normalize(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }

  static Map<String, dynamic> buildRiskPayload({
    required String productId,
    required String sceneType,
    required String orderNo,
    required NativeDeviceSnapshot snapshot,
    required ReportLocation? location,
    required int startTimeSeconds,
    required int endTimeSeconds,
  }) {
    return {
      'seamounts': normalize(productId),
      'complement': normalize(sceneType),
      'chattinesses': normalize(orderNo),
      'ungulae': normalize(snapshot.riskDeviceId),
      'airports': normalize(snapshot.idfa),
      'rhodopsins': normalize(location?.longitude),
      'overtone': normalize(location?.latitude),
      'butanones': '$startTimeSeconds',
      'knockless': '$endTimeSeconds',
    };
  }

  static String buildEncryptedDevicePayload({
    required NativeDeviceSnapshot snapshot,
    required ReportLocation? location,
    required int lastLoginAtMillis,
    required ApiCrypto crypto,
  }) {
    final payload = {
      'chlorines': normalize(snapshot.systemVersion),
      'overmilking': lastLoginAtMillis,
      'chewers': normalize(snapshot.packageName),
      'pinedrops': {
        'hamster': snapshot.batteryLevel,
        'funnelling': snapshot.isCharging,
      },
      'betwixt': {
        'mucoidal': normalize(location?.longitude),
        'tallaging': normalize(location?.latitude),
        'proselytising': normalize(location?.fullAddress),
        'diddleys': {
          'callee': normalize(location?.country),
          'phrasemongers': normalize(location?.countryCode),
          'verticil': normalize(location?.province),
          'lushest': normalize(location?.city),
          'cooches': normalize(location?.locality),
          'clientless': normalize(location?.street),
        },
      },
      'degases': {
        'simplistically': normalize(snapshot.idfv),
        'preadjusts': normalize(snapshot.idfa),
        'relive': normalize(snapshot.currentWifiBssid),
        'weka': DateTime.now().millisecondsSinceEpoch,
        'teleprocessings': normalize(snapshot.uptimeMillis),
        'linebacker': snapshot.isUsingProxy,
        'purposiveness': snapshot.isUsingVpn,
        'notarizing': snapshot.isJailbroken,
        'dialectologists': snapshot.isEmulator,
        'entombs': normalize(snapshot.language),
        'decussation': normalize(snapshot.carrier),
        'discanted': normalize(snapshot.networkType),
        'prutoth': const <Map<String, dynamic>>[],
        'carbamyls': normalize(snapshot.timeZoneName),
        'exotoxic': snapshot.elapsedMillis,
      },
      'blunderer': {
        'bondages': '',
        'morelles': normalize(snapshot.brand),
        'triumvirs': snapshot.cpuCoreCount,
        'receipted': snapshot.screenHeight,
        'stopper': normalize(snapshot.deviceName),
        'pyroninophilic': snapshot.screenWidth,
        'multimegawatts': normalize(snapshot.model),
        'entertainers': normalize(snapshot.screenSize),
        'leptophos': normalize(snapshot.systemVersion),
      },
      'wany': {
        'easels': normalize(snapshot.innerIp),
        'foodstuffs': [
          {
            'unwits': normalize(snapshot.currentWifiName),
            'initiates': normalize(snapshot.currentWifiBssid),
            'relive': normalize(snapshot.currentWifiBssid),
            'pruriences': normalize(snapshot.currentWifiName),
          },
        ],
        'dismounted': {
          'unwits': normalize(snapshot.currentWifiName),
          'initiates': normalize(snapshot.currentWifiBssid),
          'relive': normalize(snapshot.currentWifiBssid),
          'pruriences': normalize(snapshot.currentWifiName),
        },
        'psychologist': normalize(
          snapshot.wifiCount > 0
              ? snapshot.wifiCount
              : snapshot.currentWifiBssid.isNotEmpty
              ? 1
              : 0,
        ),
      },
      'misrelated': {
        'resonances': normalize(snapshot.availableStorage),
        'exoenzymes': normalize(snapshot.totalStorage),
        'homeschooled': normalize(snapshot.totalMemory),
        'splore': normalize(snapshot.availableMemory),
      },
    };

    return crypto.encryptText(jsonEncode(payload));
  }
}
