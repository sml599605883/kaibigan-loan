import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../assets/app_assets.dart';
import '../../core/client/client_bridge.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/report/risk_report_scene.dart';
import '../../core/session/session_store.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';
import 'trust_decision_result_reporter.dart';
import 'widgets/certification_prompt_banner.dart';
import 'widgets/certification_retention_guard.dart';

typedef TrustDecisionLivenessLauncher =
    Future<TrustDecisionLivenessResult> Function(String license);
typedef FaceImageFilePathBuilder = Future<String> Function(String imageBase64);
typedef CameraPermissionRequester = Future<PermissionStatus> Function();
typedef AppSettingsOpener = Future<bool> Function();

class CertificationFacePage extends StatefulWidget {
  const CertificationFacePage({
    super.key,
    CameraPermissionRequester? requestCameraPermission,
    AppSettingsOpener? openAppSettingsPage,
    TrustDecisionLivenessLauncher? showTrustDecisionLiveness,
    FaceImageFilePathBuilder? faceImageFilePathBuilder,
  }) : requestCameraPermission =
           requestCameraPermission ?? _defaultRequestCameraPermission,
       openAppSettingsPage = openAppSettingsPage ?? openAppSettings,
       showTrustDecisionLiveness =
           showTrustDecisionLiveness ?? _defaultShowTrustDecisionLiveness,
       faceImageFilePathBuilder =
           faceImageFilePathBuilder ?? _defaultFaceImageFilePathBuilder;

  final CameraPermissionRequester requestCameraPermission;
  final AppSettingsOpener openAppSettingsPage;
  final TrustDecisionLivenessLauncher showTrustDecisionLiveness;
  final FaceImageFilePathBuilder faceImageFilePathBuilder;

  @override
  State<CertificationFacePage> createState() => _CertificationFacePageState();
}

class _CertificationFacePageState extends State<CertificationFacePage> {
  static const _defaultPrompt =
      'A clear ID photo is the key to lightning-fast approval. Please upload ID front.';

  bool _isSubmitting = false;
  late final int _scene4StartTimeSeconds;

  @override
  void initState() {
    super.initState();
    _scene4StartTimeSeconds = RiskReportScene.nowSeconds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.certificationPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _FaceHeader(
              onBack: CertificationRetentionGuard.backHandler(
                type: '1',
                productId: _productIdFromCache(),
              ),
            ),
            SizedBox(height: 20.h),
            CertificationPromptBanner(message: _promptTextFromCache()),
            SizedBox(height: 40.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 19.w),
                  child: Image.asset(
                    AppAssets.certificationFaceGuide,
                    fit: BoxFit.fill,
                  ),
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

  String _promptTextFromCache() {
    if (!Get.isRegistered<SessionStore>()) {
      return _defaultPrompt;
    }
    final detail = SessionStore.instance.productDetailCache();
    final message = detail?.note['face']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }
    return _defaultPrompt;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    await AppToast.showLoading();
    try {
      final permissionStatus = await widget.requestCameraPermission();
      if (!mounted) {
        return;
      }
      if (!permissionStatus.isGranted) {
        await AppToast.dismissLoading();
        await _showCameraPermissionDialog();
        return;
      }
      final response = await ApiClient.instance.getFaceToken(
        dodgy: _orderNoFromCache(),
        commensurate: '0',
      );
      if (!mounted) {
        return;
      }
      final token = _FaceTokenResult.fromResponse(response);
      if (token.code == '400') {
        await AppToast.error(
          token.message.isNotEmpty
              ? token.message
              : 'Please re-upload your ID photo.',
        );
        return;
      }
      if (token.code != '200' || token.license.isEmpty) {
        await AppToast.error(
          token.message.isNotEmpty ? token.message : 'Failed to get face token',
        );
        return;
      }
      if (token.faceType != '7') {
        await AppToast.error('Unsupported liveness verification type');
        return;
      }
      final result = await widget.showTrustDecisionLiveness(token.license);
      unawaited(reportTrustDecisionResult(result));
      if (!result.success) {
        await AppToast.error(
          result.message.isNotEmpty
              ? result.message
              : 'Liveness verification failed',
        );
        return;
      }
      await AppToast.dismissLoading();
      await _uploadTrustDecisionFace(result: result, token: token);
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

  Future<void> _showCameraPermissionDialog() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Enable Your Camera'),
          content: const Text(
            'ID document scanning and selfie require camera access. Please enable it in your device Settings to continue.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: AppColors.cameraPermissionLaterText),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widget.openAppSettingsPage();
              },
              isDefaultAction: true,
              child: const Text('Enable Camera'),
            ),
          ],
        );
      },
    );
  }

  String _productIdFromCache() {
    if (!Get.isRegistered<SessionStore>()) {
      return '';
    }
    return SessionStore.instance.productDetailCache()?.productid.trim() ?? '';
  }

  String _orderNoFromCache() {
    if (!Get.isRegistered<SessionStore>()) {
      return '';
    }
    return SessionStore.instance.productDetailCache()?.orderNo.trim() ?? '';
  }

  Future<void> _uploadTrustDecisionFace({
    required TrustDecisionLivenessResult result,
    required _FaceTokenResult token,
  }) async {
    final imageBase64 = result.image.trim();
    if (imageBase64.isEmpty) {
      throw const FormatException('Missing liveness image');
    }
    await AppToast.showLoading();
    final filePath = await widget.faceImageFilePathBuilder(imageBase64);
    await ApiClient.instance.uploadImage(
      commensurate: '10',
      gams: '1',
      filePath: filePath,
      fileField: 'attach',
      scolloped: result.livenessId.trim(),
      arrests: token.license,
      clevises: token.faceType,
    );
    if (!mounted) {
      return;
    }
    await AppToast.dismissLoading();
    final productId = _productIdFromCache();
    if (productId.isNotEmpty) {
      RiskReportScene.report(
        productId: productId,
        sceneType: '4',
        startTimeSeconds: _scene4StartTimeSeconds,
      );
    }
    await NavigationHelper.continueProductDetailFlow(productId);
  }
}

class _FaceTokenResult {
  const _FaceTokenResult({
    required this.code,
    required this.license,
    required this.faceType,
    required this.message,
  });

  factory _FaceTokenResult.fromResponse(dynamic response) {
    final states = response.states;
    return _FaceTokenResult(
      code: states['dwarfishly'].stringValue.trim(),
      license: states['thatches'].stringValue.trim(),
      faceType: states['clevises'].stringValue.trim(),
      message: states['rail'].stringValue.trim(),
    );
  }

  final String code;
  final String license;
  final String faceType;
  final String message;
}

Future<TrustDecisionLivenessResult> _defaultShowTrustDecisionLiveness(
  String license,
) {
  return ClientBridge().showTrustDecisionLiveness(license);
}

Future<PermissionStatus> _defaultRequestCameraPermission() {
  return Permission.camera.request();
}

Future<String> _defaultFaceImageFilePathBuilder(String imageBase64) async {
  final normalized = imageBase64.contains(',')
      ? imageBase64.split(',').last
      : imageBase64;
  final bytes = base64Decode(normalized);
  final file = File(
    '${Directory.systemTemp.path}/certification_face_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

class _FaceHeader extends StatelessWidget {
  const _FaceHeader({required this.onBack});

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
