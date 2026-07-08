import '../json/json.dart';

class ProductDetailCache {
  const ProductDetailCache({
    required this.amount,
    required this.productid,
    required this.orderNo,
    required this.orderId,
    required this.term,
    required this.termType,
    required this.note,
    required this.nextStep,
  });

  factory ProductDetailCache.fromJson(dynamic value) {
    final json = Json(value);
    final product = json['sensitized'];
    return ProductDetailCache(
      amount: _field(json, product, 'ecumenicalism'),
      productid: _field(json, product, 'cabdrivers'),
      orderNo: _field(json, product, 'chattinesses'),
      orderId: _field(json, product, 'joyriding'),
      term: _field(json, product, 'desertifying'),
      termType: _field(json, product, 'tythes'),
      note: _noteMap(json['metallurgists']),
      nextStep: _nextStepMap(json['grinner']),
    );
  }

  final String amount;
  final String productid;
  final String orderNo;
  final String orderId;
  final String term;
  final String termType;
  final Map<String, dynamic> note;
  final Map<String, dynamic> nextStep;

  static String _field(Json root, Json product, String key) {
    final productValue = product[key].stringValue.trim();
    if (productValue.isNotEmpty) {
      return productValue;
    }
    return root[key].stringValue.trim();
  }

  static Map<String, dynamic> _noteMap(Json json) {
    return {
      'base': json['aimless'].stringValue,
      'base_success': json['prosencephalic'].stringValue,
      'face': json['periodontal'].stringValue,
    };
  }

  static Map<String, dynamic> _nextStepMap(Json json) {
    return {
      'subtitle': json['suppletive'].stringValue,
      'statusName': json['deepnesses'].stringValue,
      'taskType': json['unconfusing'].stringValue,
      'canClick': json['ref'].value,
      'optional': json['hairbreadth'].value,
      'ifMust': json['doronicum'].value,
      'canClickMessage': json['sullenly'].stringValue,
    };
  }
}
