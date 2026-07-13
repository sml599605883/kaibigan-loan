import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';

class CertificationSelectionSheetOption<T> {
  const CertificationSelectionSheetOption({
    required this.value,
    required this.label,
    this.iconAsset,
    this.key,
  });

  final T value;
  final String label;
  final String? iconAsset;
  final Key? key;
}

Future<T?> showCertificationSelectionSheet<T>({
  required BuildContext context,
  required List<CertificationSelectionSheetOption<T>> options,
  T? initialValue,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) {
    return null;
  }
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.uploadMethodBarrier,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => CertificationSelectionSheet<T>(
      options: options,
      initialValue: initialValue,
    ),
  );
}

class CertificationSelectionSheet<T> extends StatefulWidget {
  const CertificationSelectionSheet({
    super.key,
    required this.options,
    this.initialValue,
  });

  final List<CertificationSelectionSheetOption<T>> options;
  final T? initialValue;

  @override
  State<CertificationSelectionSheet<T>> createState() =>
      _CertificationSelectionSheetState<T>();
}

class _CertificationSelectionSheetState<T>
    extends State<CertificationSelectionSheet<T>> {
  static const _maximumVisibleOptions = 5;
  static const _optionHeight = 46.0;
  static const _optionSpacing = 15.0;

  final ScrollController _scrollController = ScrollController();
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    final initialIndex = widget.options.indexWhere(
      (option) => option.value == widget.initialValue,
    );
    if (initialIndex >= _maximumVisibleOptions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        final requestedOffset =
            (initialIndex * (_optionHeight + _optionSpacing)).h;
        _scrollController.jumpTo(
          requestedOffset
              .clamp(0.0, _scrollController.position.maxScrollExtent)
              .toDouble(),
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _buildOptionList(),
              SizedBox(height: 29.h),
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 15.w),
                child: SizedBox(
                  height: 46.h,
                  child: Row(
                    children: [
                      Expanded(
                        child: _CertificationSelectionActionButton(
                          label: 'Cancel',
                          backgroundColor:
                              AppColors.uploadMethodCancelBackground,
                          textColor: AppColors.uploadMethodCancelText,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: _CertificationSelectionActionButton(
                          label: 'Done',
                          backgroundColor: AppColors.uploadMethodDoneBackground,
                          textColor: AppColors.uploadMethodDoneText,
                          onTap: () =>
                              Navigator.of(context).pop(_selectedValue),
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

  Widget _buildOptionList() {
    final visibleOptionCount = widget.options.length.clamp(
      0,
      _maximumVisibleOptions,
    );
    final listHeight = visibleOptionCount == 0
        ? 0.0
        : visibleOptionCount * _optionHeight.h +
              (visibleOptionCount - 1) * _optionSpacing.h;
    final canScroll = widget.options.length > _maximumVisibleOptions;

    return SizedBox(
      key: const Key('certificationSelectionOptionList'),
      height: listHeight,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        physics: canScroll
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          return _CertificationSelectionOption<T>(
            option: option,
            selected: _selectedValue == option.value,
            onTap: () => setState(() => _selectedValue = option.value),
          );
        },
        separatorBuilder: (_, _) => SizedBox(height: _optionSpacing.h),
      ),
    );
  }
}

class _CertificationSelectionOption<T> extends StatelessWidget {
  const _CertificationSelectionOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CertificationSelectionSheetOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: option.key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.uploadMethodSelected : null,
        ),
        child: SizedBox(
          height: 46.h,
          width: double.infinity,
          child: option.iconAsset == null
              ? Center(child: _buildLabel())
              : Row(
                  children: [
                    SizedBox(width: 45.w),
                    Image.asset(option.iconAsset!, width: 30.w, height: 30.h),
                    Expanded(child: Center(child: _buildLabel())),
                    SizedBox(width: 75.w),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return Text(
      option.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.uploadMethodText,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 25 / 18,
      ),
    );
  }
}

class _CertificationSelectionActionButton extends StatelessWidget {
  const _CertificationSelectionActionButton({
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
