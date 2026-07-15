import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_routes.dart';
import '../../assets/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import '../orders/order_list_models.dart';
import '../widgets/section_title.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _phoneNumber = '962****1300';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.appBackground,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 120.h),
        children: [
          const _ProfileSummaryCard(phoneNumber: _phoneNumber),
          SizedBox(height: 20.h),
          const _ServiceSection(),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.profileSummaryCard),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 46.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 37.w),
                child: Image.asset(
                  AppAssets.profileAvatar,
                  width: 66.w,
                  height: 66.h,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                phoneNumber,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.profileHeaderText,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  height: 22 / 18,
                  letterSpacing: 0.56,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 25.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _OrderShortcut(
                  label: 'All order',
                  asset: AppAssets.profileOrderAll,
                  status: OrderListStatus.all,
                ),
                _OrderShortcut(
                  label: 'Outstanding',
                  asset: AppAssets.profileOrderOutstanding,
                  status: OrderListStatus.outstanding,
                ),
                _OrderShortcut(
                  label: 'Settled',
                  asset: AppAssets.profileOrderSettled,
                  status: OrderListStatus.settled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderShortcut extends StatelessWidget {
  const _OrderShortcut({
    required this.label,
    required this.asset,
    required this.status,
  });

  final String label;
  final String asset;
  final OrderListStatus status;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: () =>
            NavigationHelper.toMineOrderList<void>(initialStatus: status),
        child: SizedBox(
          width: 84.w,
          height: 87.h,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.asset(asset, width: 102.w, height: 95.h, fit: BoxFit.fill),
              Padding(
                padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 10.h),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ordersTitleText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      height: 14 / 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceSection extends StatelessWidget {
  const _ServiceSection();

  static const _items = <_ServiceItemData>[
    _ServiceItemData(
      title: 'Online Services',
      asset: AppAssets.profileServiceOnline,
      iconWidth: 21,
      iconHeight: 16,
      webPath: '/#/OverfloodBigamously',
    ),
    _ServiceItemData(
      title: 'Setting',
      asset: AppAssets.profileServiceSetting,
      iconWidth: 17,
      iconHeight: 18,
      routeName: AppRoutes.setting,
    ),
    _ServiceItemData(
      title: 'Privacy Agreement',
      asset: AppAssets.profileServicePrivacy,
      iconWidth: 16,
      iconHeight: 18,
      webPath: '/#/Pastitsios',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Our Service'),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(9.w),
          decoration: BoxDecoration(
            color: AppColors.profileServicePanel,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.profileServiceBorder),
          ),
          child: Column(
            children: [
              for (var index = 0; index < _items.length; index++) ...[
                _ServiceListItem(data: _items[index]),
                if (index != _items.length - 1) SizedBox(height: 10.h),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  const _ServiceListItem({required this.data});

  final _ServiceItemData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: data.onTap,
        child: Ink(
          height: 42.h,
          padding: EdgeInsets.fromLTRB(13.w, 12.h, 13.w, 11.h),
          decoration: BoxDecoration(
            color: AppColors.tabBackground,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 21.w,
                child: Center(
                  child: Image.asset(
                    data.asset,
                    width: data.iconWidth.w,
                    height: data.iconHeight.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.profileServiceText,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    height: 19 / 16,
                  ),
                ),
              ),
              Image.asset(AppAssets.arrowRight, width: 16.w, height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceItemData {
  const _ServiceItemData({
    required this.title,
    required this.asset,
    required this.iconWidth,
    required this.iconHeight,
    this.routeName,
    this.webPath,
  });

  final String title;
  final String asset;
  final double iconWidth;
  final double iconHeight;
  final String? routeName;
  final String? webPath;

  VoidCallback? get onTap {
    final targetRoute = routeName;
    if (targetRoute != null) {
      return () => NavigationHelper.toNamed<void>(targetRoute);
    }
    final targetWebPath = webPath;
    if (targetWebPath != null) {
      return () {
        final webBaseUrl = Get.find<ApiClient>().config.webBaseUrl;
        NavigationHelper.toWebView<void>(
          url: '${webBaseUrl.replaceFirst(RegExp(r'/+$'), '')}$targetWebPath',
        );
      };
    }
    return null;
  }
}
