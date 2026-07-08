import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/session/product_detail_cache.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';

void main() {
  tearDown(Get.reset);

  test('instance resolves the registered session store', () {
    final store = SessionStore.memory();

    Get.put<SessionStore>(store);

    expect(SessionStore.instance, same(store));
  });

  test('separates persistent data from cache data', () async {
    final store = SessionStore.memory();

    await store.setLoggedIn(true);
    await store.savePhone('09171234567');
    await store.saveDeviceInfo(
      gyrofrequency: 'iPhone X',
      entertainers: '375x812',
    );
    await store.saveBungee('user-token');
    await store.saveCacheValue('otp.request.id', 'request-1');

    expect(await store.isLoggedIn(), isTrue);
    expect(await store.phone(), '09171234567');
    expect(await store.gyrofrequency(), 'iPhone X');
    expect(await store.entertainers(), '375x812');
    expect(await store.bungee(), 'user-token');
    expect(store.cacheValue('otp.request.id'), 'request-1');

    await store.clearCache();

    expect(await store.isLoggedIn(), isTrue);
    expect(await store.phone(), '09171234567');
    expect(await store.gyrofrequency(), 'iPhone X');
    expect(await store.entertainers(), '375x812');
    expect(await store.bungee(), 'user-token');
    expect(store.cacheValue('otp.request.id'), isNull);

    await store.clearPersistent();

    expect(await store.isLoggedIn(), isFalse);
    expect(await store.phone(), '09171234567');
    expect(await store.gyrofrequency(), '');
    expect(await store.entertainers(), '');
    expect(await store.bungee(), '');
  });

  test('stores product detail cache in temporary memory only', () async {
    final store = SessionStore.memory();
    final detail = ProductDetailCache.fromJson({
      'sensitized': {
        'ecumenicalism': '3000',
        'cabdrivers': 'product-1',
        'chattinesses': 'ORDER001',
        'joyriding': 'loan-name',
        'desertifying': '91',
        'tythes': '1',
      },
      'metallurgists': {'aimless': 'Upload your PRC ID front.'},
      'grinner': {'unconfusing': 'MistermEncystment'},
    });

    await store.saveProductDetailCache(detail);

    expect(store.productDetailCache(), isNotNull);
    expect(store.productDetailCache()!.productid, 'product-1');
    expect(store.productDetailCache()!.amount, '3000');
    expect(store.productDetailCache()!.orderNo, 'ORDER001');
    expect(store.productDetailCache()!.orderId, 'loan-name');
    expect(store.productDetailCache()!.term, '91');
    expect(store.productDetailCache()!.termType, '1');
    expect(
      store.productDetailCache()!.note['base'],
      'Upload your PRC ID front.',
    );
    expect(store.productDetailCache()!.note.containsKey('aimless'), isFalse);
    expect(
      store.productDetailCache()!.nextStep['taskType'],
      'MistermEncystment',
    );
    expect(
      store.productDetailCache()!.nextStep.containsKey('unconfusing'),
      isFalse,
    );

    await store.clearCache();

    expect(store.productDetailCache(), isNull);
  });
}
