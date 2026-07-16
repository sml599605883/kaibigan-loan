import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/modules/orders/order_list_models.dart';

void main() {
  test('parses product id and card redirect target from order payload', () {
    final item = OrderListItem.fromJson(
      Json({'seamounts': 42, 'overrule': ' /order/detail?orderId=4 '}),
    );

    expect(item.productId, '42');
    expect(item.redirectTarget, '/order/detail?orderId=4');
  });
}
