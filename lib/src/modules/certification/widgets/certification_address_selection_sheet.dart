import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../assets/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../models/address_node.dart';
import '../models/address_option.dart';
import '../models/address_selection.dart';

Future<AddressSelection?> showCertificationAddressSelectionSheet({
  required BuildContext context,
  required List<AddressOption> options,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) {
    return null;
  }
  return showModalBottomSheet<AddressSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.addressSheetBarrier,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => CertificationAddressSelectionSheet(options: options),
  );
}

class CertificationAddressSelectionSheet extends StatefulWidget {
  const CertificationAddressSelectionSheet({
    super.key,
    required this.options,
    this.onSelected,
  });

  final List<AddressOption> options;
  final ValueChanged<AddressSelection>? onSelected;

  @override
  State<CertificationAddressSelectionSheet> createState() =>
      _CertificationAddressSelectionSheetState();
}

enum _AddressLevel { region, province, municipality }

class _CertificationAddressSelectionSheetState
    extends State<CertificationAddressSelectionSheet> {
  int _selectedRegionIndex = 0;
  int _selectedProvinceIndex = 0;
  int _selectedMunicipalityIndex = 0;
  _AddressLevel _activeLevel = _AddressLevel.region;
  _AddressLevel _maxReachedLevel = _AddressLevel.region;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 13.h),
      child: SizedBox(
        key: const Key('certificationAddressSheet'),
        width: 345.w,
        height: 393.h,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -4.w,
                top: -6.h,
                child: Image.asset(
                  AppAssets.certificationAddressSheetBackground,
                  width: 353.w,
                  height: 401.h,
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 25.h, 0, 15.h),
                child: Column(
                  children: [
                    _buildSegments(),
                    SizedBox(height: 21.h),
                    SizedBox(height: 242.h, child: _buildOptionList()),
                    SizedBox(height: 14.h),
                    _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegments() {
    return SizedBox(
      width: 299.w,
      height: 30.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: _AddressSegment(
              itemKey: const Key('addressSegmentRegion'),
              title: _segmentTitle(_AddressLevel.region),
              active: _activeLevel == _AddressLevel.region,
              enabled: _canTapLevel(_AddressLevel.region),
              leftPadding: 5.w,
              rightPadding: 5.w,
              onTap: () => _handleSegmentTap(_AddressLevel.region),
            ),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: _AddressSegment(
              itemKey: const Key('addressSegmentProvince'),
              title: _segmentTitle(_AddressLevel.province),
              active: _activeLevel == _AddressLevel.province,
              enabled: _canTapLevel(_AddressLevel.province),
              leftPadding: 5.w,
              rightPadding: 5.w,
              onTap: () => _handleSegmentTap(_AddressLevel.province),
            ),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: _AddressSegment(
              itemKey: const Key('addressSegmentMunicipality'),
              title: _segmentTitle(_AddressLevel.municipality),
              active: _activeLevel == _AddressLevel.municipality,
              enabled: _canTapLevel(_AddressLevel.municipality),
              leftPadding: 5.w,
              rightPadding: 5.w,
              onTap: () => _handleSegmentTap(_AddressLevel.municipality),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionList() {
    final options = _activeOptions;
    final selectedIndex = _activeSelectedIndex;
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemExtent: 60.h,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final selected = index == selectedIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleLevelTap(index),
          child: Center(
            child: Container(
              key: Key('addressOption_${option.addressId}'),
              width: double.infinity,
              height: selected ? 46.h : 60.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.addressSheetSelectedRow : null,
              ),
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.addressSheetText,
                  fontSize: 16.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  height: 20 / 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 15.w),
      child: SizedBox(
        key: const Key('addressActionButtons'),
        height: 46.h,
        child: Row(
          children: [
            Expanded(
              child: _AddressActionButton(
                label: 'Cancel',
                backgroundColor: AppColors.addressSheetCancelBackground,
                textColor: AppColors.addressSheetCancelText,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: _AddressActionButton(
                label: 'Done',
                backgroundColor: AppColors.addressSheetDoneBackground,
                textColor: AppColors.addressSheetDoneText,
                onTap: _handleDoneTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AddressNode> get _activeOptions {
    final region = widget.options[_selectedRegionIndex];
    final provinces = region.children;
    final province = provinces.isEmpty
        ? null
        : provinces[_selectedProvinceIndex];
    return switch (_activeLevel) {
      _AddressLevel.region => widget.options,
      _AddressLevel.province => provinces,
      _AddressLevel.municipality => province?.children ?? const <AddressNode>[],
    };
  }

  int get _activeSelectedIndex => switch (_activeLevel) {
    _AddressLevel.region => _selectedRegionIndex,
    _AddressLevel.province => _selectedProvinceIndex,
    _AddressLevel.municipality => _selectedMunicipalityIndex,
  };

  void _handleLevelTap(int index) {
    switch (_activeLevel) {
      case _AddressLevel.region:
        setState(() {
          _selectedRegionIndex = index;
          _selectedProvinceIndex = 0;
          _selectedMunicipalityIndex = 0;
        });
      case _AddressLevel.province:
        setState(() {
          _selectedProvinceIndex = index;
          _selectedMunicipalityIndex = 0;
        });
      case _AddressLevel.municipality:
        setState(() => _selectedMunicipalityIndex = index);
    }
  }

  void _handleDoneTap() {
    switch (_activeLevel) {
      case _AddressLevel.region:
        setState(() {
          _activeLevel = _AddressLevel.province;
          _maxReachedLevel = _AddressLevel.province;
        });
      case _AddressLevel.province:
        final region = widget.options[_selectedRegionIndex];
        final provinces = region.children;
        if (provinces.isEmpty ||
            provinces[math.min(_selectedProvinceIndex, provinces.length - 1)]
                .children
                .isEmpty) {
          _finish();
          return;
        }
        setState(() {
          _activeLevel = _AddressLevel.municipality;
          _maxReachedLevel = _AddressLevel.municipality;
        });
      case _AddressLevel.municipality:
        _finish();
    }
  }

  void _finish() {
    final selection = _buildSelection();
    widget.onSelected?.call(selection);
    Navigator.of(context).pop(selection);
  }

  void _handleSegmentTap(_AddressLevel level) {
    if (!_canTapLevel(level)) {
      return;
    }
    setState(() {
      switch (level) {
        case _AddressLevel.region:
          _selectedProvinceIndex = 0;
          _selectedMunicipalityIndex = 0;
          _activeLevel = _AddressLevel.region;
          _maxReachedLevel = _AddressLevel.region;
        case _AddressLevel.province:
          _selectedMunicipalityIndex = 0;
          _activeLevel = _AddressLevel.province;
          _maxReachedLevel = _AddressLevel.province;
        case _AddressLevel.municipality:
          _activeLevel = _AddressLevel.municipality;
      }
    });
  }

  bool _canTapLevel(_AddressLevel level) {
    return level.index <= _maxReachedLevel.index;
  }

  String _segmentTitle(_AddressLevel level) {
    final region = widget.options[_selectedRegionIndex];
    switch (level) {
      case _AddressLevel.region:
        return _maxReachedLevel == _AddressLevel.region
            ? 'Region'
            : region.label;
      case _AddressLevel.province:
        if (_maxReachedLevel == _AddressLevel.region) {
          return 'Province';
        }
        final provinces = region.children;
        if (provinces.isEmpty) {
          return 'Province';
        }
        return provinces[math.min(_selectedProvinceIndex, provinces.length - 1)]
            .label;
      case _AddressLevel.municipality:
        if (_maxReachedLevel != _AddressLevel.municipality) {
          return 'Municipality';
        }
        final provinces = region.children;
        if (provinces.isEmpty) {
          return 'Municipality';
        }
        final municipalities =
            provinces[math.min(_selectedProvinceIndex, provinces.length - 1)]
                .children;
        if (municipalities.isEmpty) {
          return 'Municipality';
        }
        return municipalities[math.min(
              _selectedMunicipalityIndex,
              municipalities.length - 1,
            )]
            .label;
    }
  }

  AddressSelection _buildSelection() {
    final region = widget.options[_selectedRegionIndex];
    final provinces = region.children;
    if (provinces.isEmpty) {
      return AddressSelection(label: region.label, value: region.label);
    }
    final province =
        provinces[math.min(_selectedProvinceIndex, provinces.length - 1)];
    final municipalities = province.children;
    if (municipalities.isEmpty) {
      final value = '${region.label}-${province.label}';
      return AddressSelection(label: value, value: value);
    }
    final municipality =
        municipalities[math.min(
          _selectedMunicipalityIndex,
          municipalities.length - 1,
        )];
    final value = '${region.label}-${province.label}-${municipality.label}';
    return AddressSelection(label: value, value: value);
  }
}

class _AddressSegment extends StatelessWidget {
  const _AddressSegment({
    required this.itemKey,
    required this.title,
    required this.active,
    required this.enabled,
    required this.leftPadding,
    required this.rightPadding,
    required this.onTap,
  });

  final Key itemKey;
  final String title;
  final bool active;
  final bool enabled;
  final double leftPadding;
  final double rightPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        key: itemKey,
        alignment: Alignment.center,
        padding: EdgeInsets.only(left: leftPadding.w, right: rightPadding.w),
        decoration: BoxDecoration(
          color: active
              ? AppColors.addressSheetSegmentActive
              : AppColors.addressSheetSegmentInactive,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active
                ? AppColors.addressSheetSegmentActiveText
                : AppColors.addressSheetSegmentInactiveText,
            fontSize: 12.sp,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            height: 18 / 12,
          ),
        ),
      ),
    );
  }
}

class _AddressActionButton extends StatelessWidget {
  const _AddressActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              height: 22 / 18,
            ),
          ),
        ),
      ),
    );
  }
}
