import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../../utils/screen_adapter.dart';

class SettingPopupBackground extends StatelessWidget {
  const SettingPopupBackground({super.key, required this.child});

  static const backgroundKey = Key('settingPopupBackground');
  static const _designWidth = 320.0;
  static const _designHeight = 372.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = math.min(_designWidth.w, screenSize.width - 32.w);
    return Center(
      child: Transform.translate(
        offset: Offset(0, -56.h),
        child: SizedBox(
          width: width,
          height: width * (_designHeight / _designWidth),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  AppAssets.settingPopupBackground,
                  key: backgroundKey,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned.fill(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
