import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_birthday_picker.dart';

void main() {
  final maximumDate = DateTime(2026, 7, 16);

  group('parseCertificationBirthday', () {
    test('parses dd-MM-yyyy, dd/MM/yyyy, and yyyy/MM/dd values', () {
      expect(
        parseCertificationBirthday('29-02-2024', maximumDate: maximumDate),
        DateTime(2024, 2, 29),
      );
      expect(
        parseCertificationBirthday('23/11/1993', maximumDate: maximumDate),
        DateTime(1993, 11, 23),
      );
      expect(
        parseCertificationBirthday('2024/02/29', maximumDate: maximumDate),
        DateTime(2024, 2, 29),
      );
    });

    test('falls back to maximumDate for empty or invalid values', () {
      for (final value in [
        '',
        'not-a-date',
        '31-04-2024',
        '29-02-2023',
        '31/04/2024',
        '29/02/2023',
      ]) {
        expect(
          parseCertificationBirthday(value, maximumDate: maximumDate),
          maximumDate,
          reason: 'value: $value',
        );
      }
    });

    test('rejects values that do not exactly match a supported format', () {
      for (final value in [
        ' 29-02-2024',
        '29-02-2024 ',
        '9-02-2024',
        '09-2-2024',
        '9/02/2024',
        '09/2/2024',
        '2024-02-29',
        '29-02/2024',
        '29/02-2024',
        '2024/02-29',
      ]) {
        expect(
          parseCertificationBirthday(value, maximumDate: maximumDate),
          maximumDate,
          reason: 'value: $value',
        );
      }
    });

    test('falls back to maximumDate when value is outside allowed range', () {
      expect(
        parseCertificationBirthday('31-12-1899', maximumDate: maximumDate),
        maximumDate,
      );
      expect(
        parseCertificationBirthday('17-07-2026', maximumDate: maximumDate),
        maximumDate,
      );
    });

    test('normalizes maximumDate fallback values to date-only', () {
      final maximumDateWithTime = DateTime(2026, 7, 16, 18, 30, 45);

      expect(
        parseCertificationBirthday(
          'not-a-date',
          maximumDate: maximumDateWithTime,
        ),
        maximumDate,
      );
      expect(
        parseCertificationBirthday(
          '17-07-2026',
          maximumDate: maximumDateWithTime,
        ),
        maximumDate,
      );
    });
  });

  test('formatCertificationBirthday uses dd-MM-yyyy', () {
    expect(formatCertificationBirthday(DateTime(2024, 2, 9)), '09-02-2024');
  });

  group('clampCertificationBirthday', () {
    test('clamps month and day values to their valid bounds', () {
      expect(
        clampCertificationBirthday(
          year: 2024,
          month: 0,
          day: 10,
          maximumDate: maximumDate,
        ),
        DateTime(2024, 1, 10),
      );
      expect(
        clampCertificationBirthday(
          year: 2024,
          month: 13,
          day: 10,
          maximumDate: maximumDate,
        ),
        DateTime(2024, 12, 10),
      );
      expect(
        clampCertificationBirthday(
          year: 2024,
          month: 6,
          day: 0,
          maximumDate: maximumDate,
        ),
        DateTime(2024, 6),
      );
    });

    test('clamps the day to the last valid day of the month', () {
      expect(
        clampCertificationBirthday(
          year: 2024,
          month: 2,
          day: 31,
          maximumDate: maximumDate,
        ),
        DateTime(2024, 2, 29),
      );
      expect(
        clampCertificationBirthday(
          year: 2023,
          month: 2,
          day: 29,
          maximumDate: maximumDate,
        ),
        DateTime(2023, 2, 28),
      );
    });

    test('clamps future dates to maximumDate', () {
      expect(
        clampCertificationBirthday(
          year: 2026,
          month: 12,
          day: 31,
          maximumDate: maximumDate,
        ),
        maximumDate,
      );
    });

    test('clamps maximum-year month before clamping its valid day', () {
      expect(
        clampCertificationBirthday(
          year: 2026,
          month: 12,
          day: 1,
          maximumDate: maximumDate,
        ),
        DateTime(2026, 7),
      );
    });

    test('normalizes a maximumDate with time before clamping', () {
      expect(
        clampCertificationBirthday(
          year: 2026,
          month: 7,
          day: 17,
          maximumDate: DateTime(2026, 7, 16, 18, 30, 45),
        ),
        maximumDate,
      );
    });

    test('clamps dates before the minimum to the minimum date', () {
      expect(
        clampCertificationBirthday(
          year: 1899,
          month: 12,
          day: 31,
          maximumDate: maximumDate,
        ),
        certificationBirthdayMinimumDate,
      );
    });
  });

  group('CertificationBirthdayPicker', () {
    testWidgets('creates day month and year wheels at the initial date', (
      tester,
    ) async {
      await _pumpLauncher(
        tester,
        initialDate: DateTime(2003, 9, 14),
        maximumDate: maximumDate,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_wheelController(tester, 'birthdayDayWheel').selectedItem, 13);
      expect(_wheelController(tester, 'birthdayMonthWheel').selectedItem, 8);
      expect(_wheelController(tester, 'birthdayYearWheel').selectedItem, 103);
      expect(_wheel(tester, 'birthdayDayWheel').diameterRatio, 1000);
      expect(_wheel(tester, 'birthdayMonthWheel').diameterRatio, 1000);
      expect(_wheel(tester, 'birthdayYearWheel').diameterRatio, 1000);
    });

    testWidgets('Cancel returns null', (tester) async {
      DateTime? result = DateTime(2000);
      await _pumpLauncher(
        tester,
        initialDate: DateTime(2003, 9, 14),
        maximumDate: maximumDate,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('Done returns the current selection', (tester) async {
      DateTime? result;
      await _pumpLauncher(
        tester,
        initialDate: DateTime(2003, 9, 14),
        maximumDate: maximumDate,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      _wheelController(tester, 'birthdayDayWheel').jumpToItem(19);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(result, DateTime(2003, 9, 20));
    });

    testWidgets('Done normalizes an initial date with time to date-only', (
      tester,
    ) async {
      DateTime? result;
      await _pumpLauncher(
        tester,
        initialDate: DateTime(2003, 9, 14, 18, 30, 45),
        maximumDate: maximumDate,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(result, DateTime(2003, 9, 14));
    });

    testWidgets('rapid year and month changes keep the last valid selection', (
      tester,
    ) async {
      DateTime? result;
      await _pumpLauncher(
        tester,
        initialDate: DateTime(2024, 1, 31),
        maximumDate: maximumDate,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      _wheelController(tester, 'birthdayYearWheel').jumpToItem(123);
      _wheelController(tester, 'birthdayMonthWheel').jumpToItem(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(result, DateTime(2023, 2, 28));
    });

    testWidgets('entering maximum year clamps month and day before shrinking', (
      tester,
    ) async {
      DateTime? result;
      await _pumpLauncher(
        tester,
        initialDate: DateTime(2025, 12, 31),
        maximumDate: maximumDate,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      _wheelController(tester, 'birthdayYearWheel').jumpToItem(126);
      await tester.pumpAndSettle();

      expect(_wheelItemCount(tester, 'birthdayMonthWheel'), 7);
      expect(_wheelController(tester, 'birthdayMonthWheel').selectedItem, 6);
      expect(_wheelItemCount(tester, 'birthdayDayWheel'), 16);
      expect(_wheelController(tester, 'birthdayDayWheel').selectedItem, 15);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, maximumDate);
    });

    testWidgets(
      'entering maximum year preserves a valid day after month clamp',
      (tester) async {
        DateTime? result;
        await _pumpLauncher(
          tester,
          initialDate: DateTime(2025, 12),
          maximumDate: maximumDate,
          onResult: (value) => result = value,
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        _wheelController(tester, 'birthdayYearWheel').jumpToItem(126);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(result, DateTime(2026, 7));
      },
    );

    testWidgets('maximum year limits its months and current month days', (
      tester,
    ) async {
      await _pumpLauncher(
        tester,
        initialDate: maximumDate,
        maximumDate: maximumDate,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_wheelItemCount(tester, 'birthdayYearWheel'), 127);
      expect(_wheelItemCount(tester, 'birthdayMonthWheel'), 7);
      expect(_wheelItemCount(tester, 'birthdayDayWheel'), 16);
    });

    testWidgets('changing leap year to non-leap year clamps the selected day', (
      tester,
    ) async {
      DateTime? result;
      await _pumpLauncher(
        tester,
        initialDate: DateTime(2024, 2, 29),
        maximumDate: maximumDate,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      _wheelController(tester, 'birthdayYearWheel').jumpToItem(123);
      await tester.pumpAndSettle();

      expect(_wheelItemCount(tester, 'birthdayDayWheel'), 28);
      expect(_wheelController(tester, 'birthdayDayWheel').selectedItem, 27);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2023, 2, 28));
    });
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required DateTime initialDate,
  required DateTime maximumDate,
  ValueChanged<DateTime?>? onResult,
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
              final result = await showCertificationBirthdayPicker(
                context: context,
                initialDate: initialDate,
                maximumDate: maximumDate,
              );
              onResult?.call(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

FixedExtentScrollController _wheelController(WidgetTester tester, String key) {
  return _wheel(tester, key).controller! as FixedExtentScrollController;
}

int _wheelItemCount(WidgetTester tester, String key) {
  return _wheel(tester, key).childDelegate.estimatedChildCount!;
}

ListWheelScrollView _wheel(WidgetTester tester, String key) =>
    tester.widget<ListWheelScrollView>(find.byKey(Key(key)));
