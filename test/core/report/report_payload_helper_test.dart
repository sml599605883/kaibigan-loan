import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/network/api_crypto.dart';
import 'package:kaibigan_loan/src/core/report/report_models.dart';
import 'package:kaibigan_loan/src/core/report/report_payload_helper.dart';

void main() {
  test('normalizes null-like values to empty strings', () {
    expect(ReportPayloadHelper.normalize(null), '');
    expect(ReportPayloadHelper.normalize(' null '), '');
    expect(ReportPayloadHelper.normalize(' Manila '), 'Manila');
  });

  test('builds risk payload with location and end time fields', () {
    final payload = ReportPayloadHelper.buildRiskPayload(
      productId: ' 1001 ',
      sceneType: ' apply ',
      orderNo: ' ORD-1 ',
      snapshot: const NativeDeviceSnapshot(
        idfa: 'idfa-1',
        riskDeviceId: 'risk-1',
      ),
      location: const ReportLocation(
        fullAddress: 'Makati',
        countryCode: 'PH',
        country: 'Philippines',
        street: 'Ayala',
        latitude: '14.55',
        longitude: '121.02',
        city: 'Makati',
      ),
      startTimeSeconds: 11,
      endTimeSeconds: 22,
    );

    expect(payload, {
      'seamounts': '1001',
      'complement': 'apply',
      'chattinesses': 'ORD-1',
      'ungulae': 'risk-1',
      'airports': 'idfa-1',
      'rhodopsins': '121.02',
      'overtone': '14.55',
      'butanones': '11',
      'knockless': '22',
    });
  });

  test('encrypted device payload follows the device-report API contract', () {
    const key = '0123456789abcdef';
    const iv = 'fedcba9876543210';
    final encrypted = ReportPayloadHelper.buildEncryptedDevicePayload(
      snapshot: const NativeDeviceSnapshot(
        idfv: 'idfv-1',
        idfa: 'idfa-1',
        batteryLevel: 70,
        isCharging: 1,
        elapsedMillis: 1234,
        uptimeMillis: '5678',
        isUsingProxy: 1,
        isUsingVpn: 1,
        isJailbroken: 1,
        isEmulator: 1,
        language: 'en',
        carrier: 'Carrier',
        networkType: 'WIFI',
        timeZoneName: 'GMT+8',
        cpuCoreCount: 8,
        brand: 'Apple',
        deviceName: 'User iPhone',
        model: 'iPhone15,3',
        systemVersion: '17.5',
        packageName: 'loan.kaibigan.app',
        screenHeight: 844,
        screenWidth: 390,
        screenSize: '6.1',
        innerIp: '10.0.0.2',
        currentWifiName: 'wifi',
        currentWifiBssid: 'bssid',
        wifiCount: 2,
        availableStorage: '100',
        totalStorage: '200',
        totalMemory: '300',
        availableMemory: '150',
      ),
      location: const ReportLocation(
        fullAddress: 'Makati',
        countryCode: 'PH',
        country: 'Philippines',
        street: 'Ayala',
        latitude: '14.55',
        longitude: '121.02',
        city: 'Makati',
      ),
      lastLoginAtMillis: 1700000000000,
      crypto: ApiCrypto(key: key, iv: iv),
    );

    final decoded =
        jsonDecode(ApiCrypto(key: key, iv: iv).decryptText(encrypted))
            as Map<String, dynamic>;
    final gps = decoded['betwixt'] as Map<String, dynamic>;
    final device = decoded['degases'] as Map<String, dynamic>;
    final hardware = decoded['blunderer'] as Map<String, dynamic>;
    final wifi = decoded['wany'] as Map<String, dynamic>;
    final storage = decoded['misrelated'] as Map<String, dynamic>;

    expect(decoded['chlorines'], '17.5');
    expect(decoded['overmilking'], 1700000000000);
    expect(decoded['chewers'], 'loan.kaibigan.app');
    expect(decoded['pinedrops'], {'hamster': 70, 'funnelling': 1});
    expect(gps['mucoidal'], '121.02');
    expect(gps['tallaging'], '14.55');
    expect(device['teleprocessings'], '5678');
    expect(device['exotoxic'], 1234);
    expect(device['prutoth'], isEmpty);
    expect(hardware['morelles'], 'Apple');
    expect(hardware['leptophos'], '17.5');
    expect(wifi['psychologist'], '2');
    expect(wifi['foodstuffs'], isA<List<dynamic>>());
    expect(storage, {
      'resonances': '100',
      'exoenzymes': '200',
      'homeschooled': '300',
      'splore': '150',
    });
  });
}
