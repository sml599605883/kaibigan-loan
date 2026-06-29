import 'package:flutter/services.dart';

import '../client/client_bridge.dart';
import '../network/api_client.dart';
import 'device_info_store.dart';

class DeviceInfoSync {
  const DeviceInfoSync({
    required this.apiClient,
    required this.clientBridge,
    required this.store,
  });

  final ApiClient apiClient;
  final ClientBridge clientBridge;
  final DeviceInfoStore store;

  Future<void> sync() async {
    final platformInfo = await _platformInfo();
    final platform = platformInfo?.platform ?? '';
    if (platform.isEmpty) {
      return;
    }

    try {
      final response = await apiClient.getDeviceName(unwits: platform);
      await store.save(
        gyrofrequency: response.states['gyrofrequency'].stringValue,
        entertainers: response.states['entertainers'].stringValue,
      );
    } catch (e) {
      return;
    }
  }

  Future<ClientPlatformInfo?> _platformInfo() async {
    if (!clientBridge.supportsNativeBridge) {
      return null;
    }
    try {
      return await clientBridge.getPlatformInfo();
    } on PlatformException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }
}
