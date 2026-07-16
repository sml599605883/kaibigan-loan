import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/modules/certification/widgets/certification_retention_guard.dart';

void main() {
  test('falls back to default back when popup is unavailable', () async {
    var defaultBackCount = 0;

    await CertificationRetentionGuard.handleBack(
      type: '0',
      productId: 'product-1',
      onDefaultBack: () => defaultBackCount++,
      presenter: ({required type, required productId, required onExit}) async {
        expect(type, '0');
        expect(productId, 'product-1');
        return false;
      },
    );

    expect(defaultBackCount, 1);
  });

  test('keeps current page when popup is shown', () async {
    var defaultBackCount = 0;

    await CertificationRetentionGuard.handleBack(
      type: '1',
      productId: 'product-1',
      onDefaultBack: () => defaultBackCount++,
      presenter: ({required type, required productId, required onExit}) async {
        return true;
      },
    );

    expect(defaultBackCount, 0);
  });
}
