import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/settings/setting_confirm_dialog.dart';
import 'package:kaibigan_loan/src/utils/screen_adapter.dart';

void main() {
  testWidgets('popup button labels use up to two lines and shrink to fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return SettingConfirmDialog(
              type: SettingConfirmDialogType.deleteAccount,
              onConfirm: () {},
            );
          },
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Delete Account'));
    expect(label.maxLines, 2);
    expect(label.style!.fontSize, lessThan(18));
    expect(tester.takeException(), isNull);
  });
}
