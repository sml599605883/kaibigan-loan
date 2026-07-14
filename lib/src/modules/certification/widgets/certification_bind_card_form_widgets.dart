import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../assets/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';
import '../models/bind_card_info.dart';

class CertificationBindCardHeader extends StatelessWidget {
  const CertificationBindCardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 48.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: IconButton(
                tooltip: 'Back',
                onPressed: Get.back,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                padding: EdgeInsets.zero,
                icon: Image.asset(
                  AppAssets.loginBack,
                  width: 23.w,
                  height: 20.h,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 64.w, vertical: 4.h),
            child: Text(
              'Identity verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.certificationTitleText,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CertificationBindCardField extends StatelessWidget {
  const CertificationBindCardField({
    super.key,
    required this.field,
    required this.controller,
    required this.focusNode,
    required this.selectionLabel,
    required this.hasSelection,
    required this.onPickerTap,
    required this.showSuggestion,
    required this.onSuggestionTap,
    required this.onSuggestionClose,
  });

  final BindCardField field;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String selectionLabel;
  final bool hasSelection;
  final VoidCallback onPickerTap;
  final bool showSuggestion;
  final VoidCallback onSuggestionTap;
  final VoidCallback onSuggestionClose;

  @override
  Widget build(BuildContext context) {
    final isText = field.fieldType == BindCardFieldType.text;
    final displayText = hasSelection ? selectionLabel : field.placeholder;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: TextStyle(
                color: AppColors.certificationFieldLabel,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 7.h),
            SizedBox(
              height: 40.h,
              child: isText
                  ? TextField(
                      key: Key('bindCardField_${field.saveKey}'),
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _fieldDecoration(field.placeholder),
                      style: TextStyle(
                        color: AppColors.certificationFieldText,
                        fontSize: 14.sp,
                      ),
                    )
                  : Material(
                      color: AppColors.certificationCardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        side: const BorderSide(
                          color: AppColors.certificationFieldBorder,
                        ),
                      ),
                      child: InkWell(
                        key: Key('bindCardField_${field.saveKey}'),
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: onPickerTap,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasSelection
                                        ? AppColors.certificationFieldText
                                        : AppColors.certificationFieldLabel,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              Image.asset(
                                AppAssets.arrowRight,
                                width: 15.w,
                                height: 10.h,
                                color: AppColors.profileArrowTint,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        if (isText && showSuggestion)
          Positioned(
            top: 0,
            left: 0,
            right: 25.w,
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.topRight,
                child: _CertificationBindCardSuggestionBubble(
                  suggestion: field.suggestedValue,
                  maxWidth: constraints.maxWidth,
                  onTap: onSuggestionTap,
                  onClose: onSuggestionClose,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CertificationBindCardSuggestionBubble extends StatelessWidget {
  const _CertificationBindCardSuggestionBubble({
    required this.suggestion,
    required this.maxWidth,
    required this.onTap,
    required this.onClose,
  });

  final String suggestion;
  final double maxWidth;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 44.w, maxWidth: maxWidth),
      child: IntrinsicWidth(
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          button: true,
          label: 'Apply suggestion',
          child: GestureDetector(
            key: const Key('bindCardSuggestionBubble'),
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              height: 40.h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      AppAssets.certificationBindCardSuggestionBubble,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(13.w, 4.h, 6.w, 12.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            suggestion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.certificationSubmitText,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Semantics(
                          key: const Key('bindCardSuggestionClose'),
                          container: true,
                          button: true,
                          label: 'Close suggestion',
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onClose,
                            child: SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: Center(
                                child: Image.asset(
                                  AppAssets
                                      .certificationBindCardSuggestionClose,
                                  width: 12.w,
                                  height: 12.h,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String placeholder) => InputDecoration(
  hintText: placeholder,
  hintStyle: TextStyle(
    color: AppColors.certificationFieldLabel,
    fontSize: 14.sp,
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
  enabledBorder: _fieldBorder(),
  focusedBorder: _fieldBorder(),
  border: _fieldBorder(),
);

OutlineInputBorder _fieldBorder() => OutlineInputBorder(
  borderRadius: BorderRadius.circular(20.r),
  borderSide: const BorderSide(color: AppColors.certificationFieldBorder),
);

class CertificationBindCardFooter extends StatelessWidget {
  const CertificationBindCardFooter({
    super.key,
    required this.hint,
    required this.onSubmit,
  });

  final String hint;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.certificationBindFooterBorder),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint.isNotEmpty)
              Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.certificationBindFooterText,
                  fontSize: 12.sp,
                ),
              ),
            if (hint.isNotEmpty) SizedBox(height: 8.h),
            SizedBox(
              height: 50.h,
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('bindCardSubmit'),
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.certificationTabActive,
                  foregroundColor: AppColors.certificationSubmitText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text('Submit', style: TextStyle(fontSize: 18.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
