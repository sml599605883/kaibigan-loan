import 'package:flutter/material.dart';

import '../../../assets/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/screen_adapter.dart';

final certificationBirthdayMinimumDate = DateTime(1900);

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime parseCertificationBirthday(
  String value, {
  required DateTime maximumDate,
}) {
  final normalizedMaximumDate = _dateOnly(maximumDate);
  final dayFirstMatch = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value);
  final dayFirstSlashMatch = RegExp(
    r'^(\d{2})/(\d{2})/(\d{4})$',
  ).firstMatch(value);
  final yearFirstMatch = RegExp(r'^(\d{4})/(\d{2})/(\d{2})$').firstMatch(value);

  final int year;
  final int month;
  final int day;
  if (dayFirstMatch != null) {
    year = int.parse(dayFirstMatch.group(3)!);
    month = int.parse(dayFirstMatch.group(2)!);
    day = int.parse(dayFirstMatch.group(1)!);
  } else if (dayFirstSlashMatch != null) {
    year = int.parse(dayFirstSlashMatch.group(3)!);
    month = int.parse(dayFirstSlashMatch.group(2)!);
    day = int.parse(dayFirstSlashMatch.group(1)!);
  } else if (yearFirstMatch != null) {
    year = int.parse(yearFirstMatch.group(1)!);
    month = int.parse(yearFirstMatch.group(2)!);
    day = int.parse(yearFirstMatch.group(3)!);
  } else {
    return normalizedMaximumDate;
  }

  final parsed = DateTime(year, month, day);
  final isValidDate =
      parsed.year == year && parsed.month == month && parsed.day == day;
  if (!isValidDate ||
      parsed.isBefore(certificationBirthdayMinimumDate) ||
      parsed.isAfter(normalizedMaximumDate)) {
    return normalizedMaximumDate;
  }
  return parsed;
}

String formatCertificationBirthday(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

DateTime clampCertificationBirthday({
  required int year,
  required int month,
  required int day,
  required DateTime maximumDate,
}) {
  final normalizedMaximumDate = _dateOnly(maximumDate);
  if (year < certificationBirthdayMinimumDate.year) {
    return certificationBirthdayMinimumDate;
  }
  if (year > normalizedMaximumDate.year) {
    return normalizedMaximumDate;
  }

  final isMaximumYear = year == normalizedMaximumDate.year;
  final maximumMonth = isMaximumYear
      ? normalizedMaximumDate.month
      : DateTime.monthsPerYear;
  final clampedMonth = month.clamp(1, maximumMonth);
  final daysInMonth = DateTime(year, clampedMonth + 1, 0).day;
  final maximumDay =
      isMaximumYear && clampedMonth == normalizedMaximumDate.month
      ? normalizedMaximumDate.day
      : daysInMonth;
  final clampedDay = day.clamp(1, maximumDay);
  return DateTime(year, clampedMonth, clampedDay);
}

Future<DateTime?> showCertificationBirthdayPicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? maximumDate,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) {
    return null;
  }
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.birthdayPickerBarrier,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => CertificationBirthdayPicker(
      initialDate: initialDate,
      maximumDate: maximumDate,
    ),
  );
}

class CertificationBirthdayPicker extends StatefulWidget {
  const CertificationBirthdayPicker({
    super.key,
    required this.initialDate,
    this.maximumDate,
  });

  final DateTime initialDate;
  final DateTime? maximumDate;

  @override
  State<CertificationBirthdayPicker> createState() =>
      _CertificationBirthdayPickerState();
}

class _CertificationBirthdayPickerState
    extends State<CertificationBirthdayPicker> {
  static const _minimumYear = 1900;

  late final DateTime _maximumDate = _dateOnly(
    widget.maximumDate ?? DateTime.now(),
  );
  late DateTime _selectedDate = clampCertificationBirthday(
    year: widget.initialDate.year,
    month: widget.initialDate.month,
    day: widget.initialDate.day,
    maximumDate: _maximumDate,
  );
  late final FixedExtentScrollController _dayController =
      FixedExtentScrollController(initialItem: _selectedDate.day - 1);
  late final FixedExtentScrollController _monthController =
      FixedExtentScrollController(initialItem: _selectedDate.month - 1);
  late final FixedExtentScrollController _yearController =
      FixedExtentScrollController(
        initialItem: _selectedDate.year - _minimumYear,
      );

  bool _isSyncingControllers = false;

  int get _monthCount => _selectedDate.year == _maximumDate.year
      ? _maximumDate.month
      : DateTime.monthsPerYear;

  int get _dayCount {
    final daysInMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;
    if (_selectedDate.year == _maximumDate.year &&
        _selectedDate.month == _maximumDate.month) {
      return _maximumDate.day;
    }
    return daysInMonth;
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 13.h),
      child: SizedBox(
        key: const Key('certificationBirthdayPicker'),
        width: 345.w,
        height: 393.h,
        child: ClipRect(
          child: Stack(
            children: [
              // Positioned.fill(
              //   child: ColoredBox(color: AppColors.birthdayPickerBackground),
              // ),
              Positioned(
                left: -4.w,
                top: -6.h,
                child: Image.asset(
                  AppAssets.certificationAddressSheetBackground,
                  width: 353.w,
                  height: 401.h,
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 25.h, 0, 15.h),
                child: Column(
                  children: [
                    SizedBox(height: 300.h, child: _buildWheels()),
                    SizedBox(height: 7.h),
                    _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWheels() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(height: 46.h, color: AppColors.birthdayPickerSelectedRow),
        Row(
          children: [
            Expanded(
              child: _buildWheel(
                key: const Key('birthdayDayWheel'),
                controller: _dayController,
                itemCount: _dayCount,
                selectedIndex: _selectedDate.day - 1,
                labelForIndex: (index) => '${index + 1}',
                onSelectedItemChanged: (index) => _selectDate(
                  year: _selectedDate.year,
                  month: _selectedDate.month,
                  day: index + 1,
                ),
              ),
            ),
            Expanded(
              child: _buildWheel(
                key: const Key('birthdayMonthWheel'),
                controller: _monthController,
                itemCount: _monthCount,
                selectedIndex: _selectedDate.month - 1,
                labelForIndex: (index) => '${index + 1}',
                onSelectedItemChanged: (index) => _selectDate(
                  year: _selectedDate.year,
                  month: index + 1,
                  day: _selectedDate.day,
                ),
              ),
            ),
            Expanded(
              child: _buildWheel(
                key: const Key('birthdayYearWheel'),
                controller: _yearController,
                itemCount: _maximumDate.year - _minimumYear + 1,
                selectedIndex: _selectedDate.year - _minimumYear,
                labelForIndex: (index) => '${_minimumYear + index}',
                onSelectedItemChanged: (index) => _selectDate(
                  year: _minimumYear + index,
                  month: _selectedDate.month,
                  day: _selectedDate.day,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWheel({
    required Key key,
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required String Function(int index) labelForIndex,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      key: key,
      controller: controller,
      itemExtent: 60.h,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1000,
      perspective: 0.003,
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) => Center(
          child: SizedBox(
            height: selectedIndex == index ? 46.h : 60.h,
            child: Center(
              child: Text(
                labelForIndex(index),
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.birthdayPickerText,
                  fontSize: 16.sp,
                  fontWeight: selectedIndex == index
                      ? FontWeight.w700
                      : FontWeight.w400,
                  height: 20 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 15.w),
      child: SizedBox(
        key: const Key('birthdayActionButtons'),
        height: 46.h,
        child: Row(
          children: [
            Expanded(
              child: _BirthdayActionButton(
                label: 'Cancel',
                backgroundColor: AppColors.birthdayPickerCancelBackground,
                textColor: AppColors.birthdayPickerCancelText,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: _BirthdayActionButton(
                label: 'Done',
                backgroundColor: AppColors.birthdayPickerDoneBackground,
                textColor: AppColors.birthdayPickerDoneText,
                onTap: () => Navigator.of(context).pop(_selectedDate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate({required int year, required int month, required int day}) {
    if (_isSyncingControllers) {
      return;
    }
    final nextDate = clampCertificationBirthday(
      year: year,
      month: month,
      day: day,
      maximumDate: _maximumDate,
    );
    _isSyncingControllers = true;
    try {
      _syncController(_yearController, nextDate.year - _minimumYear);
      _syncController(_monthController, nextDate.month - 1);
      _syncController(_dayController, nextDate.day - 1);
    } finally {
      _isSyncingControllers = false;
    }
    if (_selectedDate != nextDate) {
      setState(() => _selectedDate = nextDate);
    }
  }

  void _syncController(FixedExtentScrollController controller, int index) {
    if (controller.hasClients && controller.selectedItem != index) {
      controller.jumpToItem(index);
    }
  }
}

class _BirthdayActionButton extends StatelessWidget {
  const _BirthdayActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                height: 22 / 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
