import 'package:flutter/services.dart';

import '../client/client_bridge.dart';
import '../network/api_client.dart';
import '../session/session_store.dart';

class DeviceInfoSync {
  const DeviceInfoSync({
    required this.apiClient,
    required this.clientBridge,
    required this.store,
    this.platformInfoAttempts = 3,
    this.platformInfoRetryDelay = const Duration(milliseconds: 100),
  }) : assert(platformInfoAttempts > 0);

  final ApiClient apiClient;
  final ClientBridge clientBridge;
  final SessionStore store;
  final int platformInfoAttempts;
  final Duration platformInfoRetryDelay;

  Future<void> sync() async {
    final platformInfo = await _platformInfo();
    final platform = platformInfo?.platform ?? '';
    if (platform.isEmpty) {
      return;
    }

    try {
      final response = await apiClient.bootstrapBaseUrls(unwits: platform);
      if (response == null) {
        return;
      }
      await store.saveDeviceInfo(
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

    for (var attempt = 0; attempt < platformInfoAttempts; attempt++) {
      try {
        final info = await clientBridge.getPlatformInfo();
        if (info.platform.isNotEmpty) {
          return info;
        }
      } on MissingPluginException {
        // The implicit Flutter engine may still be registering its channels.
      } on PlatformException {
        // Retry transient channel failures during cold startup.
      } on UnsupportedError {
        return null;
      }

      if (attempt + 1 < platformInfoAttempts) {
        await Future<void>.delayed(platformInfoRetryDelay);
      }
    }
    return null;
  }
}
