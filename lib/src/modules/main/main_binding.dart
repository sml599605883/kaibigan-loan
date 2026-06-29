import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import 'main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiClient>()) {
      Get.put(ApiClient(ApiConfig()), permanent: true);
    }
    Get.put(MainController());
  }
}
