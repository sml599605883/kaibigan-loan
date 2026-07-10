import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../app_routes.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/report/risk_report_scene.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';

enum _IdentityTypeTab { recommended, other }

class CertificationIdentityPage extends StatefulWidget {
  const CertificationIdentityPage({super.key});

  @override
  State<CertificationIdentityPage> createState() =>
      _CertificationIdentityPageState();
}

class _CertificationIdentityPageState extends State<CertificationIdentityPage> {
  _IdentityTypeTab _selectedTab = _IdentityTypeTab.recommended;
  bool _isLoading = true;
  List<String> _recommendedTypes = <String>[];
  List<String> _otherTypes = <String>[];
  late final int _scene2StartTimeSeconds;

  @override
  void initState() {
    super.initState();
    _scene2StartTimeSeconds = RiskReportScene.nowSeconds();
    _loadIdentityInfo();
  }

  Future<void> _loadIdentityInfo() async {
    final productId = _productIdFromArguments();
    if (productId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiClient.instance.basicPersonInfo(
        geobotanists: productId,
      );
      final groupedTypes = response.states['postepileptic'].listValue;
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendedTypes = _parseTypeGroup(
          groupedTypes.isEmpty ? Json(null) : groupedTypes.first,
        );
        _otherTypes = groupedTypes
            .skip(1)
            .expand(_parseTypeGroup)
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendedTypes = <String>[];
        _otherTypes = <String>[];
        _isLoading = false;
      });
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
  }

  String _productIdFromArguments() {
    final arguments = Get.arguments;
    if (arguments is String) {
      return arguments.trim();
    }
    if (arguments is Map) {
      return Json(arguments)['geobotanists'].stringValue.trim();
    }
    return '';
  }

  List<String> _parseTypeGroup(Json group) {
    final seen = <String>{};
    return group.listValue
        .map((item) => item.stringValue.trim())
        .where((value) => value.isNotEmpty && seen.add(value))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.certificationPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _IdentityHeader(onBack: NavigationHelper.back),
            SizedBox(height: 15.h),
            _IdentityTabs(
              selectedTab: _selectedTab,
              onChanged: (tab) {
                setState(() {
                  _selectedTab = tab;
                });
              },
            ),
            SizedBox(height: 15.h),
            Expanded(
              child: _IdentityTypeContent(
                isLoading: _isLoading,
                productId: _productIdFromArguments(),
                scene2StartTimeSeconds: _scene2StartTimeSeconds,
                types: _selectedTab == _IdentityTypeTab.recommended
                    ? _recommendedTypes
                    : _otherTypes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 20.w),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: Image.asset(
                  AppAssets.loginBack,
                  width: 23.w,
                  height: 20.h,
                ),
              ),
            ),
          ),
          Text(
            'Identity verification',
            style: TextStyle(
              color: AppColors.certificationTitleText,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              height: 24 / 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityTabs extends StatelessWidget {
  const _IdentityTabs({required this.selectedTab, required this.onChanged});

  final _IdentityTypeTab selectedTab;
  final ValueChanged<_IdentityTypeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _IdentityTabButton(
              label: 'Recommended ID Type',
              isSelected: selectedTab == _IdentityTypeTab.recommended,
              onTap: () => onChanged(_IdentityTypeTab.recommended),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: _IdentityTabButton(
              label: 'Other Options',
              isSelected: selectedTab == _IdentityTypeTab.other,
              onTap: () => onChanged(_IdentityTypeTab.other),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityTabButton extends StatelessWidget {
  const _IdentityTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.certificationTabActive
          : AppColors.certificationTabInactive,
      borderRadius: BorderRadius.circular(5.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(5.r),
        onTap: onTap,
        child: SizedBox(
          height: 30.h,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? AppColors.certificationTabActiveText
                    : AppColors.certificationTabInactiveText,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityTypeContent extends StatelessWidget {
  const _IdentityTypeContent({
    required this.isLoading,
    required this.productId,
    required this.scene2StartTimeSeconds,
    required this.types,
  });

  final bool isLoading;
  final String productId;
  final int scene2StartTimeSeconds;
  final List<String> types;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.certificationTabActive,
        ),
      );
    }

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.certificationPanelBackground,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: types.isEmpty
              ? SizedBox(
                  height: 60.h,
                  child: Center(
                    child: Text(
                      'No ID types available',
                      style: TextStyle(
                        color: AppColors.certificationEmptyText,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < types.length; index++) ...[
                      _IdentityTypeRow(
                        productId: productId,
                        type: types[index],
                        scene2StartTimeSeconds: scene2StartTimeSeconds,
                      ),
                      if (index != types.length - 1) SizedBox(height: 10.h),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _IdentityTypeRow extends StatelessWidget {
  const _IdentityTypeRow({
    required this.productId,
    required this.type,
    required this.scene2StartTimeSeconds,
  });

  final String productId;
  final String type;
  final int scene2StartTimeSeconds;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.certificationCardBackground,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: () {
          RiskReportScene.report(
            productId: productId,
            sceneType: '2',
            startTimeSeconds: scene2StartTimeSeconds,
          );
          Get.toNamed<void>(
            AppRoutes.certificationUpload,
            arguments: {
              'geobotanists': productId,
              'cardType': type,
              'scene3StartTimeSeconds': RiskReportScene.nowSeconds(),
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Image.asset(AppAssets.idTypeDot, width: 11.w, height: 11.h),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.certificationTitleText,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    height: 19 / 16,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Image.asset(AppAssets.arrowRight, width: 16.w, height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}
