import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../assets/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../../widgets/section_title.dart';
import '../main_controller.dart';

class LoanProcessSection extends StatelessWidget {
  const LoanProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Loan Process'),
        const SizedBox(height: 10),
        Obx(() {
          final items = controller.loanProcessItems.toList(growable: false);
          if (items.isEmpty) {
            return Image.asset(AppAssets.homeProcessPanel, fit: BoxFit.fill);
          }
          return _LoanProcessPanel(items: items);
        }),
      ],
    );
  }
}

class _LoanProcessPanel extends StatelessWidget {
  const _LoanProcessPanel({required this.items});

  final List<HomeLoanProcessItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home_loan_process_list'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(7.w, 19.h, 7.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.homeProcessPanel,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.homeProcessBorder),
      ),
      child: Column(
        children: [
          _LoanProcessProgress(items: items),
          SizedBox(height: 7.h),
          _LoanProcessLabels(items: items),
          SizedBox(height: 6.h),
          _LoanProcessAmounts(items: items),
          SizedBox(height: 17.h),
          Image.asset(
            AppAssets.complianceLogos,
            height: 32.h,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }
}

class _LoanProcessProgress extends StatelessWidget {
  const _LoanProcessProgress({required this.items});

  final List<HomeLoanProcessItem> items;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(items);
    return SizedBox(
      height: 16.h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackInset = 3.w;
          final markerSize = 16.w;
          final markerCenter =
              constraints.maxWidth * ((selectedIndex + 0.5) / items.length);
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: trackInset,
                right: trackInset,
                child: Container(
                  height: 7.h,
                  decoration: BoxDecoration(
                    color: AppColors.homeProcessTrack,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Positioned(
                left: trackInset,
                width: markerCenter - trackInset,
                child: Container(
                  height: 7.h,
                  decoration: BoxDecoration(
                    color: AppColors.ordersYellow,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('home_loan_process_progress_marker'),
                left: markerCenter - markerSize / 2,
                width: markerSize,
                height: markerSize,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.homeProcessDot,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: const BoxDecoration(
                        color: AppColors.homeProcessPanel,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoanProcessLabels extends StatelessWidget {
  const _LoanProcessLabels({required this.items});

  final List<HomeLoanProcessItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.selected
                      ? AppColors.ordersTitleText
                      : AppColors.homeProcessInactiveText,
                  fontSize: 8.sp,
                  height: 1.25,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LoanProcessAmounts extends StatelessWidget {
  const _LoanProcessAmounts({required this.items});

  final List<HomeLoanProcessItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Container(
              key: ValueKey('home_loan_process_amount_$index'),
              height: 36.h,
              decoration: BoxDecoration(
                color: item.selected
                    ? AppColors.ordersYellow
                    : AppColors.homeProcessTrack,
                borderRadius: BorderRadius.circular(4.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.amount,
                      maxLines: 1,
                      style: TextStyle(
                        color: item.selected
                            ? AppColors.ordersTitleText
                            : AppColors.tabBackground,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Loan amount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.selected
                          ? AppColors.homeProcessAmountMuted
                          : AppColors.tabBackground,
                      fontSize: 8.sp,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

int _selectedIndex(List<HomeLoanProcessItem> items) {
  final selectedIndex = items.lastIndexWhere((item) => item.selected);
  return selectedIndex < 0 ? 0 : selectedIndex;
}
