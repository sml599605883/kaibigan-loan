import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/report/report_device_collector.dart';
import 'package:kaibigan_loan/src/core/report/report_models.dart';

void main() {
  test(
    'fills missing snapshot fields from package and device plugins',
    () async {
      final collector = ReportDeviceCollector(
        nativeSnapshotProvider: () async {
          return const NativeDeviceSnapshot(
            idfv: 'native-idfv',
            brand: 'NativeBrand',
          );
        },
        packageInfoProvider: () async {
          return const ReportPackageSnapshot(
            packageName: 'loan.kaibigan.app',
            appVersion: '1.2.3',
            buildNumber: '45',
          );
        },
        deviceInfoProvider: () async {
          return <String, dynamic>{
            'systemVersion': '17.5',
            'model': 'iPhone',
            'name': 'User iPhone',
            'utsname': {'machine': 'iPhone15,3'},
            'isPhysicalDevice': true,
          };
        },
      );

      final snapshot = await collector.collect();

      expect(snapshot.idfv, 'native-idfv');
      expect(snapshot.brand, 'NativeBrand');
      expect(snapshot.packageName, 'loan.kaibigan.app');
      expect(snapshot.appVersion, '1.2.3');
      expect(snapshot.systemVersion, '17.5');
      expect(snapshot.model, 'iPhone15,3');
      expect(snapshot.deviceName, 'User iPhone');
      expect(snapshot.isEmulator, 0);
    },
  );
}
