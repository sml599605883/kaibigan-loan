import 'package:flutter/material.dart';

import '../../../core/json/json.dart';
import 'address_selection.dart';
import 'personal_info_option.dart';

class PersonalInfoField {
  PersonalInfoField({
    required this.title,
    required this.placeholder,
    required this.keyName,
    required this.controlType,
    required this.numericKeyboard,
    required this.isRequired,
    required this.options,
    required this.controller,
    required this.selectedValue,
  });

  factory PersonalInfoField.fromJson(Json json) {
    final options = json['metallurgists'].listValue
        .map(PersonalInfoOption.fromJson)
        .where((option) => option.label.isNotEmpty)
        .toList(growable: false);
    final title = json['primogenitor'].stringValue.trim();
    final initialValue = json['solonets'].stringValue.trim();
    final matchedOption = _matchOption(options, initialValue);
    return PersonalInfoField(
      title: title,
      placeholder: _firstNonEmpty(json['suppletive'].stringValue.trim(), title),
      keyName: json['griding'].stringValue.trim(),
      controlType: json['prognosticator'].stringValue.trim(),
      numericKeyboard: json['bellyache'].intValue == 1,
      isRequired: json['hairbreadth'].intValue != 1,
      options: options,
      controller: TextEditingController(
        text: matchedOption?.label ?? initialValue,
      ),
      selectedValue: matchedOption?.value ?? initialValue,
    );
  }

  final String title;
  final String placeholder;
  final String keyName;
  final String controlType;
  final bool numericKeyboard;
  final bool isRequired;
  final List<PersonalInfoOption> options;
  final TextEditingController controller;
  String selectedValue;

  bool get usesAddressPicker => controlType == 'stage';
  bool get usesPicker =>
      !usesAddressPicker && options.isNotEmpty && !usesTextInput;
  bool get usesTextInput =>
      !usesAddressPicker &&
      (controlType == 'onto' || controlType == 'txt' || options.isEmpty);

  String get displayText {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      return text;
    }
    if (placeholder.isNotEmpty) {
      return placeholder;
    }
    return 'Please enter';
  }

  String get currentSubmitValue {
    if (usesTextInput) {
      return controller.text.trim();
    }
    final matchedOption = _matchOption(options, controller.text.trim());
    if (matchedOption != null) {
      return matchedOption.value;
    }
    return selectedValue.trim();
  }

  PersonalInfoOption? get selectedOption => _matchOption(
    options,
    selectedValue.isNotEmpty ? selectedValue : controller.text.trim(),
  );

  void selectOption(PersonalInfoOption option) {
    selectedValue = option.value;
    controller.text = option.label;
  }

  void selectAddress(AddressSelection selection) {
    selectedValue = selection.value;
    controller.text = selection.label;
  }

  void dispose() {
    controller.dispose();
  }

  static PersonalInfoOption? _matchOption(
    List<PersonalInfoOption> options,
    String rawValue,
  ) {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.value.trim().toLowerCase() == value ||
          option.label.trim().toLowerCase() == value) {
        return option;
      }
    }
    return null;
  }

  static String _firstNonEmpty(String primary, String fallback) {
    return primary.isNotEmpty ? primary : fallback;
  }
}
