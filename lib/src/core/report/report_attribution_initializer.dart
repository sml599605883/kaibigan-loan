import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';

enum ReportAttributionEnvironment { production, sandbox }

abstract interface class ReportAttributionInitializer {
  Future<void> initialize(String token);
}

typedef AdjustInitSdk =
    void Function({
      required String token,
      required ReportAttributionEnvironment environment,
    });

class AdjustReportAttributionInitializer
    implements ReportAttributionInitializer {
  AdjustReportAttributionInitializer({
    ReportAttributionEnvironment environment =
        ReportAttributionEnvironment.production,
    AdjustInitSdk? initSdk,
  }) : _environment = environment,
       _initSdk = initSdk ?? _defaultInitSdk;

  final ReportAttributionEnvironment _environment;
  final AdjustInitSdk _initSdk;

  @override
  Future<void> initialize(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      return;
    }
    _initSdk(token: normalized, environment: _environment);
  }

  static void _defaultInitSdk({
    required String token,
    required ReportAttributionEnvironment environment,
  }) {
    final config = AdjustConfig(
      token,
      environment == ReportAttributionEnvironment.production
          ? AdjustEnvironment.production
          : AdjustEnvironment.sandbox,
    );
    config.logLevel = AdjustLogLevel.info;
    Adjust.initSdk(config);
  }
}
