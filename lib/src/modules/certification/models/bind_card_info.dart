import '../../../core/json/json.dart';

class BindCardInfo {
  BindCardInfo({
    required Iterable<BindCardGroup> groups,
    required this.topHint,
    required this.bottomHint,
  }) : groups = List<BindCardGroup>.unmodifiable(groups);

  factory BindCardInfo.fromJson(Json states) {
    final groups = states['enthrones'].listValue
        .map(BindCardGroup.fromJson)
        .where(
          (group) =>
              group.label.isNotEmpty &&
              group.type.isNotEmpty &&
              group.fields.isNotEmpty,
        );
    return BindCardInfo(
      groups: groups,
      topHint: states['mourningly'].stringValue.trim(),
      bottomHint: states['pollywogs'].stringValue.trim(),
    );
  }

  final List<BindCardGroup> groups;
  final String topHint;
  final String bottomHint;
}

class BindCardGroup {
  BindCardGroup({
    required this.label,
    required this.type,
    required Iterable<BindCardField> fields,
  }) : fields = List<BindCardField>.unmodifiable(fields);

  factory BindCardGroup.fromJson(Json json) {
    final fields = json['enthrones'].listValue
        .map(BindCardField.fromJson)
        .where((field) => field.label.isNotEmpty && field.saveKey.isNotEmpty);
    return BindCardGroup(
      label: json['primogenitor'].stringValue.trim(),
      type: json['commensurate'].stringValue.trim(),
      fields: fields,
    );
  }

  final String label;
  final String type;
  final List<BindCardField> fields;
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
    required this.initialLabel,
    required this.initialValue,
  }) : options = List<BindCardOption>.unmodifiable(options);

  factory BindCardField.fromJson(Json json) {
    final rawType = json['prognosticator'].stringValue.trim();
    final options = json['metallurgists'].listValue
        .map(BindCardOption.fromJson)
        .where((option) => option.value.isNotEmpty && option.label.isNotEmpty);
    return BindCardField(
      label: json['primogenitor'].stringValue.trim(),
      saveKey: json['griding'].stringValue.trim(),
      placeholder: json['suppletive'].stringValue.trim(),
      fieldType: rawType.toLowerCase() == 'enum'
          ? BindCardFieldType.enumeration
          : BindCardFieldType.text,
      options: options,
      isRequired: json['hairbreadth'].intValue != 1,
      initialLabel: json['solonets'].stringValue.trim(),
      initialValue: json['whackers'].stringValue.trim(),
    );
  }

  final String label;
  final String saveKey;
  final String placeholder;
  final BindCardFieldType fieldType;
  final List<BindCardOption> options;
  final bool isRequired;
  final String initialLabel;
  final String initialValue;
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
