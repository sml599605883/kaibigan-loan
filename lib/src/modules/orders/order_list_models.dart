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
    required this.productName,
    required this.amountText,
    required this.statusText,
    required this.dateValue,
    required this.dateLabel,
    required this.actionText,
  });

  factory OrderListItem.fromJson(Json json) {
    return OrderListItem(
      productName: _firstText(json, const [
        'appName',
        'productName',
        'product_name',
        'omissible',
        'macromeres',
      ]),
      amountText: _firstText(json, const [
        'loanAmount',
        'amount',
        'amount_text',
        'display_amount',
        'moneyText',
        'ecumenicalism',
        'giardias',
        'refiners',
        'curite',
      ]),
      statusText: _firstText(json, const [
        'statusText',
        'statusDes',
        'statusName',
        'orderStatusDesc',
        'order_status_text',
        'playhouses',
        'fictitiousness',
        'sememe',
        'deepnesses',
      ]),
      dateValue: _firstText(json, const [
        'dueDate',
        'dateValue',
        'date',
        'origin_end_time',
        'spelts',
        'salvo',
      ]),
      dateLabel: _firstText(json, const [
        'dateText',
        'date_text',
        'sandpainting',
        'tallisim',
      ]),
      actionText: _firstText(json, const [
        'actionText',
        'buttonText',
        'button_text',
        'btn',
        'restless',
        'stoles',
        'berhyming',
      ]),
    );
  }

  final String productName;
  final String amountText;
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

String _firstText(Json json, List<String> keys) {
  for (final key in keys) {
    final value = json[key].stringValue.trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}
