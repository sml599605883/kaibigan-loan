import 'package:flutter/material.dart';

import '../../../core/json/json.dart';
import 'personal_info_field_type.dart';

class BindCardInfo {
  BindCardInfo({
    required Iterable<BindCardGroup> groups,
    required this.topHint,
    required this.bottomHint,
  }) : groups = List<BindCardGroup>.unmodifiable(groups);

  factory BindCardInfo.fromJson(Json states) {
    final parsedGroups = states['enthrones'].listValue
        .map(BindCardGroup.fromJson)
        .toList(growable: false);
    final groups = <BindCardGroup>[];
    for (final group in parsedGroups) {
      if (group.label.isNotEmpty &&
          group.type.isNotEmpty &&
          group.fields.isNotEmpty) {
        groups.add(group);
      } else {
        group.dispose();
      }
    }
    return BindCardInfo(
      groups: groups,
      topHint: states['mourningly'].stringValue.trim(),
      bottomHint: states['pollywogs'].stringValue.trim(),
    );
  }

  final List<BindCardGroup> groups;
  final String topHint;
  final String bottomHint;

  void dispose() {
    for (final group in groups) {
      group.dispose();
    }
  }
}

class BindCardGroup {
  BindCardGroup({
    required this.label,
    required this.type,
    required Iterable<BindCardField> fields,
  }) : fields = List<BindCardField>.unmodifiable(fields);

  factory BindCardGroup.fromJson(Json json) {
    final parsedFields = json['enthrones'].listValue
        .map(BindCardField.fromJson)
        .toList(growable: false);
    final fields = <BindCardField>[];
    for (final field in parsedFields) {
      if (field.label.isNotEmpty && field.saveKey.isNotEmpty) {
        fields.add(field);
      } else {
        field.dispose();
      }
    }
    return BindCardGroup(
      label: json['primogenitor'].stringValue.trim(),
      type: json['commensurate'].stringValue.trim(),
      fields: fields,
    );
  }

  final String label;
  final String type;
  final List<BindCardField> fields;

  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
  }
}

enum BindCardFieldType { text, enumeration }

class BindCardField {
  BindCardField({
    required this.label,
    required this.saveKey,
    required this.placeholder,
    required this.fieldType,
    required Iterable<BindCardOption> options,
    required this.isRequired,
    required this.suggestedValue,
    required this.initialValue,
    required this.controller,
    required this.selectedValue,
  }) : options = List<BindCardOption>.unmodifiable(options);

  factory BindCardField.fromJson(Json json) {
    final rawType = json['prognosticator'].stringValue.trim();
    final fieldType =
        PersonalInfoFieldType.fromRaw(rawType) ==
            PersonalInfoFieldType.enumeration
        ? BindCardFieldType.enumeration
        : BindCardFieldType.text;
    final options = json['metallurgists'].listValue
        .map(BindCardOption.fromJson)
        .where((option) => option.value.isNotEmpty && option.label.isNotEmpty)
        .toList(growable: false);
    final initialValue = json['solonets'].stringValue.trim();
    final suggestedValue = json['whackers'].stringValue.trim();
    final matchedOption = _matchOption(
      options,
      value: initialValue,
      label: suggestedValue,
    );
    return BindCardField(
      label: json['primogenitor'].stringValue.trim(),
      saveKey: json['griding'].stringValue.trim(),
      placeholder: json['suppletive'].stringValue.trim(),
      fieldType: fieldType,
      options: options,
      isRequired: json['hairbreadth'].intValue != 1,
      suggestedValue: suggestedValue,
      initialValue: initialValue,
      controller: TextEditingController(
        text: fieldType == BindCardFieldType.text
            ? initialValue
            : matchedOption?.label ??
                  (suggestedValue.isNotEmpty ? suggestedValue : initialValue),
      ),
      selectedValue: matchedOption?.value ?? initialValue,
    );
  }

  final String label;
  final String saveKey;
  final String placeholder;
  final BindCardFieldType fieldType;
  final List<BindCardOption> options;
  final bool isRequired;
  final String suggestedValue;
  final String initialValue;
  final TextEditingController controller;
  String selectedValue;

  String get currentSubmitValue {
    if (fieldType == BindCardFieldType.text) {
      return controller.text.trim();
    }
    final matchedOption = _matchOption(
      options,
      value: selectedValue,
      label: controller.text,
    );
    return matchedOption?.value ?? selectedValue.trim();
  }

  void selectOption(BindCardOption option) {
    selectedValue = option.value;
    controller.text = option.label;
  }

  void dispose() {
    controller.dispose();
  }

  static BindCardOption? _matchOption(
    List<BindCardOption> options, {
    required String value,
    required String label,
  }) {
    final normalizedValue = value.trim().toLowerCase();
    final normalizedLabel = label.trim().toLowerCase();
    for (final option in options) {
      if (normalizedValue.isNotEmpty &&
          option.value.toLowerCase() == normalizedValue) {
        return option;
      }
      if (normalizedLabel.isNotEmpty &&
          option.label.toLowerCase() == normalizedLabel) {
        return option;
      }
    }
    return null;
  }
}

class BindCardOption {
  const BindCardOption({
    required this.value,
    required this.label,
    required this.logoUrl,
    required this.status,
  });

  factory BindCardOption.fromJson(Json json) {
    return BindCardOption(
      value: json['commensurate'].stringValue.trim(),
      label: json['unwits'].stringValue.trim(),
      logoUrl: json['vocalically'].stringValue.trim(),
      status: json['bondmen'].stringValue.trim(),
    );
  }

  final String value;
  final String label;
  final String logoUrl;
  final String status;
}
