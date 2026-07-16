import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/account/account_list_models.dart';

void main() {
  test('parses account fields and supports string and numeric main flags', () {
    final items = parseAccountListItems(
      Json(<String, dynamic>{
        'religiosities': <Map<String, dynamic>>[
          <String, dynamic>{
            'overdoer': 'Bank',
            'dendron': 'https://example.com/bank.png',
            'anchovetta': <Map<String, dynamic>>[
              <String, dynamic>{
                'smokehouse': 'bank-1',
                'vocalically': '',
                'postaccident': 'Metro Bank',
                'flamen': '**** 1234',
                'bondmen': 0,
                'uptime': '1',
              },
            ],
          },
          <String, dynamic>{
            'overdoer': 'E-wallet',
            'dendron': 'https://example.com/wallet.png',
            'anchovetta': <Map<String, dynamic>>[
              <String, dynamic>{
                'smokehouse': 'wallet-1',
                'vocalically': '',
                'postaccident': 'GCash',
                'flamen': '0917 000 0000',
                'bondmen': 1,
                'uptime': 0,
              },
            ],
          },
        ],
      }),
    );

    expect(items, hasLength(2));
    expect(
      items.first,
      const AccountListItem(
        bindId: 'bank-1',
        typeName: 'Bank',
        typeIconUrl: 'https://example.com/bank.png',
        providerName: 'Metro Bank',
        displayValue: '**** 1234',
        isUnderMaintenance: true,
        isMain: true,
      ),
    );
    expect(items.last.typeIconUrl, 'https://example.com/wallet.png');
    expect(items.last.displayValue, '0917 000 0000');
    expect(items.last.isUnderMaintenance, isFalse);
    expect(items.last.isMain, isFalse);
  });

  test('groups known types first and keeps unknown server titles', () {
    final sections = groupAccountListItems(<AccountListItem>[
      _item('cash-1', 'cash pickup'),
      _item('other-1', 'Crypto Wallet'),
      _item('wallet-1', 'E-WALLET'),
      _item('bank-1', 'bank'),
      _item('other-2', 'Crypto Wallet'),
      _item('other-3', 'Other'),
    ]);

    expect(sections.map((section) => section.title), <String>[
      'bank',
      'E-WALLET',
      'cash pickup',
      'Crypto Wallet',
      'Other',
    ]);
    expect(sections[3].items.map((item) => item.bindId), <String>[
      'other-1',
      'other-2',
    ]);
  });

  test('filters accounts with an empty bind id', () {
    final items = parseAccountListItems(
      Json(<String, dynamic>{
        'religiosities': <Map<String, dynamic>>[
          <String, dynamic>{
            'overdoer': 'Bank',
            'anchovetta': <Map<String, dynamic>>[
              <String, dynamic>{'smokehouse': '   '},
              <String, dynamic>{'smokehouse': 'valid-id'},
            ],
          },
        ],
      }),
    );

    expect(items.map((item) => item.bindId), <String>['valid-id']);
  });
}

AccountListItem _item(String bindId, String typeName) {
  return AccountListItem(
    bindId: bindId,
    typeName: typeName,
    typeIconUrl: '',
    providerName: '',
    displayValue: '',
    isMain: false,
  );
}
