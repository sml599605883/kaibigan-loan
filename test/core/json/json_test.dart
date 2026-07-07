import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';

void main() {
  group('Json', () {
    test('parses text and supports safe chained access', () {
      final json = Json.parse('{"user":{"name":"Ana","age":"25"},"items":[1]}');

      expect(json['user']['name'].stringValue, 'Ana');
      expect(json['user']['age'].intValue, 25);
      expect(json['items'][0].intValue, 1);
      expect(json['items'][4].isNull(), isTrue);
      expect(json['missing']['nested'].stringValue, '');
      expect(json.mapValue['user']?['name'].stringValue, 'Ana');
      expect(json['items'].listValue.first.intValue, 1);
    });

    test('parses bytes and degrades parse failures to null', () {
      final json = Json.parseBytes(utf8.encode('{"ok":true}'));
      final broken = Json.parse('{');

      expect(json['ok'].boolValue, isTrue);
      expect(broken.isNull(), isTrue);
      expect(broken.mapValue, isEmpty);
      expect(broken.listValue, isEmpty);
    });

    test('converts bool num and string values with tolerant defaults', () {
      final json = Json({
        'yes': 'yes',
        'one': 1,
        'falseText': 'false',
        'numericText': '42.5',
        'boolNum': true,
        'scalar': 7,
      });

      expect(json['yes'].boolValue, isTrue);
      expect(json['one'].boolValue, isTrue);
      expect(json['falseText'].boolValue, isFalse);
      expect(json['numericText'].numValue, 42.5);
      expect(json['boolNum'].numValue, 1);
      expect(json['scalar'].stringValue, '7');
      expect(json['missing'].stringOrNull, isNull);
    });

    test('writes removes and serializes map and list values', () {
      final object = Json(<String, dynamic>{});
      object['name'] = 'Ben';
      object['items'] = <dynamic>[];
      object['items'][0] = 'first';
      object['items'][2] = 'third';
      object.remove('name');

      expect(object['name'].exists(), isFalse);
      expect(object['items'][0].stringValue, 'first');
      expect(object['items'][1].isNull(), isTrue);
      expect(object['items'][2].stringValue, 'third');
      expect(Json.parse(object.rawString())['items'][2].stringValue, 'third');
      expect(object.prettyPrint, contains('\n'));
    });
  });
}
