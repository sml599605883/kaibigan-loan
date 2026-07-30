import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/certification/models/bind_card_info.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_bind_card_option_sheet.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';

void main() {
  testWidgets('shows issued maintenance text when bondmen is zero', (
    tester,
  ) async {
    final options = [
      BindCardOption.fromJson(
        Json({
          'commensurate': 'bank-1',
          'unwits': 'Sample Bank',
          'bondmen': 0,
          'snatcher': '  Temporarily under maintenance  ',
        }),
      ),
      BindCardOption.fromJson(
        Json({
          'commensurate': 'bank-2',
          'unwits': 'Available Bank',
          'bondmen': 1,
          'snatcher': 'Must stay hidden',
        }),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showCertificationBindCardOptionSheet(
                context,
                options: options,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final maintenanceText = tester.widget<Text>(
      find.text('Temporarily under maintenance'),
    );
    expect(
      maintenanceText.style?.color,
      AppColors.certificationMaintenanceText,
    );
    expect(maintenanceText.style?.fontSize, 10);
    expect(maintenanceText.style?.height, 2);
    expect(
      tester.getCenter(find.text('Sample Bank')).dx,
      closeTo(
        tester.getCenter(find.text('Temporarily under maintenance')).dx,
        0.5,
      ),
    );
    expect(find.text('Must stay hidden'), findsNothing);
  });
}
