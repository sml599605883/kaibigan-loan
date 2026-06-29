import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../client/client_bridge.dart';
import '../device/device_info_store.dart';
import '../device/device_info_sync.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ApiClient> bootstrapApiClient({
  ClientBridge? clientBridge,
  ApiConfig? apiConfig,
  Dio? dio,
  DeviceInfoStore? deviceInfoStore,
}) async {
  if (Get.isRegistered<ApiClient>()) {
    return Get.find<ApiClient>();
  }

  final bridge = clientBridge ?? ClientBridge();
  final store =
      deviceInfoStore ?? DeviceInfoStore(SharedPreferencesAsync());
  final config = apiConfig ?? ApiConfig(clientBridge: bridge, deviceInfoStore: store);
  final apiClient = ApiClient(config, dio: dio);
  Get.put(apiClient, permanent: true);

  try {
    final proxy = await bridge.getProxySettings();
    if (proxy.canApply) {
      apiClient.setProxy(host: proxy.host, port: proxy.port);
    }
  } catch (_) {
    // Proxy discovery is best-effort and must not block app startup.
  }

  await DeviceInfoSync(
    apiClient: apiClient,
    clientBridge: bridge,
    store: store,
  ).sync();

  return apiClient;
}
