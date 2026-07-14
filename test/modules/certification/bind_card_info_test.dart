import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/certification/models/bind_card_info.dart';

void main() {
  test('parses bind card groups, fields, hints, and option metadata', () {
    final info = BindCardInfo.fromJson(
      Json({
        'mourningly': '  Select your payout account.  ',
        'pollywogs': '  Account details must match your ID.  ',
        'enthrones': [
          {
            'primogenitor': '  Bank account  ',
            'commensurate': 1,
            'enthrones': [
              {
                'primogenitor': '  Bank  ',
                'griding': '  bank_code  ',
                'suppletive': '  Select a bank  ',
                'prognosticator': '  Metallike  ',
                'hairbreadth': 0,
                'solonets': '  Current Name  ',
                'whackers': '  Suggested Name  ',
                'metallurgists': [
                  {
                    'commensurate': 101,
                    'unwits': '  Sample Bank  ',
                    'vocalically': '  https://example.com/bank.png  ',
                    'bondmen': 0,
                  },
                ],
              },
            ],
          },
        ],
      }),
    );

    expect(info.topHint, 'Select your payout account.');
    expect(info.bottomHint, 'Account details must match your ID.');
    expect(info.groups, hasLength(1));

    final group = info.groups.single;
    expect(group.label, 'Bank account');
    expect(group.type, '1');

    final field = group.fields.single;
    expect(field.label, 'Bank');
    expect(field.saveKey, 'bank_code');
    expect(field.placeholder, 'Select a bank');
    expect(field.fieldType, BindCardFieldType.enumeration);
    expect(field.isRequired, isTrue);
    expect(field.initialValue, 'Current Name');
    expect(field.suggestedValue, 'Suggested Name');

    final option = field.options.single;
    expect(option.value, '101');
    expect(option.label, 'Sample Bank');
    expect(option.logoUrl, 'https://example.com/bank.png');
    expect(option.status, '0');
  });

  test('parses string values and marks hairbreadth 1 as optional', () {
    final info = BindCardInfo.fromJson(
      Json({
        'enthrones': [
          {
            'primogenitor': 'E-wallet',
            'commensurate': ' wallet ',
            'enthrones': [
              {
                'primogenitor': 'Account name',
                'griding': 'account_name',
                'prognosticator': 'Foxfishes',
                'hairbreadth': 1,
                'metallurgists': [
                  {
                    'commensurate': ' gcash ',
                    'unwits': ' GCash ',
                    'bondmen': '1',
                  },
                ],
              },
            ],
          },
        ],
      }),
    );

    final group = info.groups.single;
    final field = group.fields.single;
    final option = field.options.single;

    expect(group.type, 'wallet');
    expect(field.fieldType, BindCardFieldType.text);
    expect(field.isRequired, isFalse);
    expect(field.initialValue, isEmpty);
    expect(field.suggestedValue, isEmpty);
    expect(option.value, 'gcash');
    expect(option.status, '1');
  });

  test(
    'filters malformed groups, fields, and options without dropping maintenance',
    () {
      final info = BindCardInfo.fromJson(
        Json({
          'enthrones': [
            {
              'primogenitor': ' ',
              'commensurate': 'bank',
              'enthrones': [_validField()],
            },
            {
              'primogenitor': 'Bank',
              'commensurate': ' ',
              'enthrones': [_validField()],
            },
            {
              'primogenitor': 'Bank',
              'commensurate': 'bank',
              'enthrones': [
                {'primogenitor': '', 'griding': 'bank_code'},
                {'primogenitor': 'Bank', 'griding': ''},
              ],
            },
            {
              'primogenitor': 'Bank',
              'commensurate': 'bank',
              'enthrones': [
                {
                  ..._validField(),
                  'metallurgists': [
                    {'commensurate': '', 'unwits': 'Missing value'},
                    {'commensurate': 'missing-label', 'unwits': ''},
                    {
                      'commensurate': 'maintained-bank',
                      'unwits': 'Maintained Bank',
                      'bondmen': 0,
                    },
                  ],
                },
              ],
            },
          ],
        }),
      );

      expect(info.groups, hasLength(1));
      expect(info.groups.single.fields, hasLength(1));
      expect(info.groups.single.fields.single.options, hasLength(1));
      expect(
        info.groups.single.fields.single.options.single.value,
        'maintained-bank',
      );
    },
  );
}

Map<String, Object> _validField() {
  return {
    'primogenitor': 'Bank',
    'griding': 'bank_code',
    'prognosticator': 'Metallike',
  };
}
