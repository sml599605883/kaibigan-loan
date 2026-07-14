import '../../../core/json/json.dart';

class SalaryDayGroup {
  const SalaryDayGroup({
    required this.label,
    required this.value,
    required this.children,
  });

  factory SalaryDayGroup.fromJson(Json json) {
    return SalaryDayGroup(
      label: json['unwits'].stringValue.trim(),
      value: json['commensurate'].stringValue.trim(),
      children: json['metallurgists'].listValue
          .map(SalaryDayOption.fromJson)
          .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String label;
  final String value;
  final List<SalaryDayOption> children;

  static List<SalaryDayGroup> parseList(Json json) {
    return json.listValue
        .map(SalaryDayGroup.fromJson)
        .where((group) => group.label.isNotEmpty && group.children.isNotEmpty)
        .toList(growable: false);
  }
}

class SalaryDayOption {
  const SalaryDayOption({required this.label, required this.value});

  factory SalaryDayOption.fromJson(Json json) {
    return SalaryDayOption(
      label: json['unwits'].stringValue.trim(),
      value: json['commensurate'].stringValue.trim(),
    );
  }

  final String label;
  final String value;
}

class SalaryDaySelection {
  const SalaryDaySelection({
    required this.groupValue,
    required this.submitValue,
    required this.displayText,
  });

  final String groupValue;
  final String submitValue;
  final String displayText;

  static SalaryDaySelection? fromCurrentValue(
    List<SalaryDayGroup> groups,
    String currentValue,
  ) {
    final normalized = currentValue.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final group in groups) {
      for (final child in group.children) {
        final selection = SalaryDaySelection(
          groupValue: group.value,
          submitValue: child.value,
          displayText: '${group.label}|${child.label}',
        );
        if (child.value.trim().toLowerCase() == normalized ||
            selection.displayText.toLowerCase() == normalized) {
          return selection;
        }
      }
    }
    return null;
  }
}
