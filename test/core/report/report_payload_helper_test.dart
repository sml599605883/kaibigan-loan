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

  test('encrypted device payload keeps elapsed and uptime separate', () {
    const key = 'key';
    const iv = 'iv';
    final encrypted = ReportPayloadHelper.buildEncryptedDevicePayload(
      snapshot: const NativeDeviceSnapshot(
        idfv: 'idfv-1',
        idfa: 'idfa-1',
        elapsedMillis: 1234,
        uptimeMillis: '5678',
        currentWifiName: 'wifi',
        currentWifiBssid: 'bssid',
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
    final device = decoded['monocarp'] as Map<String, dynamic>;
    final wifi = decoded['sanitorium'] as Map<String, dynamic>;

    expect(device['catabolically'], 1234);
    expect(device['cosponsoring'], '5678');
    expect(wifi['etymologist'], '1');
    expect(wifi['sandlots'], isA<List<dynamic>>());
  });
}
