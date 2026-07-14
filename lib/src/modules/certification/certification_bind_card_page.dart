import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../core/client/client_bridge.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../../core/report/risk_report_scene.dart';
import '../../core/session/session_store.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';
import 'models/bind_card_info.dart';
import 'widgets/certification_prompt_banner.dart';

typedef BindCardLivenessLauncher =
    Future<TrustDecisionLivenessResult> Function(String license);

class CertificationBindCardPage extends StatefulWidget {
  const CertificationBindCardPage({
    super.key,
    ApiClient? apiClient,
    BindCardLivenessLauncher? showTrustDecisionLiveness,
  }) : _apiClient = apiClient,
       showTrustDecisionLiveness =
           showTrustDecisionLiveness ?? _defaultShowTrustDecisionLiveness;

  final ApiClient? _apiClient;
  final BindCardLivenessLauncher showTrustDecisionLiveness;

  @override
  State<CertificationBindCardPage> createState() =>
      _CertificationBindCardPageState();
}

class _CertificationBindCardPageState extends State<CertificationBindCardPage> {
  static const _defaultHint = 'Please provide your payment method details.';
  static const _supportedSaveKeys = <String>{
    'channelCode',
    'firstName',
    'middleName',
    'lastName',
    'cardNo',
    'confirmCardNo',
  };

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, _BindCardSelection> _selections = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  BindCardInfo? _info;
  String _selectedGroupType = '';
  late final int _sceneStartTimeSeconds;

  ApiClient get _apiClient => widget._apiClient ?? ApiClient.instance;

  @override
  void initState() {
    super.initState();
    _sceneStartTimeSeconds = RiskReportScene.nowSeconds();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final productId = _productId;
    if (productId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = null;
        _info = BindCardInfo(groups: [], topHint: '', bottomHint: '');
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiClient.bankInfo(geobotanists: productId);
      final info = BindCardInfo.fromJson(response.ensureSuccess().states);
      if (!mounted) {
        return;
      }
      _initializeFormState(info);
      setState(() {
        _info = info;
        _selectedGroupType = info.groups.isEmpty ? '' : info.groups.first.type;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = ApiErrorMessage.resolve(error);
      });
    }
  }

  String get _productId {
    final arguments = Get.arguments;
    if (arguments is Map) {
      final productId = arguments['geobotanists'];
      return productId is String ? productId.trim() : '';
    }
    return '';
  }

  void _initializeFormState(BindCardInfo info) {
    for (final group in info.groups) {
      for (final field in group.fields) {
        final stateKey = _stateKey(group, field);
        if (field.fieldType == BindCardFieldType.text) {
          _controllers.putIfAbsent(
            stateKey,
            () => TextEditingController(text: field.initialValue),
          );
        } else {
          final matchedOption = _matchInitialOption(field);
          _selections.putIfAbsent(
            stateKey,
            () => _BindCardSelection(
              value: matchedOption?.value ?? field.initialValue,
              label:
                  matchedOption?.label ??
                  (field.suggestedValue.isNotEmpty
                      ? field.suggestedValue
                      : field.initialValue),
            ),
          );
        }
      }
    }
  }

  String _stateKey(BindCardGroup group, BindCardField field) =>
      '${group.type}:${field.saveKey}';

  BindCardOption? _matchInitialOption(BindCardField field) {
    final normalizedValue = field.initialValue.toLowerCase();
    final normalizedSuggestedValue = field.suggestedValue.toLowerCase();
    for (final option in field.options) {
      if (normalizedValue.isNotEmpty &&
          option.value.toLowerCase() == normalizedValue) {
        return option;
      }
      if (normalizedSuggestedValue.isNotEmpty &&
          option.label.toLowerCase() == normalizedSuggestedValue) {
        return option;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      backgroundColor: AppColors.certificationPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            const _BindCardHeader(),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: CertificationPromptBanner(
                message: info?.topHint.isNotEmpty == true
                    ? info!.topHint
                    : _defaultHint,
              ),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Image.asset(
                AppAssets.certificationBindCardProgress,
                key: const Key('bindCardProgress'),
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(height: 18.h),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: _BindCardFooter(
        hint: info?.bottomHint ?? '',
        onSubmit: _isSubmitting ? null : _submit,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.certificationEmptyText,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final info = _info;
    if (info == null || info.groups.isEmpty) {
      return Center(
        child: Text(
          'No payment methods available',
          style: TextStyle(
            color: AppColors.certificationEmptyText,
            fontSize: 14.sp,
          ),
        ),
      );
    }
    final group = info.groups.firstWhere(
      (candidate) => candidate.type == _selectedGroupType,
      orElse: () => info.groups.first,
    );
    return Column(
      children: [
        SizedBox(
          height: 36.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            scrollDirection: Axis.horizontal,
            itemCount: info.groups.length,
            separatorBuilder: (_, _) => SizedBox(width: 10.w),
            itemBuilder: (_, index) {
              final tab = info.groups[index];
              final selected = tab.type == group.type;
              return Semantics(
                button: true,
                selected: selected,
                label: tab.label,
                excludeSemantics: true,
                child: GestureDetector(
                  key: Key('bindCardTab_${tab.type}'),
                  onTap: () => setState(() => _selectedGroupType = tab.type),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.certificationTabActive
                          : AppColors.certificationTabInactive,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: Center(
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.certificationTabActiveText
                                : AppColors.certificationTabInactiveText,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 18.h),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
            child: Column(
              children: [
                for (final field in group.fields) ...[
                  _BindCardField(
                    field: field,
                    controller: _controllers[_stateKey(group, field)],
                    selection: _selections[_stateKey(group, field)],
                    onPickerTap: () => _selectOption(group, field),
                  ),
                  SizedBox(height: 14.h),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectOption(BindCardGroup group, BindCardField field) async {
    final pageContext = context;
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!pageContext.mounted) {
      return;
    }
    if (field.options.isEmpty) {
      return;
    }
    final stateKey = _stateKey(group, field);
    final option = await _showOptionSheet(
      pageContext,
      field.options,
      _selections[stateKey]?.value,
    );
    if (option == null || !mounted) {
      return;
    }
    setState(() {
      _selections[stateKey] = _BindCardSelection(
        value: option.value,
        label: option.label,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final info = _info;
    if (info == null || info.groups.isEmpty) {
      return;
    }
    final group = info.groups.firstWhere(
      (candidate) => candidate.type == _selectedGroupType,
      orElse: () => info.groups.first,
    );
    final values = <String, String>{};
    for (final field in group.fields) {
      if (!_supportedSaveKeys.contains(field.saveKey)) {
        continue;
      }
      final value = _submitValue(group, field);
      values[field.saveKey] = value;
      if (field.isRequired && value.isEmpty) {
        final placeholder = field.placeholder.trim();
        await AppToast.show(
          placeholder.isNotEmpty
              ? placeholder
              : 'Please complete ${field.label.trim()}',
        );
        return;
      }
    }
    if (values.containsKey('cardNo') &&
        values.containsKey('confirmCardNo') &&
        values['cardNo'] != values['confirmCardNo']) {
      await AppToast.show('The two account entries do not match');
      return;
    }

    setState(() => _isSubmitting = true);
    var ownsLoading = false;
    try {
      await AppToast.showLoading();
      ownsLoading = true;
      final productId = _productId;
      final response = await _saveBankInfo(
        productId: productId,
        groupType: group.type,
        values: values,
      );
      if (!mounted) {
        return;
      }
      if (response.code == 20000) {
        ownsLoading = false;
        await _completeLivenessVerification(
          productId: productId,
          groupType: group.type,
          values: values,
        );
        return;
      }
      response.ensureSuccess();
      ownsLoading = false;
      await _completeNormalSuccess(productId);
    } catch (error) {
      if (mounted) {
        await AppToast.error(ApiErrorMessage.resolve(error));
        ownsLoading = false;
      }
    } finally {
      if (ownsLoading) {
        await AppToast.dismissLoading();
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<ApiResponse> _saveBankInfo({
    required String productId,
    required String groupType,
    required Map<String, String> values,
    String clevises = '',
    String scolloped = '',
    String arrests = '',
  }) {
    return _apiClient.saveBankInfo(
      geobotanists: productId,
      heirship: groupType,
      bladers: values['channelCode'] ?? '',
      zips: values['firstName'] ?? '',
      acreage: values['middleName'] ?? '',
      coinable: values['lastName'] ?? '',
      flabby: values['cardNo'] ?? '',
      rapt: values['confirmCardNo'] ?? '',
      clevises: clevises,
      scolloped: scolloped,
      arrests: arrests,
    );
  }

  Future<void> _completeLivenessVerification({
    required String productId,
    required String groupType,
    required Map<String, String> values,
  }) async {
    var ownsLoading = true;
    try {
      final orderNo = Get.isRegistered<SessionStore>()
          ? SessionStore.instance.productDetailCache()?.orderNo.trim() ?? ''
          : '';
      if (orderNo.isEmpty) {
        await AppToast.error(
          'Missing order information for liveness verification',
        );
        ownsLoading = false;
        return;
      }
      final tokenResponse = await _apiClient.getFaceToken(
        dodgy: orderNo,
        commensurate: '1',
      );
      if (!mounted) {
        return;
      }
      final token = _BindCardFaceToken.fromResponse(
        tokenResponse.ensureSuccess(),
      );
      if (token.code != '200' || token.license.isEmpty) {
        await AppToast.error(
          token.message.isNotEmpty ? token.message : 'Failed to get face token',
        );
        ownsLoading = false;
        return;
      }
      if (token.faceType != '7') {
        await AppToast.error('Unsupported liveness verification type');
        ownsLoading = false;
        return;
      }

      await AppToast.dismissLoading();
      ownsLoading = false;
      final result = await widget.showTrustDecisionLiveness(token.license);
      if (!mounted) {
        return;
      }
      if (!result.success) {
        await AppToast.error(
          result.message.trim().isNotEmpty
              ? result.message
              : 'Liveness verification failed',
        );
        return;
      }
      final livenessId = result.livenessId.trim();
      if (livenessId.isEmpty) {
        await AppToast.error('Liveness verification failed');
        return;
      }

      await AppToast.showLoading();
      ownsLoading = true;
      final response = await _saveBankInfo(
        productId: productId,
        groupType: groupType,
        values: values,
        clevises: '7',
        scolloped: livenessId,
        arrests: token.license,
      );
      if (!mounted) {
        return;
      }
      if (response.code == 20000) {
        await AppToast.error('Liveness verification was not accepted');
        ownsLoading = false;
        return;
      }
      response.ensureSuccess();
      ownsLoading = false;
      await _completeNormalSuccess(productId);
    } catch (error) {
      if (mounted) {
        await AppToast.error(ApiErrorMessage.resolve(error));
        ownsLoading = false;
      }
    } finally {
      if (ownsLoading) {
        await AppToast.dismissLoading();
      }
    }
  }

  Future<void> _completeNormalSuccess(String productId) async {
    await AppToast.dismissLoading();
    if (!mounted) {
      return;
    }
    RiskReportScene.report(
      productId: productId,
      sceneType: '8',
      startTimeSeconds: _sceneStartTimeSeconds,
    );
    await NavigationHelper.continueProductDetailFlow(productId);
  }

  String _submitValue(BindCardGroup group, BindCardField field) {
    final stateKey = _stateKey(group, field);
    if (field.fieldType == BindCardFieldType.enumeration) {
      return _selections[stateKey]?.value.trim() ?? '';
    }
    return _controllers[stateKey]?.text.trim() ?? '';
  }
}

class _BindCardFaceToken {
  const _BindCardFaceToken({
    required this.code,
    required this.license,
    required this.faceType,
    required this.message,
  });

  factory _BindCardFaceToken.fromResponse(dynamic response) {
    final states = response.states;
    return _BindCardFaceToken(
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

class _BindCardHeader extends StatelessWidget {
  const _BindCardHeader();

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

class _BindCardField extends StatelessWidget {
  const _BindCardField({
    required this.field,
    required this.controller,
    required this.selection,
    required this.onPickerTap,
  });

  final BindCardField field;
  final TextEditingController? controller;
  final _BindCardSelection? selection;
  final VoidCallback onPickerTap;

  @override
  Widget build(BuildContext context) {
    final isText = field.fieldType == BindCardFieldType.text;
    final displayText = selection?.label.isNotEmpty == true
        ? selection!.label
        : field.placeholder;
    return Column(
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
                                color: selection?.label.isNotEmpty == true
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
    );
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
}

OutlineInputBorder _fieldBorder() => OutlineInputBorder(
  borderRadius: BorderRadius.circular(20.r),
  borderSide: const BorderSide(color: AppColors.certificationFieldBorder),
);

class _BindCardFooter extends StatelessWidget {
  const _BindCardFooter({required this.hint, required this.onSubmit});

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

class _BindCardSelection {
  const _BindCardSelection({required this.value, required this.label});

  final String value;
  final String label;
}

Future<BindCardOption?> _showOptionSheet(
  BuildContext context,
  List<BindCardOption> options,
  String? initialValue,
) {
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
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 15.h),
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
                      onTap: () => setState(() => _selected = option),
                      child: Container(
                        height: 46.h,
                        color: selected ? AppColors.uploadMethodSelected : null,
                        child: Row(
                          children: [
                            SizedBox(width: 12.w),
                            _BusinessLogo(url: option.logoUrl),
                            SizedBox(width: 12.w),
                            Expanded(
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
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
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
