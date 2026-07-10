import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/report/report_attribution_initializer.dart';

void main() {
  test('starts Adjust with production environment token', () async {
    late String capturedToken;
    late ReportAttributionEnvironment capturedEnvironment;
    final initializer = AdjustReportAttributionInitializer(
      initSdk: ({required token, required environment}) {
        capturedToken = token;
        capturedEnvironment = environment;
      },
    );

    await initializer.initialize(' adjust-token ');

    expect(capturedToken, 'adjust-token');
    expect(capturedEnvironment, ReportAttributionEnvironment.production);
  });

  test('ignores empty tokens', () async {
    var initCount = 0;
    final initializer = AdjustReportAttributionInitializer(
      initSdk: ({required token, required environment}) {
        initCount++;
      },
    );

    await initializer.initialize(' ');

    expect(initCount, 0);
  });
}
