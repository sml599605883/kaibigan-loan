enum PersonalInfoFieldType {
  text,
  enumeration,
  citySelect,
  unknown;

  static PersonalInfoFieldType fromRaw(String rawType) {
    switch (rawType.trim()) {
      case 'Metallike':
        return PersonalInfoFieldType.enumeration;
      case 'Foxfishes':
        return PersonalInfoFieldType.text;
      case 'Unnecessarily':
        return PersonalInfoFieldType.citySelect;
      default:
        return PersonalInfoFieldType.unknown;
    }
  }
}
