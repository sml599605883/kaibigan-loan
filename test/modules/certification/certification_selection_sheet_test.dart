import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_selection_sheet.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';

void main() {
  testWidgets('selects an option and returns it only after confirmation', (
    tester,
  ) async {
    String? result;

    await _pumpLauncher(
      tester,
      onPressed: (context) async {
        result = await showCertificationSelectionSheet<String>(
          context: context,
          options: const [
            CertificationSelectionSheetOption(
              value: 'a',
              label: 'Option A',
              key: Key('option-a'),
            ),
            CertificationSelectionSheetOption(
              value: 'b',
              label: 'Option B',
              key: Key('option-b'),
            ),
          ],
          initialValue: 'a',
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CertificationSelectionSheet<String>), findsOneWidget);
    expect(
      _optionColor(tester, const Key('option-a')),
      AppColors.uploadMethodSelected,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('option-a')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Option B'));
    await tester.pump();

    expect(result, isNull);
    expect(
      _optionColor(tester, const Key('option-b')),
      AppColors.uploadMethodSelected,
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, 'b');
  });

  testWidgets('cancel dismisses without returning the temporary selection', (
    tester,
  ) async {
    String? result = 'unchanged';

    await _pumpLauncher(
      tester,
      onPressed: (context) async {
        final selected = await showCertificationSelectionSheet<String>(
          context: context,
          options: const [
            CertificationSelectionSheetOption(value: 'a', label: 'Option A'),
          ],
        );
        if (selected != null) {
          result = selected;
        }
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option A'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, 'unchanged');
    expect(find.byType(CertificationSelectionSheet<String>), findsNothing);
  });

  testWidgets('renders an optional icon asset', (tester) async {
    await _pumpLauncher(
      tester,
      onPressed: (context) => showCertificationSelectionSheet<String>(
        context: context,
        options: const [
          CertificationSelectionSheetOption(
            value: 'camera',
            label: 'Camera',
            iconAsset: AppAssets.certificationUploadCamera,
            key: Key('camera-option'),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('camera-option')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (image.image as AssetImage).assetName,
      AppAssets.certificationUploadCamera,
    );
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onPressed,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => onPressed(context),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Color? _optionColor(WidgetTester tester, Key key) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
  );
  return (decoratedBox.decoration as BoxDecoration).color;
}
