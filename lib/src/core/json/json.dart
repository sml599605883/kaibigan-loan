import 'dart:convert';

class Json {
  Json(dynamic value) : _value = _normalize(value);

  dynamic _value;

  static Json parse(String source) {
    try {
      return Json(jsonDecode(source));
    } catch (_) {
      return Json(null);
    }
  }

  static Json parseBytes(List<int> bytes) {
    try {
      return parse(utf8.decode(bytes));
    } catch (_) {
      return Json(null);
    }
  }

  dynamic get value => _value;

  Map<String, dynamic> get mapValue => mapOrNull ?? <String, dynamic>{};

  Map<String, dynamic>? get mapOrNull {
    final value = _value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  List<dynamic> get listValue => listOrNull ?? <dynamic>[];

  List<dynamic>? get listOrNull {
    final value = _value;
    if (value is List) {
      return value;
    }
    return null;
  }

  bool get boolValue => boolOrNull ?? false;

  bool? get boolOrNull {
    final value = _value;
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (<String>{'true', 'y', 't', 'yes', '1'}.contains(normalized)) {
        return true;
      }
      if (<String>{'false', 'n', 'f', 'no', '0'}.contains(normalized)) {
        return false;
      }
    }
    return null;
  }

  num get numValue => numOrNull ?? 0;

  num? get numOrNull {
    final value = _value;
    if (value is num) {
      return value;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? double.tryParse(value.trim());
    }
    return null;
  }

  int get intValue => numValue.toInt();

  int? get intOrNull => numOrNull?.toInt();

  double get doubleValue => numValue.toDouble();

  double? get doubleOrNull => numOrNull?.toDouble();

  String get stringValue => stringOrNull ?? '';

  String? get stringOrNull {
    final value = _value;
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  bool exists() => _value != null;

  bool isNull() => _value == null;

  Json operator [](Object? key) {
    final value = _value;
    if (key is int && value is List) {
      if (key >= 0 && key < value.length) {
        return Json(value[key]);
      }
      return Json(null);
    }
    if (value is Map) {
      if (value.containsKey(key)) {
        return Json(value[key]);
      }
      if (key != null && value.containsKey(key.toString())) {
        return Json(value[key.toString()]);
      }
    }
    return Json(null);
  }

  void operator []=(Object key, dynamic item) {
    if (key is int) {
      if (_value is! List) {
        _value = <dynamic>[];
      }
      final list = _value as List<dynamic>;
      while (list.length <= key) {
        list.add(null);
      }
      list[key] = _normalize(item);
      return;
    }

    if (_value is! Map) {
      _value = <String, dynamic>{};
    }
    (_value as Map<dynamic, dynamic>)[key.toString()] = _normalize(item);
  }

  void remove(Object key) {
    final value = _value;
    if (key is int && value is List && key >= 0 && key < value.length) {
      value.removeAt(key);
      return;
    }
    if (value is Map) {
      value.remove(key);
      value.remove(key.toString());
    }
  }

  String rawString() => jsonEncode(_value);

  String get prettyPrint => const JsonEncoder.withIndent('  ').convert(_value);

  @override
  String toString() => rawString();

  static dynamic _normalize(dynamic value) {
    if (value is Json) {
      return value.value;
    }
    return value;
  }
}
