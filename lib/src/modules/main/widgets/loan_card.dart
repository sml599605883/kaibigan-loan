import 'package:flutter/material.dart';

import '../../../assets/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../main_controller.dart';

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.onApply,
    this.productName = '',
    this.productLogo = '',
    this.amountRange = '₱ 60,000',
    this.amountRangeDescription = '',
    this.termInfo = '91-180 Days',
    this.termInfoDescription = '',
    this.loanRate = '≤ 0.05% / Day',
    this.loanRateDescription = '',
    this.loanTermOptions = const <HomeLoanTermOption>[],
    this.buttonText = 'Apply Now',
  });

  final VoidCallback onApply;
  final String productName;
  final String productLogo;
  final String amountRange;
  final String amountRangeDescription;
  final String termInfo;
  final String termInfoDescription;
  final String loanRate;
  final String loanRateDescription;
  final List<HomeLoanTermOption> loanTermOptions;
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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 119.w),
                child: Column(
                  children: [
                    _AmountPanel(
                      amountRange: amountRange,
                      description: amountRangeDescription,
                    ),
                    SizedBox(height: 21.w),
                    if (loanTermOptions.isNotEmpty)
                      _LoanTermOptions(options: loanTermOptions)
                    else
                      _LoanFacts(
                        termInfo: termInfo,
                        termInfoDescription: termInfoDescription,
                        loanRate: loanRate,
                        loanRateDescription: loanRateDescription,
                      ),
                    SizedBox(height: 19.w),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 60.w),
                      child: _ApplyButton(
                        onTap: onApply,
                        buttonText: buttonText,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 35.w,
                top: 53.w,
                child: _ProductIdentity(
                  productName: productName,
                  productLogo: productLogo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductIdentity extends StatelessWidget {
  const _ProductIdentity({
    required this.productName,
    required this.productLogo,
  });

  final String productName;
  final String productLogo;

  @override
  Widget build(BuildContext context) {
    final name = productName.trim();
    final logo = productLogo.trim();
    if (name.isEmpty && logo.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 200.w,
      height: 23.w,
      child: Row(
        children: [
          if (logo.isNotEmpty) ...[
            ClipOval(
              key: const ValueKey('home_loan_product_logo'),
              child: Image.network(
                logo,
                width: 23.w,
                height: 23.w,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            SizedBox(width: 7.w),
          ],
          if (name.isNotEmpty)
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ordersTitleText,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  height: 19 / 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({required this.amountRange, required this.description});

  final String amountRange;
  final String description;

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
            description,
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
  const _LoanFacts({
    required this.termInfo,
    required this.termInfoDescription,
    required this.loanRate,
    required this.loanRateDescription,
  });

  final String termInfo;
  final String termInfoDescription;
  final String loanRate;
  final String loanRateDescription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 29.w),
        Expanded(
          child: _LoanFactPill(
            icon: Icons.calendar_month_rounded,
            title: termInfo.isEmpty ? '91-180 Days' : termInfo,
            subtitle: termInfoDescription,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _LoanFactPill(
            icon: Icons.percent_rounded,
            title: loanRate.isEmpty ? '≤ 0.05% / Day' : loanRate,
            subtitle: loanRateDescription,
          ),
        ),
        SizedBox(width: 29.w),
      ],
    );
  }
}

class _LoanTermOptions extends StatelessWidget {
  const _LoanTermOptions({required this.options});

  final List<HomeLoanTermOption> options;

  @override
  Widget build(BuildContext context) {
    if (options.length == 1) {
      return SizedBox(
        key: const ValueKey('home_loan_term_options'),
        width: double.infinity,
        child: Center(
          child: SizedBox(
            width: 136.w,
            child: _LoanTermOptionPill(
              key: const ValueKey('home_loan_term_option_0'),
              option: options.first,
            ),
          ),
        ),
      );
    }
    return Row(
      key: const ValueKey('home_loan_term_options'),
      children: [
        SizedBox(width: 29.w),
        Expanded(
          child: _LoanTermOptionPill(
            key: const ValueKey('home_loan_term_option_0'),
            option: options.first,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _LoanTermOptionPill(
            key: const ValueKey('home_loan_term_option_1'),
            option: options.last,
          ),
        ),
        SizedBox(width: 29.w),
      ],
    );
  }
}

class _LoanTermOptionPill extends StatelessWidget {
  const _LoanTermOptionPill({super.key, required this.option});

  final HomeLoanTermOption option;

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
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.appBackground,
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option.value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.tabBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 24 / 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 41, color: AppColors.homeCardBorder),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ordersTitleText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 17 / 14,
              ),
            ),
          ),
          const SizedBox(width: 7),
        ],
      ),
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
