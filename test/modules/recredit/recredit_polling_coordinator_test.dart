import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/recredit/recredit_polling_coordinator.dart';

void main() {
  test('retries threats 2 and stops after threats 1', () async {
    var requestCount = 0;
    final coordinator = RecreditPollingCoordinator(
      request: () async {
        requestCount += 1;
        return _response(requestCount == 1 ? 2 : 1);
      },
      currentRoute: () => '/other',
      interval: Duration.zero,
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-1');

    await _waitUntil(() => requestCount == 2 && !coordinator.isRunning);
    expect(requestCount, 2);
  });

  test('retries after request exception and stops after threats 1', () async {
    var requestCount = 0;
    final coordinator = RecreditPollingCoordinator(
      request: () async {
        requestCount += 1;
        if (requestCount == 1) {
          throw StateError('temporary failure');
        }
        return _response(1);
      },
      currentRoute: () => '/other',
      interval: Duration.zero,
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-1');

    await _waitUntil(() => requestCount == 2 && !coordinator.isRunning);
    expect(requestCount, 2);
  });

  test(
    'recredit completion admits trimmed product without home refresh',
    () async {
      var homeRefreshCount = 0;
      final admittedProductIds = <String>[];
      final coordinator = RecreditPollingCoordinator(
        request: () async => _response(1),
        currentRoute: () => AppRoutes.recredit,
        homeRefresher: () async {
          homeRefreshCount += 1;
        },
        admissionRunner: (productId) async {
          admittedProductIds.add(productId);
        },
        interval: Duration.zero,
      );
      addTearDown(coordinator.stop);

      coordinator.start('  product-2  ');

      await _waitUntil(() => admittedProductIds.isNotEmpty);
      expect(admittedProductIds, ['product-2']);
      expect(homeRefreshCount, 0);
      expect(coordinator.isRunning, isFalse);
    },
  );

  test('main completion refreshes home without admission', () async {
    var homeRefreshCount = 0;
    var admissionCount = 0;
    final coordinator = RecreditPollingCoordinator(
      request: () async => _response(1),
      currentRoute: () => AppRoutes.main,
      homeRefresher: () async {
        homeRefreshCount += 1;
      },
      admissionRunner: (_) async {
        admissionCount += 1;
      },
      interval: Duration.zero,
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-3');

    await _waitUntil(() => homeRefreshCount == 1);
    expect(admissionCount, 0);
    expect(coordinator.isRunning, isFalse);
  });

  test('empty product id does not request or start', () async {
    var requestCount = 0;
    final coordinator = RecreditPollingCoordinator(
      request: () async {
        requestCount += 1;
        return _response(1);
      },
      interval: Duration.zero,
    );
    addTearDown(coordinator.stop);

    coordinator.start('   ');
    await Future<void>.delayed(Duration.zero);

    expect(requestCount, 0);
    expect(coordinator.isRunning, isFalse);
  });

  test('unknown threats result retries instead of stopping', () async {
    var requestCount = 0;
    final coordinator = RecreditPollingCoordinator(
      request: () async {
        requestCount += 1;
        return _response(requestCount == 1 ? 99 : 1);
      },
      currentRoute: () => '/other',
      interval: Duration.zero,
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-4');

    await _waitUntil(() => requestCount == 2 && !coordinator.isRunning);
    expect(requestCount, 2);
  });

  test('ignores a successful response completed after stop', () async {
    final responseCompleter = Completer<ApiResponse>();
    var requestCount = 0;
    var homeRefreshCount = 0;
    var admissionCount = 0;
    final coordinator = RecreditPollingCoordinator(
      request: () {
        requestCount += 1;
        return responseCompleter.future;
      },
      currentRoute: () => AppRoutes.recredit,
      homeRefresher: () async {
        homeRefreshCount += 1;
      },
      admissionRunner: (_) async {
        admissionCount += 1;
      },
      interval: Duration.zero,
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-stopped');
    await _waitUntil(() => requestCount == 1);
    coordinator.stop();
    responseCompleter.complete(_response(1));
    await _flushEvents();

    expect(homeRefreshCount, 0);
    expect(admissionCount, 0);
    expect(coordinator.isRunning, isFalse);
  });

  test(
    'new start supersedes an in-flight request from the old product',
    () async {
      final oldResponse = Completer<ApiResponse>();
      final newResponse = Completer<ApiResponse>();
      var requestCount = 0;
      final admittedProductIds = <String>[];
      final coordinator = RecreditPollingCoordinator(
        request: () {
          requestCount += 1;
          return requestCount == 1 ? oldResponse.future : newResponse.future;
        },
        currentRoute: () => AppRoutes.recredit,
        admissionRunner: (productId) async {
          admittedProductIds.add(productId);
        },
        interval: Duration.zero,
      );
      addTearDown(coordinator.stop);

      coordinator.start('product-old');
      await _waitUntil(() => requestCount == 1);
      coordinator.start(' product-new ');
      await _waitUntil(() => requestCount == 2);

      newResponse.complete(_response(1));
      await _waitUntil(() => admittedProductIds.isNotEmpty);
      oldResponse.complete(_response(1));
      await _flushEvents();

      expect(admittedProductIds, ['product-new']);
      expect(coordinator.isRunning, isFalse);
    },
  );

  test('logs completion callback errors and remains stopped', () async {
    var requestCount = 0;
    final logs = <String>[];
    final coordinator = RecreditPollingCoordinator(
      request: () async {
        requestCount += 1;
        return _response(1);
      },
      currentRoute: () => AppRoutes.recredit,
      admissionRunner: (_) async {
        throw StateError('admission failed');
      },
      logger: logs.add,
      interval: Duration.zero,
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-error');
    await _waitUntil(() => logs.isNotEmpty);
    await _flushEvents();

    expect(requestCount, 1);
    expect(coordinator.isRunning, isFalse);
    expect(logs.single, contains('recredit completion failed:'));
    expect(logs.single, contains('admission failed'));
  });
}

ApiResponse _response(int threats) {
  return ApiResponse(
    code: 0,
    message: 'success',
    states: Json({'threats': threats}),
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 100; i += 1) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met before timeout');
}

Future<void> _flushEvents() async {
  for (var i = 0; i < 10; i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
