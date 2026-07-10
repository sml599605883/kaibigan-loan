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
      'vulgates': normalize(snapshot.systemVersion),
      'mycobacteria': lastLoginAtMillis,
      'fluorinating': normalize(snapshot.packageName),
      'lamas': {
        'scalls': snapshot.batteryLevel,
        'hedgehog': snapshot.isCharging,
      },
      'trouser': {
        'zoolatry': normalize(location?.longitude),
        'legendizes': normalize(location?.latitude),
        'unchronological': normalize(location?.fullAddress),
        'embranglement': {
          'dreamlike': normalize(location?.country),
          'paperclips': normalize(location?.countryCode),
          'thionins': normalize(location?.province),
          'baseboards': normalize(location?.city),
          'crural': normalize(location?.locality),
          'compeller': normalize(location?.street),
        },
      },
      'monocarp': {
        'donkeys': normalize(snapshot.idfv),
        'owlishly': normalize(snapshot.idfa),
        'ejaculators': normalize(snapshot.currentWifiBssid),
        'incantational': DateTime.now().millisecondsSinceEpoch,
        'cosponsoring': normalize(snapshot.uptimeMillis),
        'defiances': normalize(snapshot.networkType),
        'recolor': normalize(snapshot.carrier),
        'shrubbiest': normalize(snapshot.language),
        'diphthongizes': normalize(snapshot.timeZoneName),
        'catabolically': snapshot.elapsedMillis,
        'discombobulated': snapshot.isUsingProxy,
        'subrogated': snapshot.isUsingVpn,
        'precommitments': snapshot.isJailbroken,
        'wedeln': snapshot.isEmulator,
      },
      'ritz': {
        'humanity': normalize(snapshot.brand),
        'downshifts': normalize(snapshot.model),
        'cashoo': snapshot.cpuCoreCount,
        'regilds': snapshot.screenHeight,
        'trickily': normalize(snapshot.deviceName),
        'winesap': snapshot.screenWidth,
        'bombings': normalize(snapshot.model),
        'aplombs': normalize(snapshot.screenSize),
        'menazons': normalize(snapshot.systemVersion),
      },
      'sanitorium': {
        'scourges': normalize(snapshot.innerIp),
        'sandlots': [
          {
            'fornices': normalize(snapshot.currentWifiName),
            'colatitudes': normalize(snapshot.currentWifiBssid),
            'ejaculators': normalize(snapshot.currentWifiBssid),
            'jokily': normalize(snapshot.currentWifiName),
          },
        ],
        'crinites': {
          'fornices': normalize(snapshot.currentWifiName),
          'colatitudes': normalize(snapshot.currentWifiBssid),
          'ejaculators': normalize(snapshot.currentWifiBssid),
          'jokily': normalize(snapshot.currentWifiName),
        },
        'etymologist': normalize(
          snapshot.wifiCount > 0
              ? snapshot.wifiCount
              : snapshot.currentWifiBssid.isNotEmpty
              ? 1
              : 0,
        ),
      },
      'clubwomen': {
        'wherever': normalize(snapshot.availableStorage),
        'step': normalize(snapshot.totalStorage),
        'outstarted': normalize(snapshot.totalMemory),
        'trasher': normalize(snapshot.availableMemory),
      },
    };

    return crypto.encryptText(jsonEncode(payload));
  }
}
