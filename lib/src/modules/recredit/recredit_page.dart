import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';
import 'recredit_polling_coordinator.dart';

class RecreditPage extends StatefulWidget {
  const RecreditPage({
    super.key,
    this.progressDelayGenerator,
    this.progressIncrementGenerator,
    this.onStartRecredit,
  });

  final Duration Function()? progressDelayGenerator;
  final int Function(int currentProgress)? progressIncrementGenerator;
  final void Function(String productId)? onStartRecredit;

  @override
  State<RecreditPage> createState() => _RecreditPageState();
}

class _RecreditPageState extends State<RecreditPage> {
  static final Random _random = Random();

  Timer? _progressTimer;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _scheduleProgressUpdate();
    _startRecreditIfPossible();
  }

  void _startRecreditIfPossible() {
    final productId = _extractProductId(Get.arguments);
    if (productId.isEmpty) {
      return;
    }
    final callback = widget.onStartRecredit;
    if (callback != null) {
      callback(productId);
      return;
    }
    final coordinator = Get.isRegistered<RecreditPollingCoordinator>()
        ? Get.find<RecreditPollingCoordinator>()
        : Get.put(RecreditPollingCoordinator(), permanent: true);
    coordinator.start(productId);
  }

  String _extractProductId(Object? arguments) {
    if (arguments is! Map) {
      return '';
    }
    final payload = arguments['payload'];
    final payloadMap = payload is Map ? payload : null;
    for (final key in const ['geobotanists', 'productId', 'cohabiter']) {
      for (final source in [arguments, payloadMap]) {
        final value = source?[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return '';
  }

  void _scheduleProgressUpdate() {
    if (_progress >= 99) {
      return;
    }
    final delay =
        widget.progressDelayGenerator?.call() ??
        Duration(seconds: _random.nextInt(3) + 1);
    _progressTimer = Timer(delay, _advanceProgress);
  }

  void _advanceProgress() {
    if (!mounted) {
      return;
    }
    final increment =
        widget.progressIncrementGenerator?.call(_progress) ??
        _random.nextInt(11) + 5;
    setState(() {
      _progress = (_progress + increment).clamp(0, 99);
    });
    _scheduleProgressUpdate();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    ScreenAdapter.init(context);
    final returnHeight = max(44.0, 44.h);
    final illustrationSpacer = max(16.h, 204.h - topInset - 8.h - returnHeight);
    return Scaffold(
      backgroundColor: AppColors.recreditPageBackground,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8.w, top: 8.h),
                        child: Semantics(
                          button: true,
                          label: 'Back',
                          excludeSemantics: true,
                          onTap: NavigationHelper.back,
                          child: GestureDetector(
                            key: const Key('recredit_return_button'),
                            behavior: HitTestBehavior.opaque,
                            onTap: NavigationHelper.back,
                            child: SizedBox(
                              width: max(44.0, 44.w),
                              height: returnHeight,
                              child: Center(
                                child: Image.asset(
                                  AppAssets.loginBack,
                                  width: 23.w,
                                  height: 20.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: illustrationSpacer),
                    Image.asset(
                      AppAssets.recreditIllustration,
                      key: const Key('recredit_illustration'),
                      width: 192.w,
                      height: 154.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 18.h),
                    _EstimateText(),
                    Text(
                      'Please wait patiently',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.recreditText,
                        fontFamily: 'Helvetica',
                        fontSize: 12.sp,
                        height: 18 / 12,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _ProgressIndicator(progress: _progress),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EstimateText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final regularStyle = TextStyle(
      color: AppColors.recreditText,
      fontFamily: 'Helvetica',
      fontSize: 12.sp,
      height: 18 / 12,
      letterSpacing: 0,
    );
    return RichText(
      maxLines: 1,
      textAlign: TextAlign.center,
      text: TextSpan(
        style: regularStyle,
        children: [
          const TextSpan(text: 'Calculating your credit limit, just '),
          TextSpan(
            text: '30 seconds',
            style: regularStyle.copyWith(
              color: AppColors.recreditEstimateHighlight,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32.w;
        final width = min(308.w, max(0.0, availableWidth));
        final markerSize = min(16.w, width);
        final markerLeft = max(
          0.0,
          (width - markerSize) * progress / 99,
        ).clamp(0.0, max(0.0, width - markerSize)).toDouble();
        final labelWidth = min(44.w, width);
        final labelLeft = (markerLeft + markerSize / 2 - labelWidth / 2)
            .clamp(0.0, max(0.0, width - labelWidth))
            .toDouble();
        return SizedBox(
          key: const Key('recredit_progress_section'),
          width: width,
          height: 51.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 4.5.h,
                left: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: Container(
                    key: const Key('recredit_progress_bar'),
                    width: width,
                    height: 7.h,
                    color: AppColors.recreditProgressTrack,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress / 100,
                      child: SizedBox.expand(
                        child: ColoredBox(
                          color: AppColors.recreditProgressValue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markerLeft,
                top: 0,
                child: Image.asset(
                  AppAssets.recreditProgressMarker,
                  key: const Key('recredit_status_icon'),
                  width: markerSize,
                  height: markerSize,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: labelLeft,
                top: 24.h,
                child: Container(
                  key: const Key('recredit_progress_label_container'),
                  width: labelWidth,
                  height: 24.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.recreditProgressLabel,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$progress%',
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.recreditText,
                      fontFamily: 'Helvetica',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      height: 18 / 12,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
