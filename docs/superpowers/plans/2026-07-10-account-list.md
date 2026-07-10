# Account List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Lanhu payment-account list, load bound accounts for a product, and submit the selected account for an order.

**Architecture:** A compact immutable account model handles documented-field parsing and grouping. `AccountListPage` owns API loading, selection, submit, retry, and loading states. `NavigationHelper` only validates and forwards route arguments.

**Tech Stack:** Flutter, GetX, `ApiClient`, `Json`, `AppToast`, `flutter_test`.

---

### Task 1: Account Model And Parsing

**Files:**
- Create: `lib/src/modules/account/account_list_models.dart`
- Test: `test/modules/account/account_list_models_test.dart`

- [ ] **Step 1: Write the failing parser test**

```dart
test('parses documented account fields and groups known types', () {
  final accounts = parseAccountListItems(Json({'religiosities': [
    {'smokehouse': 'bind-1', 'overdoer': 'Bank', 'dendron': 'https://example.test/bdo.png', 'postaccident': 'BDO', 'benefits': '5490163575561234', 'uptime': '1'},
  ]}));

  expect(accounts.single.bindId, 'bind-1');
  expect(accounts.single.isMain, isTrue);
  expect(groupAccountListItems(accounts).single.title, 'Bank');
});
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/modules/account/account_list_models_test.dart`

Expected: FAIL because the model library does not exist.

- [ ] **Step 3: Implement the minimal model**

```dart
class AccountListItem {
  const AccountListItem({required this.bindId, required this.typeName, required this.typeIconUrl, required this.providerName, required this.displayValue, required this.isMain});

  factory AccountListItem.fromJson(Json json) => AccountListItem(
    bindId: json['smokehouse'].stringValue,
    typeName: json['overdoer'].stringValue,
    typeIconUrl: json['dendron'].stringValue,
    providerName: json['postaccident'].stringValue,
    displayValue: json['benefits'].stringValue,
    isMain: json['uptime'].boolValue,
  );
}
```

Parse `states['religiosities']`, discard empty `smokehouse`, and group Bank, E-wallet, and Cash Pickup first; append every other non-empty type as a server-named group.

- [ ] **Step 4: Verify GREEN**

Run: `flutter test test/modules/account/account_list_models_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

Run: `git add lib/src/modules/account/account_list_models.dart test/modules/account/account_list_models_test.dart && git commit -m "feat: add account list model"`

### Task 2: Assets, Route, And Navigation

**Files:**
- Create: `assets/account_option_selected.png`
- Create: `assets/account_option_unselected.png`
- Create: `assets/account_add_payment_methods.png`
- Modify: `lib/src/assets/app_assets.dart`
- Modify: `lib/src/app_routes.dart`
- Modify: `lib/src/navigation_helper.dart`
- Test: `test/navigation_helper_test.dart`

- [ ] **Step 1: Write the failing route-helper test**

```dart
testWidgets('pushes account list with product and order arguments', (tester) async {
  await _pumpRoutes(tester);
  NavigationHelper.toAccountList<void>(productId: 'product-1', orderNo: 'ORDER001');
  await tester.pumpAndSettle();

  expect(Get.currentRoute, AppRoutes.accountList);
  expect(Get.arguments, {'geobotanists': 'product-1', 'dodgy': 'ORDER001'});
});
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/navigation_helper_test.dart --plain-name "pushes account list with product and order arguments"`

Expected: FAIL because `toAccountList` and `AppRoutes.accountList` do not exist.

- [ ] **Step 3: Implement asset and route plumbing**

Move the three raw files without resampling to `assets/account_option_selected.png`, `assets/account_option_unselected.png`, and `assets/account_add_payment_methods.png`, then remove the empty raw directory. Add their `AppAssets` constants. Register `AppRoutes.accountList` and `AccountListPage`; add `toAccountList` requiring trimmed non-empty `productId` and `orderNo`, and a `toNamed` case.

- [ ] **Step 4: Verify GREEN**

Run: `flutter test test/navigation_helper_test.dart --plain-name "pushes account list with product and order arguments"`

Expected: PASS.

- [ ] **Step 5: Commit**

Run: `git add assets lib/src/assets/app_assets.dart lib/src/app_routes.dart lib/src/navigation_helper.dart test/navigation_helper_test.dart && git commit -m "feat: add account list route"`

### Task 3: Page, States, And Submission

**Files:**
- Create: `lib/src/modules/account/account_list_page.dart`
- Modify: `lib/src/theme/app_colors.dart`
- Test: `test/modules/account/account_list_page_test.dart`

- [ ] **Step 1: Write the failing initial-load test**

```dart
testWidgets('loads accounts and selects the main account', (tester) async {
  apiClient.accountListStates = Json({'religiosities': [
    {'smokehouse': 'bind-1', 'overdoer': 'Bank', 'postaccident': 'BDO', 'benefits': '5490163575561234', 'uptime': '1'},
  ]});
  await _pumpAccountList(tester, arguments: {'geobotanists': 'product-1', 'dodgy': 'ORDER001'});
  await tester.pumpAndSettle();

  expect(apiClient.productIds, ['product-1']);
  expect(find.text('BDO'), findsOneWidget);
  expect(find.byKey(const Key('accountListConfirm')), findsOneWidget);
});
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/modules/account/account_list_page_test.dart --plain-name "loads accounts and selects the main account"`

Expected: FAIL because `AccountListPage` does not exist.

- [ ] **Step 3: Implement visual and load states**

Add account-list color tokens for page, blue card, yellow content panel, warning text, add-button fill/border, and confirm text. Implement `AccountListPage` with a `SafeArea`, scrollable content, fixed Confirm region, back action, `AppSectionTitle` groups, selected/unselected supplied assets, and disabled add-payment visual. Call `userAccountList(geobotanists:)`; display progress, retryable API error, or empty state; initially select the first main account.

- [ ] **Step 4: Verify GREEN**

Run: `flutter test test/modules/account/account_list_page_test.dart --plain-name "loads accounts and selects the main account"`

Expected: PASS.

- [ ] **Step 5: Write failing submit tests**

```dart
testWidgets('submits the selected bind ID for the current order', (tester) async {
  await _pumpAccountList(tester, arguments: {'geobotanists': 'product-1', 'dodgy': 'ORDER001'});
  await tester.pumpAndSettle();
  await tester.tap(find.text('GCash'));
  await tester.tap(find.byKey(const Key('accountListConfirm')));
  await tester.pumpAndSettle();

  expect(apiClient.changeRequests, [{'dodgy': 'ORDER001', 'smokehouse': 'bind-2'}]);
});
```

Add a test asserting a submit exception preserves the selection, re-enables Confirm, and displays the resolved failure.

- [ ] **Step 6: Verify RED**

Run: `flutter test test/modules/account/account_list_page_test.dart --plain-name "submits the selected bind ID for the current order"`

Expected: FAIL because confirm behavior is absent.

- [ ] **Step 7: Implement selection and submission**

On card tap set `_selected`. On Confirm, reject missing order/selection or duplicate submit; call `AppToast.showLoading`, then `changeOrderAccount(dodgy:, smokehouse:)`. On success dismiss loading, show a non-empty server message, and return the selected model through `NavigationHelper.back`. On failure dismiss loading, keep the selection, and call `AppToast.error(ApiErrorMessage.resolve(error))`.

- [ ] **Step 8: Verify GREEN**

Run: `flutter test test/modules/account/account_list_page_test.dart`

Expected: PASS.

- [ ] **Step 9: Commit**

Run: `git add lib/src/modules/account/account_list_page.dart lib/src/theme/app_colors.dart test/modules/account/account_list_page_test.dart && git commit -m "feat: add account selection page"`

### Task 4: Integrated Verification

**Files:**
- Verify: `lib/src/modules/account/account_list_models.dart`
- Verify: `lib/src/modules/account/account_list_page.dart`
- Verify: `lib/src/app_routes.dart`
- Verify: `lib/src/navigation_helper.dart`
- Verify: `test/modules/account/account_list_models_test.dart`
- Verify: `test/modules/account/account_list_page_test.dart`
- Verify: `test/navigation_helper_test.dart`

- [ ] **Step 1: Format changed code**

Run: `dart format lib/src/modules/account lib/src/assets/app_assets.dart lib/src/app_routes.dart lib/src/navigation_helper.dart lib/src/theme/app_colors.dart test/modules/account test/navigation_helper_test.dart`

Expected: formatter completes without errors.

- [ ] **Step 2: Run focused tests**

Run: `flutter test test/modules/account test/navigation_helper_test.dart`

Expected: PASS with no failures.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`

Expected: `No issues found!`.

- [ ] **Step 4: Inspect final worktree**

Run: `git diff HEAD --check && git status --short`

Expected: no whitespace errors; the raw asset folder is gone and only account-list work remains.
