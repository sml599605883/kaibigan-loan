import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/report/risk_report_scene.dart';
import '../../core/session/session_store.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';
import 'widgets/certification_prompt_banner.dart';

class CertificationIdentitySubmitPage extends StatefulWidget {
  const CertificationIdentitySubmitPage({super.key});

  @override
  State<CertificationIdentitySubmitPage> createState() =>
      _CertificationIdentitySubmitPageState();
}

class _CertificationIdentitySubmitPageState
    extends State<CertificationIdentitySubmitPage> {
  static const _defaultPrompt =
      'A clear ID photo is the key to lightning-fast approval. Please upload ID front.';

  bool _isSubmitting = false;
  late final TextEditingController _nameController;
  late final TextEditingController _idNoController;
  late final TextEditingController _birthdayController;
  late final String _imageUrl;

  @override
  void initState() {
    super.initState();
    final info = _recognizedInfo();
    _nameController = TextEditingController(text: info.name);
    _idNoController = TextEditingController(text: info.idNo);
    _birthdayController = TextEditingController(text: info.birthday);
    _imageUrl = info.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNoController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.certificationPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _IdentitySubmitHeader(onBack: NavigationHelper.back),
            SizedBox(height: 21.h),
            CertificationPromptBanner(message: _promptTextFromCache()),
            SizedBox(height: 45.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IdImagePreview(imageUrl: _imageUrl),
                    SizedBox(height: 27.h),
                    _EditableIdentityField(
                      key: const Key('identityFullNameInput'),
                      label: 'Full Name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 18.h),
                    _EditableIdentityField(
                      key: const Key('identityIdNoInput'),
                      label: 'ID No.',
                      controller: _idNoController,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 18.h),
                    _EditableIdentityField(
                      key: const Key('identityBirthdayInput'),
                      label: 'Date of Birth',
                      controller: _birthdayController,
                      readOnly: true,
                      onTap: _logBirthdayPickerTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 20.h, left: 60.w, right: 60.w),
          child: SizedBox(
            width: 276.w,
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.certificationTabActive,
                foregroundColor: AppColors.certificationSubmitText,
                disabledBackgroundColor: AppColors.certificationTabActive,
                disabledForegroundColor: AppColors.certificationSubmitText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: Text(
                'Submit',
                style: TextStyle(
                  color: AppColors.certificationSubmitText,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  height: 22 / 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _RecognizedIdentityInfo _recognizedInfo() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return _RecognizedIdentityInfo.fromJson(arguments['recognizedInfo']);
    }
    return const _RecognizedIdentityInfo();
  }

  String _cardTypeFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return Json(arguments)['cardType'].stringValue.trim();
    }
    return '';
  }

  String _productIdFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return Json(arguments)['geobotanists'].stringValue.trim();
    }
    return '';
  }

  String _promptTextFromCache() {
    if (!Get.isRegistered<SessionStore>()) {
      return _defaultPrompt;
    }
    final detail = SessionStore.instance.productDetailCache();
    final message = detail?.note['base_success']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }
    return _defaultPrompt;
  }

  int _scene3StartTimeSecondsFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      final value = arguments['scene3StartTimeSeconds'];
      if (value is int && value > 0) {
        return value;
      }
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return RiskReportScene.nowSeconds();
  }

  void _logBirthdayPickerTap() {
    debugPrint('identity birthday date picker tapped');
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    await AppToast.showLoading();
    try {
      final response = await ApiClient.instance.saveBasicInfo(
        asthmas: _birthdayController.text.trim(),
        overmanaged: _idNoController.text.trim(),
        unwits: _nameController.text.trim(),
        commensurate: '11',
        heirship: _cardTypeFromArguments(),
      );
      if (!mounted) {
        return;
      }
      await AppToast.dismissLoading();
      if (response.message.trim().isNotEmpty) {
        await AppToast.show(response.message);
      }
      final productId = _productIdFromArguments();
      if (productId.isNotEmpty) {
        RiskReportScene.report(
          productId: productId,
          sceneType: '3',
          startTimeSeconds: _scene3StartTimeSecondsFromArguments(),
        );
        await NavigationHelper.continueProductDetailFlow(productId);
        return;
      }
      NavigationHelper.toCertificationFace<void>(
        productId: productId,
        arguments: {
          'geobotanists': productId,
          'cardType': _cardTypeFromArguments(),
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppToast.error(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _RecognizedIdentityInfo {
  const _RecognizedIdentityInfo({
    this.name = '',
    this.idNo = '',
    this.birthday = '',
    this.imageUrl = '',
  });

  factory _RecognizedIdentityInfo.fromJson(dynamic value) {
    final json = Json(value);
    return _RecognizedIdentityInfo(
      name: json['unwits'].stringValue.trim(),
      idNo: json['overmanaged'].stringValue.trim(),
      birthday: _formatBirthday(json['asthmas'].stringValue),
      imageUrl: json['bloomeries'].stringValue.trim(),
    );
  }

  final String name;
  final String idNo;
  final String birthday;
  final String imageUrl;

  static String _formatBirthday(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\d{4})/(\d{2})/(\d{2})$').firstMatch(trimmed);
    if (match == null) {
      return trimmed;
    }
    return '${match.group(3)}-${match.group(2)}-${match.group(1)}';
  }
}

class _IdentitySubmitHeader extends StatelessWidget {
  const _IdentitySubmitHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Padding(
          //     padding: EdgeInsets.only(left: 20.w),
          //     child: GestureDetector(
          //       behavior: HitTestBehavior.opaque,
          //       onTap: onBack,
          //       child: Image.asset(
          //         AppAssets.loginBack,
          //         width: 23.w,
          //         height: 20.h,
          //       ),
          //     ),
          //   ),
          // ),
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

class _IdImagePreview extends StatelessWidget {
  const _IdImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.isEmpty
        ? Image.asset(AppAssets.certificationIdUploadDemo, fit: BoxFit.cover)
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Image.asset(
              AppAssets.certificationIdUploadDemo,
              fit: BoxFit.cover,
            ),
          );

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 295.w,
          height: 186.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.certificationIdPreviewBorder),
          ),
          child: image,
        ),
      ),
    );
  }
}

class _EditableIdentityField extends StatelessWidget {
  const _EditableIdentityField({
    super.key,
    required this.label,
    required this.controller,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.certificationFieldLabel,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            height: 14 / 12,
          ),
        ),
        SizedBox(height: 7.h),
        Container(
          height: 40.h,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.certificationCardBackground,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.certificationFieldBorder),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            textInputAction: textInputAction,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.certificationFieldText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 17 / 14,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 11.h,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
