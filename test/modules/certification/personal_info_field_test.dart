import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/certification/models/address_selection.dart';
import 'package:kaibigan_loan/src/modules/certification/models/personal_info_field.dart';
import 'package:kaibigan_loan/src/modules/certification/models/personal_info_field_type.dart';
import 'package:kaibigan_loan/src/modules/certification/models/personal_info_option.dart';

void main() {
  test('maps documented obfuscated certification component types', () {
    expect(
      PersonalInfoFieldType.fromRaw('Metallike'),
      PersonalInfoFieldType.enumeration,
    );
    expect(
      PersonalInfoFieldType.fromRaw('Foxfishes'),
      PersonalInfoFieldType.text,
    );
    expect(
      PersonalInfoFieldType.fromRaw('Unnecessarily'),
      PersonalInfoFieldType.citySelect,
    );
    expect(
      PersonalInfoFieldType.fromRaw('stage'),
      PersonalInfoFieldType.unknown,
    );
  });

  test('address selection separates displayed label from submitted value', () {
    final field = PersonalInfoField.fromJson(
      Json({
        'primogenitor': 'Residential Address',
        'suppletive': 'Please select address',
        'griding': 'residential_address',
        'prognosticator': 'Unnecessarily',
        'hairbreadth': 0,
        'solonets': 'Old Address',
      }),
    );
    addTearDown(field.dispose);

    expect(field.usesAddressPicker, isTrue);
    expect(field.usesPicker, isFalse);
    expect(field.usesTextInput, isFalse);

    field.selectAddress(
      const AddressSelection(
        label: 'Region I / Pangasinan / Alcala',
        value: 'Region I-Pangasinan-Alcala',
      ),
    );

    expect(field.displayText, 'Region I / Pangasinan / Alcala');
    expect(field.controller.text, 'Region I / Pangasinan / Alcala');
    expect(field.currentSubmitValue, 'Region I-Pangasinan-Alcala');
  });

  test('enum selection displays label and submits value', () {
    final field = PersonalInfoField.fromJson(
      Json({
        'primogenitor': 'Gender',
        'suppletive': 'Gender',
        'griding': 'copies',
        'prognosticator': 'Metallike',
        'hairbreadth': 0,
        'solonets': 'Female',
        'metallurgists': [
          {'unwits': 'Male', 'commensurate': 1},
          {'unwits': 'Female', 'commensurate': 2},
        ],
      }),
    );
    addTearDown(field.dispose);

    expect(field.usesPicker, isTrue);

    expect(field.displayText, 'Female');
    expect(field.currentSubmitValue, '2');

    field.selectOption(const PersonalInfoOption(label: 'Male', value: '1'));

    expect(field.displayText, 'Male');
    expect(field.currentSubmitValue, '1');
  });

  test(
    'text field submits trimmed controller text and displays placeholder',
    () {
      final field = PersonalInfoField.fromJson(
        Json({
          'primogenitor': 'Email',
          'suppletive': 'Please input email',
          'griding': 'offer',
          'prognosticator': 'Foxfishes',
          'hairbreadth': 0,
          'solonets': '',
        }),
      );
      addTearDown(field.dispose);

      expect(field.usesTextInput, isTrue);

      expect(field.displayText, 'Please input email');
      field.controller.text = '  jane@example.com  ';

      expect(field.displayText, 'jane@example.com');
      expect(field.currentSubmitValue, 'jane@example.com');
    },
  );

  test('treats undocumented component types as unknown', () {
    final field = PersonalInfoField.fromJson(
      Json({
        'primogenitor': 'Legacy Address',
        'suppletive': 'Legacy Address',
        'griding': 'legacy_address',
        'prognosticator': 'stage',
        'hairbreadth': 1,
        'solonets': 'Legacy Value',
      }),
    );
    addTearDown(field.dispose);

    expect(field.usesAddressPicker, isFalse);
    expect(field.usesPicker, isFalse);
    expect(field.usesTextInput, isFalse);
    expect(field.isSupported, isFalse);
  });
}
