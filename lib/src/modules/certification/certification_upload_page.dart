import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app_routes.dart';
import '../../assets/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';
import 'widgets/certification_prompt_banner.dart';

enum CertificationUploadMethod { photoAlbum, camera }

abstract class CertificationUploadImagePicker {
  Future<String?> pickFromCamera();

  Future<String?> pickFromGallery();
}

abstract class CertificationUploadImageCompressor {
  Future<String?> compressToLimit(String filePath);
}

class CertificationUploadCameraPermissionException implements Exception {
  const CertificationUploadCameraPermissionException();
}

class ImagePickerCertificationUploadImagePicker
    implements CertificationUploadImagePicker {
  ImagePickerCertificationUploadImagePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const CertificationUploadCameraPermissionException();
    }
    final file = await _imagePicker.pickImage(source: ImageSource.camera);
    return file?.path;
  }

  @override
  Future<String?> pickFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    return file?.path;
  }
}

class DefaultCertificationUploadImageCompressor
    implements CertificationUploadImageCompressor {
  static const _targetBytes = 500 * 1024;

  @override
  Future<String?> compressToLimit(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }

    var quality = 90;
    File compressedFile = file;
    while (quality >= 10) {
      final qualityCompressedFile = await _compressImageQuality(
        compressedFile,
        quality,
      );
      if (qualityCompressedFile == null) {
        return null;
      }
      compressedFile = qualityCompressedFile;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
      quality -= 5;
    }

    final bytes = await compressedFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    var currentWidth = frame.image.width;
    var currentHeight = frame.image.height;

    while (currentWidth > 100 && currentHeight > 100) {
      currentWidth = (currentWidth * 0.95).toInt();
      currentHeight = (currentHeight * 0.95).toInt();
      final sizeCompressedFile = await _compressImageSize(
        file,
        currentWidth,
        currentHeight,
      );
      if (sizeCompressedFile == null) {
        return null;
      }
      compressedFile = sizeCompressedFile;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
    }
    return compressedFile.path;
  }

  Future<File?> _compressImageQuality(File file, int quality) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/certification_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: false,
      keepExif: false,
    );
    if (result == null) {
      return null;
    }
    return File(result.path);
  }

  Future<File?> _compressImageSize(File file, int width, int height) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/certification_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      minWidth: width,
      minHeight: height,
      quality: 95,
      format: CompressFormat.jpeg,
    );
    if (result == null) {
      return null;
    }
    return File(result.path);
  }
}

class CertificationUploadPage extends StatefulWidget {
  const CertificationUploadPage({
    super.key,
    this.onUploadMethodSelected,
    this.imagePicker,
    this.imageCompressor,
    this.openAppSettingsPage = openAppSettings,
  });

  final ValueChanged<CertificationUploadMethod>? onUploadMethodSelected;
  final CertificationUploadImagePicker? imagePicker;
  final CertificationUploadImageCompressor? imageCompressor;
  final Future<bool> Function() openAppSettingsPage;

  @override
  State<CertificationUploadPage> createState() =>
      _CertificationUploadPageState();
}

class _CertificationUploadPageState extends State<CertificationUploadPage> {
  late final CertificationUploadImagePicker _imagePicker =
      widget.imagePicker ?? ImagePickerCertificationUploadImagePicker();
  late final CertificationUploadImageCompressor _imageCompressor =
      widget.imageCompressor ?? DefaultCertificationUploadImageCompressor();
  bool _isUploading = false;

  static const _promptText =
      'A clear ID photo is the key to lightning-fast approval. Please upload ID front.';

  @override
  Widget build(BuildContext context) {
    final promptText = _promptTextFromCache();

    return Scaffold(
      backgroundColor: AppColors.certificationPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _UploadHeader(onBack: NavigationHelper.back),
            SizedBox(height: 21.h),
            CertificationPromptBanner(message: promptText),
            SizedBox(height: 21.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 19.w),
                      child: Image.asset(
                        AppAssets.certificationIdUploadDemo,
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(height: 24.h),
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: _isUploading
                  ? null
                  : () => _showUploadMethodSheet(context),
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
      return _promptText;
    }
    final detail = SessionStore.instance.productDetailCache();
    final message = detail?.note['base']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }
    return _promptText;
  }

  Future<void> _showUploadMethodSheet(BuildContext context) async {
    final selectedMethod =
        await showModalBottomSheet<CertificationUploadMethod>(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: AppColors.uploadMethodBarrier,
          elevation: 0,
          isScrollControlled: true,
          builder: (_) => const _UploadMethodSheet(),
        );
    if (selectedMethod == null) {
      return;
    }
    widget.onUploadMethodSelected?.call(selectedMethod);
    await _pickCompressAndUpload(selectedMethod);
  }

  Future<void> _pickCompressAndUpload(CertificationUploadMethod method) async {
    await AppToast.showLoading();
    final String? filePath;
    try {
      filePath = method == CertificationUploadMethod.camera
          ? await _imagePicker.pickFromCamera()
          : await _imagePicker.pickFromGallery();
    } on CertificationUploadCameraPermissionException {
      await AppToast.dismissLoading();
      if (!mounted) {
        return;
      }
      await _showCameraPermissionDialog();
      return;
    }

    if (filePath == null || filePath.isEmpty) {
      await AppToast.dismissLoading();
      return;
    }

    final compressedPath = await _imageCompressor.compressToLimit(filePath);
    if (compressedPath == null || compressedPath.isEmpty) {
      await AppToast.error('Image compression failed');
      return;
    }

    await _uploadSelectedFile(compressedPath, method);
  }

  Future<void> _uploadSelectedFile(
    String filePath,
    CertificationUploadMethod method,
  ) async {
    if (_isUploading) {
      return;
    }
    setState(() => _isUploading = true);
    try {
      final response = await ApiClient.instance.uploadImage(
        commensurate: '11',
        gams: method == CertificationUploadMethod.photoAlbum ? '1' : '2',
        filePath: filePath,
        fileField: 'attach',
        heirship: _cardTypeFromArguments(),
      );
      if (!mounted) {
        return;
      }
      await AppToast.dismissLoading();
      Get.toNamed<void>(
        AppRoutes.certificationIdentitySubmit,
        arguments: {
          'geobotanists': _productIdFromArguments(),
          'cardType': _cardTypeFromArguments(),
          'scene3StartTimeSeconds': _scene3StartTimeSecondsFromArguments(),
          'recognizedInfo': response.states.rawMapValue,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppToast.error(ApiErrorMessage.resolve(error));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _showCameraPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Camera permission required'),
          content: const Text(
            'Please enable camera access in Settings to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widget.openAppSettingsPage();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  String _cardTypeFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return arguments['cardType']?.toString().trim() ?? '';
    }
    return '';
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
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  String _productIdFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return arguments['geobotanists']?.toString().trim() ?? '';
    }
    return '';
  }
}

class _UploadMethodSheet extends StatefulWidget {
  const _UploadMethodSheet();

  @override
  State<_UploadMethodSheet> createState() => _UploadMethodSheetState();
}

class _UploadMethodSheetState extends State<_UploadMethodSheet> {
  static const _photoAlbum = 'Photo album';
  static const _photograph = 'Photograph';

  CertificationUploadMethod? _selectedMethod;

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
              _UploadMethodOption(
                key: const Key('certificationUploadPhotoAlbumOption'),
                iconAsset: AppAssets.certificationUploadAlbum,
                label: _photoAlbum,
                selected:
                    _selectedMethod == CertificationUploadMethod.photoAlbum,
                onTap: () => _select(CertificationUploadMethod.photoAlbum),
              ),
              SizedBox(height: 15.h),
              _UploadMethodOption(
                key: const Key('certificationUploadPhotographOption'),
                iconAsset: AppAssets.certificationUploadCamera,
                label: _photograph,
                selected: _selectedMethod == CertificationUploadMethod.camera,
                onTap: () => _select(CertificationUploadMethod.camera),
              ),
              SizedBox(height: 29.h),
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 15.w),
                child: SizedBox(
                  height: 46.h,
                  child: Row(
                    children: [
                      Expanded(
                        child: _UploadMethodActionButton(
                          label: 'Cancel',
                          backgroundColor:
                              AppColors.uploadMethodCancelBackground,
                          textColor: AppColors.uploadMethodCancelText,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: _UploadMethodActionButton(
                          label: 'Done',
                          backgroundColor: AppColors.uploadMethodDoneBackground,
                          textColor: AppColors.uploadMethodDoneText,
                          onTap: () =>
                              Navigator.of(context).pop(_selectedMethod),
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

  void _select(CertificationUploadMethod method) {
    setState(() => _selectedMethod = method);
  }
}

class _UploadMethodOption extends StatelessWidget {
  const _UploadMethodOption({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.uploadMethodSelected : null,
        ),
        child: SizedBox(
          height: 46.h,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              child: Row(
                children: [
                  SizedBox(width: 45.w),
                  Image.asset(iconAsset, width: 30.w, height: 30.h),
                  Expanded(
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
                  SizedBox(width: 75.w),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadMethodActionButton extends StatelessWidget {
  const _UploadMethodActionButton({
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

class _UploadHeader extends StatelessWidget {
  const _UploadHeader({required this.onBack});

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
