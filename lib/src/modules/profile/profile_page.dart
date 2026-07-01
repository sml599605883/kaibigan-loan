import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import '../widgets/section_title.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _phoneNumber = '962****1300';

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return ColoredBox(
      color: AppColors.appBackground,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: screen.edgeInsetsFromLTRB(20, 0, 20, 120),
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
    final screen = ScreenAdapter.of(context);

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
          SizedBox(height: screen.h(46.h)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 37.w),
                child: Image.asset(
                  AppAssets.profileAvatar,
                  width: screen.w(66),
                  height: screen.h(66),
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                phoneNumber,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.profileHeaderText,
                  fontSize: screen.sp(18),
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
                ),
                _OrderShortcut(
                  label: 'Outstanding',
                  asset: AppAssets.profileOrderOutstanding,
                ),
                _OrderShortcut(
                  label: 'Settled',
                  asset: AppAssets.profileOrderSettled,
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
  const _OrderShortcut({required this.label, required this.asset});

  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: screen.borderRadiusAll(10),
        onTap: () {},
        child: SizedBox(
          width: screen.w(84),
          height: screen.h(87),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.asset(
                asset,
                width: screen.w(102),
                height: screen.h(95),
                fit: BoxFit.fill,
              ),
              Padding(
                padding: screen.edgeInsetsOnly(left: 4, right: 4, bottom: 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ordersTitleText,
                      fontSize: screen.sp(12),
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
    ),
    _ServiceItemData(
      title: 'Setting',
      asset: AppAssets.profileServiceSetting,
      iconWidth: 17,
      iconHeight: 18,
    ),
    _ServiceItemData(
      title: 'Privacy Agreement',
      asset: AppAssets.profileServicePrivacy,
      iconWidth: 16,
      iconHeight: 18,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = ScreenAdapter.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Our Service'),
        SizedBox(height: screen.h(10)),
        Container(
          width: double.infinity,
          padding: screen.edgeInsetsAll(9),
          decoration: BoxDecoration(
            color: AppColors.profileServicePanel,
            borderRadius: screen.borderRadiusAll(20),
            border: Border.all(color: AppColors.profileServiceBorder),
          ),
          child: Column(
            children: [
              for (var index = 0; index < _items.length; index++) ...[
                _ServiceListItem(data: _items[index]),
                if (index != _items.length - 1) SizedBox(height: screen.h(10)),
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
    final screen = ScreenAdapter.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: screen.borderRadiusAll(20),
        onTap: () {},
        child: Ink(
          height: screen.h(42),
          padding: screen.edgeInsetsFromLTRB(27, 12, 23, 11),
          decoration: BoxDecoration(
            color: AppColors.tabBackground,
            borderRadius: screen.borderRadiusAll(20),
          ),
          child: Row(
            children: [
              SizedBox(
                width: screen.w(21),
                child: Center(
                  child: Image.asset(
                    data.asset,
                    width: screen.w(data.iconWidth),
                    height: screen.h(data.iconHeight),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: screen.w(30)),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.profileServiceText,
                    fontSize: screen.sp(16),
                    fontWeight: FontWeight.w400,
                    height: 19 / 16,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.profileArrowTint,
                size: screen.r(28),
              ),
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
  });

  final String title;
  final String asset;
  final double iconWidth;
  final double iconHeight;
}
