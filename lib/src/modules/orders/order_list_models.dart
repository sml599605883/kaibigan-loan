import '../../core/json/json.dart';

enum OrderListStatus {
  all('4', 'All order'),
  outstanding('7', 'Outstanding'),
  overdue('6', 'Overdue'),
  settled('5', 'Settled');

  const OrderListStatus(this.code, this.label);

  final String code;
  final String label;

  static OrderListStatus fromCode(String? code) {
    final normalizedCode = code?.trim();
    for (final status in values) {
      if (status.code == normalizedCode) {
        return status;
      }
    }
    return all;
  }
}

class OrderListItem {
  const OrderListItem({
    required this.productId,
    required this.redirectTarget,
    required this.productName,
    required this.productLogo,
    required this.amountText,
    required this.amountLabel,
    required this.statusText,
    required this.dateValue,
    required this.dateLabel,
    required this.actionText,
  });

  factory OrderListItem.fromJson(Json json) {
    return OrderListItem(
      productId: json['seamounts'].stringValue.trim(),
      redirectTarget: json['overrule'].stringValue.trim(),
      productName: json['omissible'].stringValue.trim(),
      productLogo: json['biontic'].stringValue.trim(),
      amountText: json['ecumenicalism'].stringValue.trim(),
      amountLabel: json['curite'].stringValue.trim(),
      statusText: json['playhouses'].stringValue.trim(),
      dateValue: json['spelts'].stringValue.trim(),
      dateLabel: json['sandpainting'].stringValue.trim(),
      actionText: json['restless'].stringValue.trim(),
    );
  }

  final String productId;
  final String redirectTarget;
  final String productName;
  final String productLogo;
  final String amountText;
  final String amountLabel;
  final String statusText;
  final String dateValue;
  final String dateLabel;
  final String actionText;

  bool get isOverdue => statusText.toLowerCase().contains('overdue');
  bool get isRepayAction => actionText.toLowerCase().contains('repay');
}

List<OrderListItem> parseOrderListItems(Json states) {
  final list = states['religiosities'].listValue;
  return list.map(OrderListItem.fromJson).toList(growable: false);
}
