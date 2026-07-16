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
import 'models/personal_info_field.dart';
import 'models/personal_info_option.dart';
import 'models/salary_day_option.dart';
import 'widgets/certification_address_selection_sheet.dart';
import 'widgets/certification_prompt_banner.dart';
import 'widgets/certification_retention_guard.dart';
import 'widgets/certification_salary_day_selection_sheet.dart';
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
  List<PersonalInfoField> _fields = <PersonalInfoField>[];
  List<AddressOption>? _cachedAddressOptions;
  Future<List<AddressOption>>? _addressOptionsFuture;
  final Map<String, List<SalaryDayGroup>> _salaryDayOptions = {};
  final Map<String, SalaryDaySelection> _salaryDaySelections = {};
  late final int _sceneStartTimeSeconds;

  @override
  void initState() {
    super.initState();
    _sceneStartTimeSeconds = RiskReportScene.nowSeconds();
    _loadPersonalInfo();
  }

  @override
  void dispose() {
    _disposeFields(_fields);
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
      final fields = <PersonalInfoField>[];
      _salaryDayOptions.clear();
      _salaryDaySelections.clear();
      for (final json in response.states['enthrones'].listValue) {
        final field = PersonalInfoField.fromJson(json);
        if (widget._kind == _CertificationInfoKind.work &&
            field.keyName == 'passwords') {
          final options = SalaryDayGroup.parseList(json['metallurgists']);
          if (options.isNotEmpty) {
            _salaryDayOptions[field.keyName] = options;
            final selection = SalaryDaySelection.fromCurrentValue(
              options,
              field.selectedValue,
            );
            if (selection != null) {
              _salaryDaySelections[field.keyName] = selection;
              field.selectedValue = selection.submitValue;
              field.controller.text = selection.displayText;
            }
          }
        }
        if (field.keyName.isNotEmpty && field.isSupported) {
          fields.add(field);
        } else {
          field.dispose();
        }
      }
      if (!mounted) {
        _disposeFields(fields);
        return;
      }
      setState(() {
        _prompt = _firstNonEmpty(
          response.states['mourningly'].stringValue.trim(),
          _defaultPrompt,
        );
        _replaceFields(fields);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _replaceFields(<PersonalInfoField>[]);
        _isLoading = false;
      });
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
  }

  void _replaceFields(List<PersonalInfoField> fields) {
    _disposeFields(_fields);
    _fields = fields;
  }

  void _disposeFields(Iterable<PersonalInfoField> fields) {
    for (final field in fields) {
      field.dispose();
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
            _PersonalInfoHeader(
              onBack: CertificationRetentionGuard.backHandler(
                type: widget._kind == _CertificationInfoKind.work ? '3' : '2',
                productId: _productIdFromArguments(),
              ),
            ),
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
              onTap: () => _handleFieldTap(_fields[index]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleFieldTap(PersonalInfoField field) async {
    if (widget._kind == _CertificationInfoKind.work &&
        field.keyName == 'passwords') {
      await _selectSalaryDay(field);
      return;
    }
    if (field.usesAddressPicker) {
      await _selectAddress(field);
      return;
    }
    await _selectOption(field);
  }

  Future<void> _selectSalaryDay(PersonalInfoField field) async {
    final options = _salaryDayOptions[field.keyName];
    if (options == null || options.isEmpty) {
      return;
    }
    final selection = await showCertificationSalaryDaySelectionSheet(
      context: context,
      options: options,
      initialSelection: _salaryDaySelections[field.keyName],
    );
    if (selection == null || !mounted) {
      return;
    }
    setState(() {
      _salaryDaySelections[field.keyName] = selection;
      field.selectedValue = selection.submitValue;
      field.controller.text = selection.displayText;
    });
  }

  Future<void> _selectOption(PersonalInfoField field) async {
    if (!field.usesPicker || field.options.isEmpty) {
      return;
    }
    final option = await showCertificationSelectionSheet<PersonalInfoOption>(
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
      field.selectOption(option);
    });
  }

  Future<void> _selectAddress(PersonalInfoField field) async {
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
      final value = field.currentSubmitValue;
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
  const _PersonalInfoFieldView({required this.field, required this.onTap});

  final PersonalInfoField field;
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
            ? _PersonalInfoInput(field: field)
            : _PersonalInfoPicker(field: field, onTap: onTap),
      ],
    );
  }
}

class _PersonalInfoInput extends StatelessWidget {
  const _PersonalInfoInput({required this.field});

  final PersonalInfoField field;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: TextField(
        key: Key('personalInfoInput_${field.keyName}'),
        controller: field.controller,
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

  final PersonalInfoField field;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = field.displayText;
    final hasValue = field.controller.text.trim().isNotEmpty;
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
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: !hasValue
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
