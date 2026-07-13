import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/report/risk_report_scene.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';
import 'models/address_option.dart';
import 'models/address_selection.dart';
import 'widgets/certification_address_selection_sheet.dart';
import 'widgets/certification_prompt_banner.dart';
import 'widgets/certification_selection_sheet.dart';

class CertificationPersonalInfoPage extends StatefulWidget {
  const CertificationPersonalInfoPage({super.key})
    : _kind = _CertificationInfoKind.personal;

  const CertificationPersonalInfoPage.work({super.key})
    : _kind = _CertificationInfoKind.work;

  final _CertificationInfoKind _kind;

  @override
  State<CertificationPersonalInfoPage> createState() =>
      _CertificationPersonalInfoPageState();
}

class _CertificationPersonalInfoPageState
    extends State<CertificationPersonalInfoPage> {
  static const _defaultPrompt =
      'Fill in personal information truthfully and accurately, with a 90% success rate';

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _prompt = _defaultPrompt;
  List<_PersonalInfoField> _fields = <_PersonalInfoField>[];
  List<AddressOption>? _cachedAddressOptions;
  Future<List<AddressOption>>? _addressOptionsFuture;
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  late final int _sceneStartTimeSeconds;

  @override
  void initState() {
    super.initState();
    _sceneStartTimeSeconds = RiskReportScene.nowSeconds();
    _loadPersonalInfo();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPersonalInfo() async {
    final productId = _productIdFromArguments();
    if (productId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = widget._kind == _CertificationInfoKind.work
          ? await ApiClient.instance.jobInfo(geobotanists: productId)
          : await ApiClient.instance.personalInfo(geobotanists: productId);
      final fields = response.states['enthrones'].listValue
          .map(_PersonalInfoField.fromJson)
          .where((field) => field.keyName.isNotEmpty)
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _prompt = _firstNonEmpty(
          response.states['mourningly'].stringValue.trim(),
          _defaultPrompt,
        );
        _fields = fields;
        _syncControllers(fields);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fields = <_PersonalInfoField>[];
        _isLoading = false;
      });
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
  }

  void _syncControllers(List<_PersonalInfoField> fields) {
    final activeKeys = fields
        .where((field) => field.usesTextInput)
        .map((field) => field.keyName)
        .toSet();
    for (final key in _controllers.keys.toList()) {
      if (!activeKeys.contains(key)) {
        _controllers.remove(key)?.dispose();
      }
    }
    for (final field in fields) {
      if (!field.usesTextInput) {
        continue;
      }
      _controllers.putIfAbsent(
        field.keyName,
        () => TextEditingController(text: field.currentText),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.certificationPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _PersonalInfoHeader(onBack: NavigationHelper.back),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: CertificationPromptBanner(message: _prompt),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Image.asset(
                _progressAsset,
                key: const Key('personalInfoProgressImage'),
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(height: 18.h),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 20.h, left: 56.w, right: 56.w),
          child: SizedBox(
            height: 50.h,
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

  String get _progressAsset => widget._kind == _CertificationInfoKind.work
      ? AppAssets.certificationWorkProgress
      : AppAssets.certificationPersonalProgress;

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fields.isEmpty) {
      return Center(
        child: Text(
          'No personal information available',
          style: TextStyle(
            color: AppColors.certificationEmptyText,
            fontSize: 14.sp,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < _fields.length; index++) ...[
            if (index > 0) SizedBox(height: 10.h),
            _PersonalInfoFieldView(
              field: _fields[index],
              controller: _controllers[_fields[index].keyName],
              onTap: () => _handleFieldTap(_fields[index]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleFieldTap(_PersonalInfoField field) async {
    if (field.usesAddressPicker) {
      await _selectAddress(field);
      return;
    }
    await _selectOption(field);
  }

  Future<void> _selectOption(_PersonalInfoField field) async {
    if (!field.usesPicker || field.options.isEmpty) {
      return;
    }
    final option = await showCertificationSelectionSheet<_PersonalInfoOption>(
      context: context,
      options: field.options
          .map(
            (option) => CertificationSelectionSheetOption(
              value: option,
              label: option.label,
              key: Key('certificationInfoOption_${option.value}'),
            ),
          )
          .toList(growable: false),
      initialValue: field.selectedOption,
    );
    if (option == null || !mounted) {
      return;
    }
    setState(() {
      field.select(option);
    });
  }

  Future<void> _selectAddress(_PersonalInfoField field) async {
    final shouldShowLoading =
        _cachedAddressOptions == null && _addressOptionsFuture == null;
    try {
      if (shouldShowLoading) {
        await AppToast.showLoading();
      }
      final options = await _getAddressOptions();
      if (options.isEmpty) {
        await AppToast.error(field.placeholder);
        return;
      }
      if (shouldShowLoading) {
        await AppToast.dismissLoading();
      }
      if (!mounted) {
        return;
      }
      final selection = await showCertificationAddressSelectionSheet(
        context: context,
        options: options,
      );
      if (selection == null || !mounted) {
        return;
      }
      setState(() => field.selectAddress(selection));
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
  }

  Future<List<AddressOption>> _getAddressOptions() {
    final cached = _cachedAddressOptions;
    if (cached != null && cached.isNotEmpty) {
      return Future<List<AddressOption>>.value(cached);
    }
    final inFlight = _addressOptionsFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _fetchAddressOptions();
    _addressOptionsFuture = future;
    return future;
  }

  Future<List<AddressOption>> _fetchAddressOptions() async {
    try {
      final response = await ApiClient.instance.addressInit();
      final options = AddressOption.parseList(response.states);
      if (options.isNotEmpty) {
        _cachedAddressOptions = options;
      }
      return options;
    } finally {
      _addressOptionsFuture = null;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final payload = <String, dynamic>{
      'geobotanists': _productIdFromArguments(),
    };
    for (final field in _fields) {
      final value = field.usesTextInput
          ? (_controllers[field.keyName]?.text.trim() ?? '')
          : field.selectedValue.trim();
      if (field.isRequired && value.isEmpty) {
        await AppToast.error(field.placeholder);
        return;
      }
      if (value.isNotEmpty) {
        payload[field.keyName] = value;
      }
    }

    setState(() => _isSubmitting = true);
    await AppToast.showLoading();
    try {
      final response = widget._kind == _CertificationInfoKind.work
          ? await ApiClient.instance.saveJobInfo(data: payload)
          : await ApiClient.instance.savePersonalInfo(data: payload);
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
          sceneType: widget._kind == _CertificationInfoKind.work ? '6' : '5',
          startTimeSeconds: _sceneStartTimeSeconds,
        );
        await NavigationHelper.continueProductDetailFlow(productId);
      }
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

  String _firstNonEmpty(String primary, String fallback) {
    return primary.isNotEmpty ? primary : fallback;
  }
}

enum _CertificationInfoKind { personal, work }

class _PersonalInfoHeader extends StatelessWidget {
  const _PersonalInfoHeader({required this.onBack});

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

class _PersonalInfoFieldView extends StatelessWidget {
  const _PersonalInfoFieldView({
    required this.field,
    required this.controller,
    required this.onTap,
  });

  final _PersonalInfoField field;
  final TextEditingController? controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.certificationFieldLabel,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            height: 14 / 12,
          ),
        ),
        SizedBox(height: 7.h),
        field.usesTextInput
            ? _PersonalInfoInput(field: field, controller: controller!)
            : _PersonalInfoPicker(field: field, onTap: onTap),
      ],
    );
  }
}

class _PersonalInfoInput extends StatelessWidget {
  const _PersonalInfoInput({required this.field, required this.controller});

  final _PersonalInfoField field;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: TextField(
        key: Key('personalInfoInput_${field.keyName}'),
        controller: controller,
        keyboardType: field.numericKeyboard
            ? TextInputType.number
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: AppColors.certificationFieldText,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          height: 17 / 14,
        ),
        decoration: InputDecoration(
          hintText: field.placeholder,
          hintStyle: TextStyle(
            color: AppColors.certificationFieldLabel,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          enabledBorder: _fieldBorder(),
          focusedBorder: _fieldBorder(),
          border: _fieldBorder(),
        ),
      ),
    );
  }
}

class _PersonalInfoPicker extends StatelessWidget {
  const _PersonalInfoPicker({required this.field, required this.onTap});

  final _PersonalInfoField field;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = field.currentText;
    return Material(
      color: AppColors.certificationCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: const BorderSide(color: AppColors.certificationFieldBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: SizedBox(
          height: 40.h,
          child: Padding(
            padding: EdgeInsets.only(left: 12.w, right: 10.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text.isEmpty ? field.placeholder : text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text.isEmpty
                          ? AppColors.certificationFieldLabel
                          : AppColors.certificationFieldText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      height: 17 / 14,
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
    );
  }
}

OutlineInputBorder _fieldBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(20.r),
    borderSide: const BorderSide(color: AppColors.certificationFieldBorder),
  );
}

class _PersonalInfoField {
  _PersonalInfoField({
    required this.title,
    required this.placeholder,
    required this.keyName,
    required this.controlType,
    required this.numericKeyboard,
    required this.isRequired,
    required this.options,
    required String currentText,
  }) : _currentText = currentText {
    _selectedOption = _optionForText(currentText);
  }

  factory _PersonalInfoField.fromJson(Json json) {
    final options = json['metallurgists'].listValue
        .map(_PersonalInfoOption.fromJson)
        .where((option) => option.label.isNotEmpty)
        .toList(growable: false);
    final title = json['primogenitor'].stringValue.trim();
    return _PersonalInfoField(
      title: title,
      placeholder: _firstNonEmpty(json['suppletive'].stringValue.trim(), title),
      keyName: json['griding'].stringValue.trim(),
      controlType: json['prognosticator'].stringValue.trim(),
      numericKeyboard: json['bellyache'].intValue == 1,
      isRequired: json['hairbreadth'].intValue != 1,
      options: options,
      currentText: json['solonets'].stringValue.trim(),
    );
  }

  final String title;
  final String placeholder;
  final String keyName;
  final String controlType;
  final bool numericKeyboard;
  final bool isRequired;
  final List<_PersonalInfoOption> options;
  String _currentText;
  _PersonalInfoOption? _selectedOption;

  bool get usesAddressPicker => controlType == 'stage';
  bool get usesPicker =>
      !usesAddressPicker && options.isNotEmpty && !usesTextInput;
  bool get usesTextInput =>
      !usesAddressPicker &&
      (controlType == 'onto' || controlType == 'txt' || options.isEmpty);

  String get currentText => _selectedOption?.label ?? _currentText;
  _PersonalInfoOption? get selectedOption => _selectedOption;
  String get selectedValue => usesAddressPicker
      ? _currentText
      : _selectedOption?.value ?? _optionForText(_currentText)?.value ?? '';

  void select(_PersonalInfoOption option) {
    _selectedOption = option;
    _currentText = option.label;
  }

  void selectAddress(AddressSelection selection) {
    _selectedOption = null;
    _currentText = selection.value;
  }

  _PersonalInfoOption? _optionForText(String text) {
    final normalizedText = text.trim().toLowerCase();
    if (normalizedText.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.label.toLowerCase() == normalizedText ||
          option.value == text.trim()) {
        return option;
      }
    }
    return null;
  }
}

class _PersonalInfoOption {
  const _PersonalInfoOption({required this.label, required this.value});

  factory _PersonalInfoOption.fromJson(Json json) {
    return _PersonalInfoOption(
      label: json['unwits'].stringValue.trim(),
      value: json['commensurate'].stringValue.trim(),
    );
  }

  final String label;
  final String value;
}

String _firstNonEmpty(String primary, String fallback) {
  return primary.isNotEmpty ? primary : fallback;
}
