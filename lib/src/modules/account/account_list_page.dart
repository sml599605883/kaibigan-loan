import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assets/app_assets.dart';
import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../navigation_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../utils/screen_adapter.dart';
import '../widgets/section_title.dart';
import 'account_list_models.dart';

class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  var _isLoading = true;
  var _isSubmitting = false;
  String? _errorMessage;
  List<AccountListSection> _sections = const <AccountListSection>[];
  AccountListItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  String get _productId => _argument('geobotanists');

  String get _orderNo => _orderNoFromArguments();

  String _orderNoFromArguments() => _argument('dodgy');

  String _argument(String key) {
    final arguments = Get.arguments;
    return arguments is Map ? Json(arguments)[key].stringValue.trim() : '';
  }

  Future<void> _loadAccounts() async {
    final productId = _productId;
    final orderNo = _orderNoFromArguments();
    if (productId.isEmpty || orderNo.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = productId.isEmpty
            ? 'Missing product information'
            : 'Missing order information';
        _sections = const <AccountListSection>[];
        _selectedItem = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiClient.instance.userAccountList(
        geobotanists: productId,
      );
      final items = parseAccountListItems(response.ensureSuccess().states);
      final sections = groupAccountListItems(items);
      final mainItem = sections
          .expand((section) => section.items)
          .where((item) => item.isMain)
          .firstOrNull;
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _selectedItem = mainItem;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ApiErrorMessage.resolve(error);
        _sections = const <AccountListSection>[];
        _selectedItem = null;
      });
    }
  }

  Future<void> _confirm() async {
    final selected = _selectedItem;
    if (selected == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    await AppToast.showLoading();
    try {
      final response = await ApiClient.instance.changeOrderAccount(
        dodgy: _orderNo,
        smokehouse: selected.bindId,
      );
      final redirectUrl = response
          .ensureSuccess()
          .states['preinserting']
          .stringValue
          .trim();
      if (redirectUrl.isEmpty) {
        throw ApiBusinessException('Missing account change result url');
      }
      await AppToast.dismissLoading();
      if (mounted) NavigationHelper.back(result: redirectUrl);
    } catch (error) {
      if (!mounted) {
        await AppToast.dismissLoading();
        return;
      }
      setState(() => _isSubmitting = false);
      await AppToast.error(ApiErrorMessage.resolve(error));
    }
  }

  Future<void> _addPaymentMethod() async {
    final route = NavigationHelper.toCertificationBindCard<Object?>(
      productId: _productId,
      orderNo: _orderNo,
      isAccountChange: true,
    );
    if (route == null) {
      return;
    }
    final redirectUrl = (await route)?.toString().trim() ?? '';
    if (mounted && redirectUrl.isNotEmpty) {
      NavigationHelper.back(result: redirectUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accountPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _AccountListHeader(),
            Expanded(child: _buildContent()),
            _ConfirmButton(
              enabled: _selectedItem != null && !_isSubmitting,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accountConfirmEnabled,
        ),
      );
    }
    if (_errorMessage != null) {
      return _AccountErrorState(
        message: _errorMessage!,
        onRetry: _loadAccounts,
      );
    }
    if (_sections.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No payment methods available',
                style: TextStyle(color: AppColors.accountStateText),
              ),
              SizedBox(height: 16.h),
              _buildAddPaymentMethod(),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in _sections) ...[
            AppSectionTitle(title: section.title),
            SizedBox(height: 12.h),
            for (final item in section.items) ...[
              _AccountListCard(
                item: item,
                selected: _selectedItem?.bindId == item.bindId,
                onTap: () => setState(() => _selectedItem = item),
              ),
              SizedBox(height: 12.h),
            ],
          ],
          _buildAddPaymentMethod(),
        ],
      ),
    );
  }

  Widget _buildAddPaymentMethod() {
    return InkWell(
      key: const Key('accountAddPaymentMethod'),
      onTap: _addPaymentMethod,
      child: Image.asset(
        AppAssets.accountAddPaymentMethods,
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

class _AccountListHeader extends StatelessWidget {
  const _AccountListHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: NavigationHelper.back,
              icon: Image.asset(AppAssets.loginBack, width: 23.w, height: 20.h),
            ),
          ),
          Text(
            'Loan Application',
            style: TextStyle(
              color: AppColors.accountHeaderText,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountListCard extends StatelessWidget {
  const _AccountListCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AccountListItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '${item.providerName} ${item.displayValue}'.trim(),
      child: Material(
        color: AppColors.accountCardBackground,
        borderRadius: BorderRadius.circular(20.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('accountListItem-${item.bindId}'),
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: Key('accountCardHeader-${item.bindId}'),
                height: 60.h,
                color: AppColors.accountCardHeader,
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  children: [
                    SizedBox(
                      key: Key('accountCardLogo-${item.bindId}'),
                      width: 30.w,
                      height: 30.h,
                      child: _TypeIcon(url: item.typeIconUrl),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        item.providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.accountCardText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                    Image.asset(
                      selected
                          ? AppAssets.accountOptionSelected
                          : AppAssets.accountOptionUnselected,
                      width: 20.w,
                      height: 20.h,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 11.h),
                child: Container(
                  key: Key('accountCardReceiptPanel-${item.bindId}'),
                  padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 9.h),
                  decoration: BoxDecoration(
                    color: AppColors.accountCardPanel,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt Account',
                        style: TextStyle(
                          color: AppColors.accountCardLabelText,
                          fontSize: 12.sp,
                          height: 14 / 12,
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        item.displayValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.accountCardValueText,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          height: 24 / 20,
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
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.expand();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );
  }
}

class _AccountErrorState extends StatelessWidget {
  const _AccountErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(color: AppColors.accountStateText),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: MaterialButton(
            key: const Key('accountListConfirm'),
            color: AppColors.accountConfirmEnabled,
            disabledColor: AppColors.accountConfirmDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            onPressed: enabled ? onPressed : null,
            child: Text(
              'Confirm',
              style: TextStyle(
                color: AppColors.accountConfirmText,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
