import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';
import '../orders/orders_page.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';
import 'main_controller.dart';

class MainShellPage extends GetView<MainController> {
  const MainShellPage({super.key});

  static const _pages = <Widget>[HomePage(), OrdersPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => IndexedStack(
            index: controller.selectedIndex.value,
            children: _pages,
          ),
        ),
      ),
      bottomNavigationBar: const _MainTabBar(),
    );
  }
}

class _MainTabBar extends GetView<MainController> {
  const _MainTabBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.tabBackground,
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: AppColors.tabShadow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Obx(
          () => Row(
            children: [
              _TabBarItem(
                label: 'Home',
                selectedAsset: AppAssets.homeSelected,
                normalAsset: AppAssets.homeNormal,
                selected: controller.selectedIndex.value == 0,
                onTap: () => controller.selectTab(0),
              ),
              _TabBarItem(
                label: 'Orders',
                selectedAsset: AppAssets.ordersSelected,
                normalAsset: AppAssets.ordersNormal,
                selected: controller.selectedIndex.value == 1,
                onTap: () => controller.selectTab(1),
              ),
              _TabBarItem(
                label: 'Mine',
                selectedAsset: AppAssets.profileSelected,
                normalAsset: AppAssets.profileNormal,
                selected: controller.selectedIndex.value == 2,
                onTap: () => controller.selectTab(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.label,
    required this.selectedAsset,
    required this.normalAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String selectedAsset;
  final String normalAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Center(
            child: Image.asset(
              selected ? selectedAsset : normalAsset,
              width: 35,
              height: 35,
            ),
          ),
        ),
      ),
    );
  }
}
