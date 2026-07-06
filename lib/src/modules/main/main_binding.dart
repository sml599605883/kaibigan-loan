import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/session/session_store.dart';
import 'main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SessionStore>()) {
      Get.put(SessionStore(SharedPreferencesAsync()), permanent: true);
    }
    if (!Get.isRegistered<ApiClient>()) {
      Get.put(
        ApiClient(ApiConfig(sessionStore: SessionStore.instance)),
        permanent: true,
      );
    }
    Get.put(MainController());
  }
}
