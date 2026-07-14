import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../models/bind_card_info.dart';

Future<BindCardOption?> showCertificationBindCardOptionSheet(
  BuildContext context, {
  required List<BindCardOption> options,
  String? initialValue,
}) {
  return showModalBottomSheet<BindCardOption>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.uploadMethodBarrier,
    isScrollControlled: true,
    builder: (_) =>
        _BindCardOptionSheet(options: options, initialValue: initialValue),
  );
}

class _BindCardOptionSheet extends StatefulWidget {
  const _BindCardOptionSheet({
    required this.options,
    required this.initialValue,
  });

  final List<BindCardOption> options;
  final String? initialValue;

  @override
  State<_BindCardOptionSheet> createState() => _BindCardOptionSheetState();
}

class _BindCardOptionSheetState extends State<_BindCardOptionSheet> {
  static const _maximumVisibleOptions = 5;
  static const _optionHeight = 46.0;
  static const _optionSpacing = 12.0;

  final ScrollController _scrollController = ScrollController();
  BindCardOption? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.options
        .where((option) => option.value == widget.initialValue)
        .firstOrNull;
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
          padding: EdgeInsets.fromLTRB(0, 24.h, 0, 15.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                key: const Key('bindCardOptionList'),
                height: _optionListHeight,
                child: ListView.separated(
                  controller: _scrollController,
                  shrinkWrap: true,
                  physics: widget.options.length > _maximumVisibleOptions
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: widget.options.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (_, index) {
                    final option = widget.options[index];
                    final selected = option.value == _selected?.value;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = option),
                      child: Container(
                        key: Key('bindCardOptionRow_$index'),
                        height: 46.h,
                        color: selected ? AppColors.uploadMethodSelected : null,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                              ),
                              child: Row(
                                key: Key('bindCardOptionContent_$index'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (option.logoUrl.isNotEmpty) ...[
                                    _BusinessLogo(url: option.logoUrl),
                                    SizedBox(width: 12.w),
                                  ],
                                  Flexible(
                                    child: Text(
                                      option.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.uploadMethodText,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                height: 46.h,
                child: Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        label: 'Cancel',
                        background: AppColors.uploadMethodCancelBackground,
                        textColor: AppColors.uploadMethodCancelText,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: _SheetButton(
                        label: 'Done',
                        background: AppColors.uploadMethodDoneBackground,
                        textColor: AppColors.uploadMethodDoneText,
                        onTap: () => Navigator.of(context).pop(_selected),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _optionListHeight {
    final visibleOptionCount = widget.options.length.clamp(
      0,
      _maximumVisibleOptions,
    );
    if (visibleOptionCount == 0) {
      return 0;
    }
    return visibleOptionCount * _optionHeight.h +
        (visibleOptionCount - 1) * _optionSpacing.h;
  }
}

class _BusinessLogo extends StatelessWidget {
  const _BusinessLogo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return SizedBox(width: 30.w, height: 30.h);
    }
    return Image.network(
      url,
      width: 30.w,
      height: 30.h,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox(width: 30.w, height: 30.h),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: textColor, fontSize: 18.sp),
          ),
        ),
      ),
    );
  }
}
