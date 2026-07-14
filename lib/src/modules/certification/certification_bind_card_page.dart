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
import 'widgets/certification_bind_card_form_widgets.dart';
import 'widgets/certification_bind_card_option_sheet.dart';
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

  final Map<String, FocusNode> _focusNodes = {};
  final Set<String> _dismissedSuggestionKeys = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  BindCardInfo? _info;
  String _selectedGroupType = '';
  String? _activeSuggestionKey;
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
    _disposeFormState();
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
        info.dispose();
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
    _disposeFormState();
    for (final group in info.groups) {
      for (final field in group.fields) {
        final stateKey = _stateKey(group, field);
        if (field.fieldType == BindCardFieldType.text) {
          final focusNode = FocusNode();
          field.controller.addListener(_updateActiveSuggestion);
          focusNode.addListener(_updateActiveSuggestion);
          _focusNodes[stateKey] = focusNode;
        }
      }
    }
  }

  void _disposeFormState() {
    final info = _info;
    if (info != null) {
      for (final group in info.groups) {
        for (final field in group.fields) {
          if (field.fieldType == BindCardFieldType.text) {
            field.controller.removeListener(_updateActiveSuggestion);
          }
        }
      }
      info.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.removeListener(_updateActiveSuggestion);
      focusNode.dispose();
    }
    _focusNodes.clear();
    _dismissedSuggestionKeys.clear();
    _activeSuggestionKey = null;
  }

  String _stateKey(BindCardGroup group, BindCardField field) =>
      '${group.type}:${field.saveKey}';

  void _updateActiveSuggestion() {
    if (!mounted) {
      return;
    }
    final info = _info;
    if (info == null) {
      return;
    }
    for (final group in info.groups) {
      for (final field in group.fields) {
        if (field.fieldType != BindCardFieldType.text) {
          continue;
        }
        final stateKey = _stateKey(group, field);
        if (field.controller.text.trim().isNotEmpty) {
          _dismissedSuggestionKeys.remove(stateKey);
        }
      }
    }

    String? nextKey;
    final selectedGroup = info.groups.where(
      (group) => group.type == _selectedGroupType,
    );
    if (selectedGroup.isNotEmpty) {
      for (final field in selectedGroup.first.fields) {
        if (field.fieldType != BindCardFieldType.text) {
          continue;
        }
        final stateKey = _stateKey(selectedGroup.first, field);
        final focusNode = _focusNodes[stateKey];
        if (focusNode?.hasFocus != true ||
            field.controller.text.trim().isNotEmpty ||
            field.suggestedValue.trim().isEmpty ||
            _dismissedSuggestionKeys.contains(stateKey)) {
          continue;
        }
        nextKey = stateKey;
        break;
      }
    }
    if (_activeSuggestionKey == nextKey) {
      return;
    }
    setState(() => _activeSuggestionKey = nextKey);
  }

  void _dismissActiveSuggestion() {
    final stateKey = _activeSuggestionKey;
    if (stateKey == null) {
      return;
    }
    setState(() {
      _dismissedSuggestionKeys.add(stateKey);
      _activeSuggestionKey = null;
    });
  }

  void _applySuggestions(BindCardGroup group) {
    FocusScope.of(context).unfocus();
    for (final field in group.fields) {
      if (field.fieldType != BindCardFieldType.text) {
        continue;
      }
      final suggestion = field.suggestedValue.trim();
      if (field.controller.text.trim().isNotEmpty || suggestion.isEmpty) {
        continue;
      }
      field.controller.text = suggestion;
    }
    if (mounted) {
      setState(() => _activeSuggestionKey = null);
    }
  }

  void _selectGroup(String groupType) {
    if (_selectedGroupType == groupType) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedGroupType = groupType;
      _activeSuggestionKey = null;
    });
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
            const CertificationBindCardHeader(),
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
      bottomNavigationBar: CertificationBindCardFooter(
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
                  onTap: () => _selectGroup(tab.type),
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
                  CertificationBindCardField(
                    field: field,
                    controller: field.controller,
                    focusNode: _focusNodes[_stateKey(group, field)],
                    selectionLabel: field.controller.text,
                    hasSelection: field.currentSubmitValue.isNotEmpty,
                    onPickerTap: () => _selectOption(field),
                    showSuggestion:
                        _activeSuggestionKey == _stateKey(group, field),
                    onSuggestionTap: () => _applySuggestions(group),
                    onSuggestionClose: _dismissActiveSuggestion,
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

  Future<void> _selectOption(BindCardField field) async {
    final pageContext = context;
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!pageContext.mounted) {
      return;
    }
    if (field.options.isEmpty) {
      return;
    }
    final option = await showCertificationBindCardOptionSheet(
      pageContext,
      options: field.options,
      initialValue: field.currentSubmitValue,
    );
    if (option == null || !mounted) {
      return;
    }
    setState(() {
      field.selectOption(option);
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
      final value = field.currentSubmitValue;
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
      bladers: values['bladers'] ?? '',
      zips: values['zips'] ?? '',
      acreage: values['acreage'] ?? '',
      coinable: values['coinable'] ?? '',
      flabby: values['flabby'] ?? '',
      rapt: values['rapt'] ?? '',
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
