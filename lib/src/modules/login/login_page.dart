import 'dart:async';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

import '../../assets/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/screen_adapter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  Timer? _countdownTimer;
  bool _agreementAccepted = true;
  bool _requestingCode = false;
  bool _loggingIn = false;
  int _countdownSeconds = 0;

  bool get _canSubmit {
    return _phoneController.text.isNotEmpty &&
        _codeController.text.isNotEmpty &&
        _agreementAccepted;
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onInputChanged);
    _codeController.addListener(_onCodeChanged);
    _loadRememberedPhone();
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_onInputChanged)
      ..dispose();
    _codeController
      ..removeListener(_onCodeChanged)
      ..dispose();
    _codeFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  Future<void> _loadRememberedPhone() async {
    final phone = await SessionStore.instance.phone();
    if (!mounted || phone.isEmpty || _phoneController.text.isNotEmpty) {
      return;
    }
    _phoneController.value = TextEditingValue(
      text: phone,
      selection: TextSelection.collapsed(offset: phone.length),
    );
  }

  void _toggleAgreement() {
    setState(() {
      _agreementAccepted = !_agreementAccepted;
    });
  }

  void _onCodeChanged() {
    _onInputChanged();
    if (_codeController.text.length == 6) {
      _loginWithSmsCode();
    }
  }

  Future<void> _requestSmsCode() async {
    if (_requestingCode || _countdownSeconds > 0) {
      return;
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      return;
    }
    setState(() {
      _requestingCode = true;
    });
    var shouldDismissLoading = true;
    try {
      await AppToast.showLoading();
      final response = await ApiClient.instance.sendSmsCode(
        potline: phone,
        waterbird: 'sms',
      );
      if (!mounted) {
        return;
      }
      await AppToast.show(response.message);
      shouldDismissLoading = false;
      _codeFocusNode.requestFocus();
      _startCountdown();
    } catch (error) {
      await AppToast.show(ApiErrorMessage.resolve(error));
      shouldDismissLoading = false;
    } finally {
      if (shouldDismissLoading) {
        await AppToast.dismissLoading();
      }
      if (mounted) {
        setState(() {
          _requestingCode = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _countdownSeconds = 0;
        });
        return;
      }
      setState(() {
        _countdownSeconds--;
      });
    });
  }

  Future<void> _loginWithSmsCode() async {
    if (_loggingIn) {
      return;
    }
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (phone.isEmpty || code.length != 6) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _loggingIn = true;
    var shouldDismissLoading = true;
    try {
      await AppToast.showLoading();
      final response = await ApiClient.instance.smsCodeLogin(
        threadier: phone,
        informal: code,
      );
      final bungee = response.states['bungee'].stringValue;
      await SessionStore.instance.saveBungee(bungee);
      await SessionStore.instance.savePhone(phone);
      await SessionStore.instance.setLoggedIn(true);
      log('sms code login success');
      if (mounted) {
        Get.back<void>();
      }
    } catch (error) {
      await AppToast.show(ApiErrorMessage.resolve(error));
      shouldDismissLoading = false;
      _codeController.clear();
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    } finally {
      if (shouldDismissLoading) {
        await AppToast.dismissLoading();
      }
      _loggingIn = false;
    }
  }

  void _openPrivacyPolicy() {
    log('Privacy Policy tapped');
  }

  void _goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.of(context);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 64.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20.w),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _goBack,
                  child: Padding(
                    padding: 4.insetsAll,
                    child: Image.asset(
                      AppAssets.loginBack,
                      width: 23.w,
                      height: 20.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 80.h),
            _LoginPanel(
              phoneController: _phoneController,
              codeController: _codeController,
              codeFocusNode: _codeFocusNode,
              canSubmit: _canSubmit,
              countdownSeconds: _countdownSeconds,
              requestingCode: _requestingCode,
              onGetCode: _requestSmsCode,
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 36.h,
          padding: EdgeInsets.fromLTRB(37.w, 0, 37.w, 0),
          child: _AgreementRow(
            accepted: _agreementAccepted,
            onTap: _toggleAgreement,
            onPolicyTap: _openPrivacyPolicy,
          ),
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.phoneController,
    required this.codeController,
    required this.codeFocusNode,
    required this.canSubmit,
    required this.countdownSeconds,
    required this.requestingCode,
    required this.onGetCode,
  });

  final TextEditingController phoneController;
  final TextEditingController codeController;
  final FocusNode codeFocusNode;
  final bool canSubmit;
  final int countdownSeconds;
  final bool requestingCode;
  final VoidCallback onGetCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 337.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 0),
      decoration: BoxDecoration(
        color: AppColors.loginPanel,
        borderRadius: 20.radiusAll,
        border: Border.all(color: AppColors.loginPanelBorder, width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 58.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi!  Welcome',
                  style: TextStyle(
                    color: AppColors.loginTitleText,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    height: 24 / 20,
                  ),
                ),
                SizedBox(height: 24.h),
                _PhoneInput(controller: phoneController),
                SizedBox(height: 19.h),
                _CodeInput(
                  controller: codeController,
                  focusNode: codeFocusNode,
                  countdownSeconds: countdownSeconds,
                  requestingCode: requestingCode,
                  onGetCode: onGetCode,
                ),
                SizedBox(height: 40.h),
                _SubmitButton(enabled: canSubmit),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 96.w,
                height: 96.w,
                child: Transform.translate(
                  offset: Offset(0, -58.h),
                  child: ClipOval(
                    child: Image.asset(AppAssets.loginLogo, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneInput extends StatelessWidget {
  const _PhoneInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      padding: EdgeInsets.fromLTRB(12.w, 0, 18.w, 0),
      decoration: BoxDecoration(
        color: AppColors.loginFieldBackground,
        borderRadius: 20.radiusAll,
      ),
      child: Row(
        children: [
          Text(
            '+63',
            style: TextStyle(
              color: AppColors.loginInputText,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 10.w),
          Container(width: 1.w, height: 21.h, color: AppColors.loginDivider),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              key: const Key('loginPhoneField'),
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.loginInputText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Please fill in your phone number',
                hintStyle: TextStyle(
                  color: AppColors.loginPlaceholderText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeInput extends StatelessWidget {
  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.countdownSeconds,
    required this.requestingCode,
    required this.onGetCode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int countdownSeconds;
  final bool requestingCode;
  final VoidCallback onGetCode;

  @override
  Widget build(BuildContext context) {
    final hasCode = controller.text.isNotEmpty;
    final countingDown = countdownSeconds > 0;
    final getCodeText = countingDown ? '${countdownSeconds}s' : 'Get Code';

    return Container(
      height: 54.h,
      padding: EdgeInsets.fromLTRB(10.w, 0, 11.w, 0),
      decoration: BoxDecoration(
        color: AppColors.loginFieldBackground,
        borderRadius: 20.radiusAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('loginCodeField'),
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.loginInputText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Send SMS verification code',
                hintStyle: TextStyle(
                  color: AppColors.loginPlaceholderText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Container(width: 1.w, height: 21.h, color: AppColors.loginDivider),
          SizedBox(width: 10.w),
          GestureDetector(
            key: const Key('loginGetCodeButton'),
            behavior: HitTestBehavior.opaque,
            onTap: countingDown || requestingCode ? null : onGetCode,
            child: SizedBox(
              width: 75.w,
              child: Text(
                getCodeText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasCode || countingDown
                      ? AppColors.loginPlaceholderText
                      : AppColors.loginInputText,
                  fontSize: 14.sp,
                  fontWeight: hasCode || countingDown
                      ? FontWeight.w400
                      : FontWeight.w700,
                  height: 17 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () {} : null,
        child: DecoratedBox(
          key: const Key('loginSubmitDecoration'),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.loginButtonEnabled
                : AppColors.loginButtonDisabled,
            borderRadius: 25.radiusAll,
          ),
          child: SizedBox(
            height: 50.h,
            child: Center(
              child: Text(
                "Let's Go",
                style: TextStyle(
                  color: enabled
                      ? AppColors.loginTitleText
                      : AppColors.loginAgreementText,
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
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.accepted,
    required this.onTap,
    required this.onPolicyTap,
  });

  final bool accepted;
  final VoidCallback onTap;
  final VoidCallback onPolicyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: const Key('loginAgreementToggle'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 24.w,
            // height: 36.h,
            child: Align(
              alignment: Alignment.topLeft,
              child: accepted
                  ? Image.asset(
                      key: const Key('loginAgreementChecked'),
                      AppAssets.loginAgreementChecked,
                      width: 16.w,
                      height: 16.w,
                    )
                  : Container(
                      key: const Key('loginAgreementUnchecked'),
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.loginAgreementText,
                          width: 1,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppColors.loginAgreementText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
              children: [
                const TextSpan(text: 'I have read and agree to the '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: AppColors.loginAgreementLink,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onPolicyTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
