import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts iOS notification routing before runApp', () {
    final content = File('lib/main.dart').readAsStringSync();
    final coordinatorStart = content.indexOf(
      'IosNotificationRouteCoordinator.instance.start()',
    );
    final runApp = content.indexOf('runApp(const KaibiganLoanApp())');

    expect(coordinatorStart, isNonNegative);
    expect(runApp, greaterThan(coordinatorStart));
  });
}
