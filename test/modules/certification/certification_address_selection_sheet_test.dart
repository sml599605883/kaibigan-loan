import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/certification/models/address_node.dart';
import 'package:kaibigan_loan/src/modules/certification/models/address_option.dart';
import 'package:kaibigan_loan/src/modules/certification/models/address_selection.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_address_selection_sheet.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';

void main() {
  test('parses current-project address fields recursively', () {
    final options = AddressOption.parseList(
      Json({
        'religiosities': [
          {
            'griding': 'region-1',
            'unwits': 'Region I',
            'carburetor': [
              {
                'griding': 'province-1',
                'unwits': 'Pangasinan',
                'carburetor': [
                  {'griding': 'municipality-1', 'unwits': 'Alcala'},
                ],
              },
            ],
          },
          {'griding': 'empty', 'unwits': ''},
        ],
      }),
    );

    expect(options, hasLength(1));
    expect(options.single.addressId, 'region-1');
    expect(options.single.label, 'Region I');
    expect(options.single.children.single.addressId, 'province-1');
    expect(options.single.children.single.label, 'Pangasinan');
    expect(
      options.single.children.single.children.single.addressId,
      'municipality-1',
    );
    expect(options.single.children.single.children.single.label, 'Alcala');
  });

  test('keeps a labeled root when the API branch has no children', () {
    final options = AddressOption.parseList(
      Json({
        'religiosities': [
          {'griding': 'region-1', 'unwits': 'Region I'},
        ],
      }),
    );

    expect(options.single.label, 'Region I');
    expect(options.single.children, isEmpty);
  });

  testWidgets('walks through three address levels and returns joined labels', (
    tester,
  ) async {
    AddressSelection? result;
    await _pumpLauncher(
      tester,
      options: _threeLevelOptions,
      onResult: (selection) => result = selection,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result?.label, 'Region I-Pangasinan-Alcala');
    expect(result?.value, 'Region I-Pangasinan-Alcala');
  });

  testWidgets('finishes at province when municipality children are empty', (
    tester,
  ) async {
    AddressSelection? result;
    await _pumpLauncher(
      tester,
      options: _twoLevelOptions,
      onResult: (selection) => result = selection,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result?.value, 'Region I-Pangasinan');
  });

  testWidgets('matches Lanhu panel and active selection styling', (
    tester,
  ) async {
    await _pumpLauncher(tester, options: _threeLevelOptions);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final barrier = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .last;
    expect(barrier.color, AppColors.addressSheetBarrier);
    expect(
      tester.getSize(find.byKey(const Key('certificationAddressSheet'))),
      const Size(345, 393),
    );
    expect(
      _decorationColor(tester, const Key('addressSegmentRegion')),
      AppColors.addressSheetSegmentActive,
    );
    expect(
      _decorationColor(tester, const Key('addressOption_region-1')),
      AppColors.addressSheetSelectedRow,
    );
    expect(
      tester.getSize(find.byKey(const Key('addressActionButtons'))).width,
      314,
    );
    expect(tester.getSize(find.text('Cancel')).height, lessThanOrEqualTo(22));
  });

  testWidgets('returns to region and clears later progress', (tester) async {
    await _pumpLauncher(tester, options: _threeLevelOptions);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addressSegmentRegion')));
    await tester.pumpAndSettle();

    expect(
      _decorationColor(tester, const Key('addressSegmentRegion')),
      AppColors.addressSheetSegmentActive,
    );
    expect(find.text('Province'), findsOneWidget);
    expect(find.text('Municipality'), findsOneWidget);
  });

  testWidgets('cancel returns null and reopening starts at region', (
    tester,
  ) async {
    AddressSelection? result;
    await _pumpLauncher(
      tester,
      options: _threeLevelOptions,
      onResult: (selection) => result = selection,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(
      _decorationColor(tester, const Key('addressSegmentRegion')),
      AppColors.addressSheetSegmentActive,
    );
  });

  testWidgets('does not restore input focus after closing', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                TextButton(
                  onPressed: () => showCertificationAddressSelectionSheet(
                    context: context,
                    options: _threeLevelOptions,
                  ),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
  });
}

const _threeLevelOptions = <AddressOption>[
  AddressOption(
    addressId: 'region-1',
    label: 'Region I',
    children: [
      AddressNode(
        addressId: 'province-1',
        label: 'Pangasinan',
        children: [
          AddressNode(
            addressId: 'municipality-1',
            label: 'Alcala',
            children: [],
          ),
        ],
      ),
    ],
  ),
];

const _twoLevelOptions = <AddressOption>[
  AddressOption(
    addressId: 'region-1',
    label: 'Region I',
    children: [
      AddressNode(addressId: 'province-1', label: 'Pangasinan', children: []),
    ],
  ),
];

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required List<AddressOption> options,
  ValueChanged<AddressSelection>? onResult,
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
            onPressed: () async {
              final selection = await showCertificationAddressSelectionSheet(
                context: context,
                options: options,
              );
              if (selection != null) {
                onResult?.call(selection);
              }
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Color? _decorationColor(WidgetTester tester, Key key) {
  final container = tester.widget<Container>(find.byKey(key));
  return (container.decoration as BoxDecoration?)?.color;
}
