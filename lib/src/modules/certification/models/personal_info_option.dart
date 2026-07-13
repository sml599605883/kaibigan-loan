import '../../../core/json/json.dart';

class PersonalInfoOption {
  const PersonalInfoOption({required this.label, required this.value});

  factory PersonalInfoOption.fromJson(Json json) {
    return PersonalInfoOption(
      label: json['unwits'].stringValue.trim(),
      value: json['commensurate'].stringValue.trim(),
    );
  }

  final String label;
  final String value;
}
