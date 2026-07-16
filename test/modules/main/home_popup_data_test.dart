import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/main/home_popup_data.dart';

void main() {
  test('parses documented app upgrade popup fields', () {
    final data = HomePopupData.fromJson(
      Json({
        'commensurate': 1,
        'misaligned': {
          'misapprehension': '2.1.0',
          'lowliness': 'Install the latest version.',
          'bloomeries': 'https://store.example.test/app',
        },
      }),
    );

    expect(data.type, HomePopupType.appUpgrade);
    expect(data.displayVersion, 'V2.1.0');
    expect(data.content, 'Install the latest version.');
    expect(data.targetUrl, 'https://store.example.test/app');
    expect(data.shouldShow, isTrue);
  });

  test('parses documented marketing popup fields', () {
    final data = HomePopupData.fromJson(
      Json({
        'commensurate': 3,
        'misaligned': {
          'mourningly': 'Promotion',
          'tanists': 'https://cdn.example.test/popup.png',
          'bloomeries': 'https://h5.example.test/promotion',
        },
      }),
    );

    expect(data.type, HomePopupType.marketing);
    expect(data.content, 'Promotion');
    expect(data.imageUrl, 'https://cdn.example.test/popup.png');
    expect(data.targetUrl, 'https://h5.example.test/promotion');
    expect(data.shouldShow, isTrue);
  });

  test('does not show unsupported or incomplete popup types', () {
    expect(
      HomePopupData.fromJson(Json({'commensurate': 0})).shouldShow,
      isFalse,
    );
    expect(
      HomePopupData.fromJson(Json({'commensurate': 2})).type,
      HomePopupType.membershipUpgrade,
    );
    expect(
      HomePopupData.fromJson(Json({'commensurate': 99})).type,
      HomePopupType.unsupported,
    );
    expect(
      HomePopupData.fromJson(
        Json({
          'commensurate': 3,
          'misaligned': {'tanists': ' '},
        }),
      ).shouldShow,
      isFalse,
    );
  });
}
