import 'package:get/get.dart';

class MainController extends GetxController {
  final selectedIndex = 0.obs;

  void selectTab(int index) {
    if (selectedIndex.value == index) {
      return;
    }
    selectedIndex.value = index;
  }
}
