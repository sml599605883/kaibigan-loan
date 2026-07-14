import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../models/salary_day_option.dart';

Future<SalaryDaySelection?> showCertificationSalaryDaySelectionSheet({
  required BuildContext context,
  required List<SalaryDayGroup> options,
  SalaryDaySelection? initialSelection,
}) async {
  if (options.isEmpty) {
    return null;
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) {
    return null;
  }
  return showModalBottomSheet<SalaryDaySelection>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.uploadMethodBarrier,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => CertificationSalaryDaySelectionSheet(
      options: options,
      initialSelection: initialSelection,
    ),
  );
}

class CertificationSalaryDaySelectionSheet extends StatefulWidget {
  const CertificationSalaryDaySelectionSheet({
    super.key,
    required this.options,
    this.initialSelection,
  });

  final List<SalaryDayGroup> options;
  final SalaryDaySelection? initialSelection;

  @override
  State<CertificationSalaryDaySelectionSheet> createState() =>
      _CertificationSalaryDaySelectionSheetState();
}

enum _SalaryDayLevel { group, child }

class _CertificationSalaryDaySelectionSheetState
    extends State<CertificationSalaryDaySelectionSheet> {
  static const _maximumVisibleOptions = 5;
  static const _optionHeight = 46.0;
  static const _optionSpacing = 15.0;

  late int _selectedGroupIndex = _initialGroupIndex();
  late int _selectedChildIndex = _initialChildIndex();
  _SalaryDayLevel _activeLevel = _SalaryDayLevel.group;

  int _initialGroupIndex() {
    final groupValue = widget.initialSelection?.groupValue ?? '';
    final index = widget.options.indexWhere(
      (group) => group.value == groupValue,
    );
    return index < 0 ? 0 : index;
  }

  int _initialChildIndex() {
    final submitValue = widget.initialSelection?.submitValue ?? '';
    final children = widget.options[_selectedGroupIndex].children;
    final index = children.indexWhere((child) => child.value == submitValue);
    return index < 0 ? 0 : index;
  }

  List<Object> get _activeOptions => _activeLevel == _SalaryDayLevel.group
      ? widget.options
      : widget.options[_selectedGroupIndex].children;

  int get _selectedIndex => _activeLevel == _SalaryDayLevel.group
      ? _selectedGroupIndex
      : _selectedChildIndex;

  void _select(int index) {
    setState(() {
      if (_activeLevel == _SalaryDayLevel.group) {
        _selectedGroupIndex = index;
        _selectedChildIndex = 0;
      } else {
        _selectedChildIndex = index;
      }
    });
  }

  void _handleCancel() {
    if (_activeLevel == _SalaryDayLevel.child) {
      setState(() => _activeLevel = _SalaryDayLevel.group);
      return;
    }
    Navigator.of(context).pop();
  }

  void _handleDone() {
    if (_activeLevel == _SalaryDayLevel.group) {
      setState(() => _activeLevel = _SalaryDayLevel.child);
      return;
    }
    final group = widget.options[_selectedGroupIndex];
    final child = group.children[_selectedChildIndex];
    Navigator.of(context).pop(
      SalaryDaySelection(
        groupValue: group.value,
        submitValue: child.value,
        displayText: '${group.label}|${child.label}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = _activeOptions;
    final visibleCount = options.length.clamp(0, _maximumVisibleOptions);
    final listHeight = visibleCount == 0
        ? 0.0
        : visibleCount * _optionHeight.h +
              (visibleCount - 1) * _optionSpacing.h;
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 13.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.uploadMethodSheetBackground,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 30.h, bottom: 15.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                key: const Key('salaryDayOptionList'),
                height: listHeight,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: options.length > _maximumVisibleOptions
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final label = option is SalaryDayGroup
                        ? option.label
                        : (option as SalaryDayOption).label;
                    return GestureDetector(
                      key: Key('salaryDayOption_$index'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _select(index),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: index == _selectedIndex
                              ? AppColors.uploadMethodSelected
                              : null,
                        ),
                        child: SizedBox(
                          height: _optionHeight.h,
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.uploadMethodText,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                height: 25 / 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, _) =>
                      SizedBox(height: _optionSpacing.h),
                ),
              ),
              SizedBox(height: 29.h),
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 15.w),
                child: SizedBox(
                  height: 46.h,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SalaryDayActionButton(
                          label: 'Cancel',
                          backgroundColor:
                              AppColors.uploadMethodCancelBackground,
                          textColor: AppColors.uploadMethodCancelText,
                          onTap: _handleCancel,
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: _SalaryDayActionButton(
                          label: 'Done',
                          backgroundColor: AppColors.uploadMethodDoneBackground,
                          textColor: AppColors.uploadMethodDoneText,
                          onTap: _handleDone,
                        ),
                      ),
                    ],
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

class _SalaryDayActionButton extends StatelessWidget {
  const _SalaryDayActionButton({
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
