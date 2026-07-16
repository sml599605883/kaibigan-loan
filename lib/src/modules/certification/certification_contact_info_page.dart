import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/report/risk_report_scene.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';
import '../../navigation_helper.dart';
import 'models/personal_info_option.dart';
import 'widgets/certification_prompt_banner.dart';
import 'widgets/certification_retention_guard.dart';
import 'widgets/certification_selection_sheet.dart';

class CertificationContactInfoPage extends StatefulWidget {
  const CertificationContactInfoPage({super.key});

  @override
  State<CertificationContactInfoPage> createState() =>
      _CertificationContactInfoPageState();
}

class _CertificationContactInfoPageState
    extends State<CertificationContactInfoPage> {
  static const _defaultPrompt =
      'We will protect your personal information from disclosure';

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _loadError = '';
  String _prompt = _defaultPrompt;
  List<_ContactGroup> _groups = <_ContactGroup>[];
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  late final int _sceneStartTimeSeconds;

  @override
  void initState() {
    super.initState();
    _sceneStartTimeSeconds = RiskReportScene.nowSeconds();
    _loadContactInfo();
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

  Future<void> _loadContactInfo() async {
    final productId = _productIdFromArguments();
    if (productId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    setState(() {
      _isLoading = true;
      _loadError = '';
    });
    try {
      final response = await ApiClient.instance.contactInfo(
        geobotanists: productId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _groups = response.states['backdating']['religiosities'].listValue
            .map((value) => _ContactGroup.fromJson(Json(value)))
            .where((group) => group.groupKey.isNotEmpty)
            .toList(growable: false);
        _prompt = _firstNonEmpty(
          response.states['mourningly'].stringValue.trim(),
          _defaultPrompt,
        );
        _loadError = '';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = ApiErrorMessage.resolve(error);
      setState(() {
        _isLoading = false;
        _loadError = message;
      });
      await AppToast.error(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.certificationPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _ContactInfoHeader(
              onBack: CertificationRetentionGuard.backHandler(
                type: '4',
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
                AppAssets.certificationContactProgress,
                key: const Key('contactInfoProgressImage'),
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
              ),
              onPressed:
                  _isLoading ||
                      _loadError.isNotEmpty ||
                      _groups.isEmpty ||
                      _isSubmitting
                  ? null
                  : _submit,
              child: Text(
                'Submit',
                style: TextStyle(
                  color: AppColors.certificationSubmitText,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.certificationFieldText,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(onPressed: _loadContactInfo, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_groups.isEmpty) {
      return Center(
        child: Text(
          'No emergency contacts available',
          style: TextStyle(
            color: AppColors.certificationEmptyText,
            fontSize: 14.sp,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      itemCount: _groups.length,
      itemBuilder: (context, index) => _ContactGroupView(
        index: index,
        group: _groups[index],
        onRelationshipTap: () => _selectRelationship(_groups[index]),
        onContactTap: () => _selectContact(_groups[index]),
      ),
      separatorBuilder: (_, _) => SizedBox(height: 24.h),
    );
  }

  Future<void> _selectRelationship(_ContactGroup group) async {
    final selectedValue = await showCertificationSelectionSheet<String>(
      context: context,
      options: group.relationshipOptions
          .map(
            (option) => CertificationSelectionSheetOption<String>(
              value: option.value,
              label: option.label,
              key: Key(
                'contactInfoRelationship_${group.groupKey}_${option.value}',
              ),
            ),
          )
          .toList(growable: false),
      initialValue: group.relationshipValue,
    );
    if (selectedValue == null || !mounted) {
      return;
    }
    setState(() => group.relationshipValue = selectedValue);
  }

  Future<void> _selectContact(_ContactGroup group) async {
    Contact? contact;
    try {
      contact = await _contactPicker.selectContact();
    } catch (error) {
      if (mounted) {
        await AppToast.error(ApiErrorMessage.resolve(error));
      }
      return;
    }
    if (contact == null || !mounted) {
      return;
    }
    final name = (contact.fullName ?? '').trim();
    final phone = _primaryPhone(contact);
    if (name.isEmpty && phone.isEmpty) {
      return;
    }
    setState(() {
      if (name.isNotEmpty) {
        group.name = name;
      }
      if (phone.isNotEmpty) {
        group.phone = phone;
      }
    });
  }

  String _primaryPhone(Contact contact) {
    final selectedPhone = (contact.selectedPhoneNumber ?? '').trim();
    if (selectedPhone.isNotEmpty) {
      return selectedPhone;
    }
    for (final phone in contact.phoneNumbers ?? const <String>[]) {
      if (phone.trim().isNotEmpty) {
        return phone.trim();
      }
    }
    return '';
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final productId = _productIdFromArguments();
    if (productId.isEmpty) {
      return;
    }
    final contacts = _groups
        .map(
          (group) => <String, dynamic>{
            'daybed': group.phone.trim(),
            'unwits': group.name.trim(),
            'scenarists': group.relationshipValue.trim(),
            'flashbulbs': group.groupKey,
          },
        )
        .toList(growable: false);

    setState(() => _isSubmitting = true);
    await AppToast.showLoading();
    try {
      await ApiClient.instance.saveContactInfo(
        geobotanists: productId,
        fas: Json(contacts).rawString(),
      );
      if (!mounted) {
        return;
      }
      await AppToast.dismissLoading();
      RiskReportScene.report(
        productId: productId,
        sceneType: '7',
        startTimeSeconds: _sceneStartTimeSeconds,
      );
      await NavigationHelper.continueProductDetailFlow(productId);
    } catch (error) {
      if (mounted) {
        await AppToast.error(ApiErrorMessage.resolve(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  static String _firstNonEmpty(String primary, String fallback) {
    return primary.isNotEmpty ? primary : fallback;
  }
}

class _ContactGroup {
  _ContactGroup({
    required this.groupKey,
    required this.relationshipValue,
    required this.name,
    required this.phone,
    required this.relationshipOptions,
  });

  factory _ContactGroup.fromJson(Json json) {
    final options = json['hosted'].listValue
        .map((value) => PersonalInfoOption.fromJson(Json(value)))
        .where((option) => option.label.isNotEmpty)
        .toList(growable: false);
    return _ContactGroup(
      groupKey: json['flashbulbs'].stringValue.trim(),
      relationshipValue: json['scenarists'].stringValue.trim(),
      name: json['unwits'].stringValue.trim(),
      phone: json['daybed'].stringValue.trim(),
      relationshipOptions: options,
    );
  }

  final String groupKey;
  String relationshipValue;
  String name;
  String phone;
  final List<PersonalInfoOption> relationshipOptions;

  String get relationshipLabel {
    for (final option in relationshipOptions) {
      if (option.value == relationshipValue ||
          option.label == relationshipValue) {
        return option.label;
      }
    }
    return 'Please select';
  }
}

class _ContactInfoHeader extends StatelessWidget {
  const _ContactInfoHeader({required this.onBack});

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
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactGroupView extends StatelessWidget {
  const _ContactGroupView({
    required this.index,
    required this.group,
    required this.onRelationshipTap,
    required this.onContactTap,
  });

  final int index;
  final _ContactGroup group;
  final VoidCallback onRelationshipTap;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contacts - ${index + 1}',
          style: TextStyle(
            color: AppColors.certificationSectionTitle,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          'Relationship',
          style: TextStyle(
            color: AppColors.certificationFieldLabel,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 7.h),
        GestureDetector(
          key: Key('contactInfoRelationship_${group.groupKey}'),
          behavior: HitTestBehavior.opaque,
          onTap: onRelationshipTap,
          child: _ContactFieldBox(
            height: 40,
            child: Row(
              children: [
                Expanded(child: Text(group.relationshipLabel)),
                Image.asset(
                  AppAssets.arrowRight,
                  key: Key('contactInfoRelationshipArrow_${group.groupKey}'),
                  width: 15.w,
                  height: 10.h,
                  color: AppColors.profileArrowTint,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'City You Work',
          style: TextStyle(
            color: AppColors.certificationFieldLabel,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 7.h),
        GestureDetector(
          key: Key('contactInfoContact_${group.groupKey}'),
          behavior: HitTestBehavior.opaque,
          onTap: onContactTap,
          child: _ContactFieldBox(
            height: 80,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        group.name.isEmpty
                            ? 'Please select contact'
                            : group.name,
                      ),
                      if (group.phone.isNotEmpty) SizedBox(height: 12.h),
                      if (group.phone.isNotEmpty) Text(group.phone),
                    ],
                  ),
                ),
                Image.asset(
                  AppAssets.contactPickerIcon,
                  key: Key('contactInfoPicker_${group.groupKey}'),
                  width: 22.w,
                  height: 20.h,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactFieldBox extends StatelessWidget {
  const _ContactFieldBox({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.certificationCardBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.certificationFieldBorder),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: AppColors.certificationFieldText,
          fontSize: 14.sp,
        ),
        child: child,
      ),
    );
  }
}
