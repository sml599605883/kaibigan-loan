import 'package:flutter/material.dart';

import '../../../assets/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.onApply,
    this.amountRange = '₱ 60,000',
    this.termInfo = '91-180 Days',
    this.loanRate = '≤ 0.05% / Day',
    this.buttonText = 'Apply Now',
  });

  final VoidCallback onApply;
  final String amountRange;
  final String termInfo;
  final String loanRate;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Apply Now',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onApply,
        child: Container(
          key: const ValueKey('home_loan_card'),
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.homeLoanCardBackground),
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 119.w),
            child: Column(
              children: [
                _AmountPanel(amountRange: amountRange),
                SizedBox(height: 21.w),
                _LoanFacts(termInfo: termInfo, loanRate: loanRate),
                SizedBox(height: 19.w),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60.w),
                  child: _ApplyButton(onTap: onApply, buttonText: buttonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({required this.amountRange});

  final String amountRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82.h,
      decoration: BoxDecoration(
        color: AppColors.homeCardPanel,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Available up to',
            style: TextStyle(
              color: AppColors.ordersTitleText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
          ),
          SizedBox(
            height: 48.h,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amountRange.isEmpty ? '₱ 60,000' : amountRange,
                style: TextStyle(
                  color: AppColors.ordersTitleText,
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanFacts extends StatelessWidget {
  const _LoanFacts({required this.termInfo, required this.loanRate});

  final String termInfo;
  final String loanRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 29.w),
        Expanded(
          child: _LoanFactPill(
            icon: Icons.calendar_month_rounded,
            title: termInfo.isEmpty ? '91-180 Days' : termInfo,
            subtitle: 'Loan Term',
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _LoanFactPill(
            icon: Icons.percent_rounded,
            title: loanRate.isEmpty ? '≤ 0.05% / Day' : loanRate,
            subtitle: 'Low Interest',
          ),
        ),
        SizedBox(width: 29.w),
      ],
    );
  }
}

class _LoanFactPill extends StatelessWidget {
  const _LoanFactPill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 41,
      decoration: BoxDecoration(
        color: AppColors.homeCardPanel,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.homeCardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Center(
              child: Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  color: AppColors.appBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.tabBackground, size: 17),
              ),
            ),
          ),
          Container(width: 1, height: 41, color: AppColors.homeCardBorder),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ordersTitleText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ordersMutedText,
                    fontSize: 10,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.onTap, required this.buttonText});

  final VoidCallback onTap;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.ordersYellow, AppColors.ordersYellowEnd],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.tabShadow,
              blurRadius: 2,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(
            child: Text(
              buttonText.isEmpty ? 'Apply Now' : buttonText,
              style: const TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
