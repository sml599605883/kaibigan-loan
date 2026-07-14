import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/certification/models/salary_day_option.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_salary_day_selection_sheet.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';
import 'package:kaibigan_loan/src/utils/screen_adapter.dart';

void main() {
  test('restores a salary day selection from the API display value', () {
    final selection = SalaryDaySelection.fromCurrentValue(
      _options,
      'Once a Month|1',
    );

    expect(selection?.groupValue, '4');
    expect(selection?.submitValue, '11');
    expect(selection?.displayText, 'Once a Month|1');
  });

  testWidgets('cancel on child level returns to salary-day groups', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.text('Weekly'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Fri'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Once a Month'), findsOneWidget);
    expect(find.text('Fri'), findsNothing);
  });

  testWidgets('shows the current child selection when reopened', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        initialSelection: const SalaryDaySelection(
          groupValue: '2',
          submitValue: '6',
          displayText: 'Weekly|Fri',
        ),
      ),
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final option = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('salaryDayOption_1')),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (option.decoration as BoxDecoration).color,
      AppColors.uploadMethodSelected,
    );
  });
}

Widget _host({SalaryDaySelection? initialSelection}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        ScreenAdapter.init(context);
        return Scaffold(
          body: CertificationSalaryDaySelectionSheet(
            options: _options,
            initialSelection: initialSelection,
          ),
        );
      },
    ),
  );
}

final _options = SalaryDayGroup.parseList(
  Json([
    {
      'unwits': 'Weekly',
      'commensurate': 2,
      'metallurgists': [
        {'unwits': 'Mon', 'commensurate': 2},
        {'unwits': 'Fri', 'commensurate': 6},
      ],
    },
    {
      'unwits': 'Once a Month',
      'commensurate': 4,
      'metallurgists': [
        {'unwits': 1, 'commensurate': 11},
      ],
    },
  ]),
);
