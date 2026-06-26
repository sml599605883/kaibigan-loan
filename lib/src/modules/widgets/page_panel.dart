import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';

class PagePanel extends StatelessWidget {
  const PagePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tabBackground,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(asset, width: 56, height: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Image.asset(AppAssets.arrowRight, width: 16, height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
