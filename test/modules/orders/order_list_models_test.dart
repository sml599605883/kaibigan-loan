import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/orders/order_list_models.dart';

void main() {
  test('parses the documented order-list payload fields', () {
    final item = OrderListItem.fromJson(
      Json({
        'seamounts': 42,
        'overrule': ' /order/detail?orderId=4 ',
        'omissible': 'Kaibigan Loan',
        'biontic': 'https://cdn.example.test/logo.png',
        'ecumenicalism': '₱ 8,000',
        'curite': 'Loan Amount',
        'playhouses': 'Waiting to confirm usage',
        'spelts': '27-07-2026',
        'sandpainting': 'Application Date',
        'restless': 'Details',
      }),
    );

    expect(item.productId, '42');
    expect(item.redirectTarget, '/order/detail?orderId=4');
    expect(item.productName, 'Kaibigan Loan');
    expect(item.productLogo, 'https://cdn.example.test/logo.png');
    expect(item.amountText, '₱ 8,000');
    expect(item.amountLabel, 'Loan Amount');
    expect(item.statusText, 'Waiting to confirm usage');
    expect(item.dateValue, '27-07-2026');
    expect(item.dateLabel, 'Application Date');
    expect(item.actionText, 'Details');
  });
}
