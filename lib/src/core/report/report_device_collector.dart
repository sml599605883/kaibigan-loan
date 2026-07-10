import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'report_models.dart';

class ReportPackageSnapshot {
  const ReportPackageSnapshot({
    required this.packageName,
    required this.appVersion,
    required this.buildNumber,
  });

  final String packageName;
  final String appVersion;
  final String buildNumber;
}

typedef NativeSnapshotProvider = Future<NativeDeviceSnapshot> Function();
typedef ReportPackageInfoProvider = Future<ReportPackageSnapshot> Function();
typedef ReportDeviceInfoProvider = Future<Map<String, dynamic>> Function();

class ReportDeviceCollector {
  ReportDeviceCollector({
    required NativeSnapshotProvider nativeSnapshotProvider,
    ReportPackageInfoProvider? packageInfoProvider,
    ReportDeviceInfoProvider? deviceInfoProvider,
  }) : _nativeSnapshotProvider = nativeSnapshotProvider,
       _packageInfoProvider = packageInfoProvider ?? _defaultPackageInfo,
       _deviceInfoProvider = deviceInfoProvider ?? _defaultDeviceInfo;

  final NativeSnapshotProvider _nativeSnapshotProvider;
  final ReportPackageInfoProvider _packageInfoProvider;
  final ReportDeviceInfoProvider _deviceInfoProvider;

  Future<NativeDeviceSnapshot> collect() async {
    final native = await _nativeSnapshotProvider();
    final package = await _safePackageInfo();
    final device = await _safeDeviceInfo();
    final machine = _stringValue(_nested(device, 'utsname', 'machine'));
    final model = _firstNonEmpty([
      native.model,
      machine,
      _stringValue(device['model']),
      _stringValue(device['device']),
      _stringValue(device['machine']),
    ]);

    return native.copyWith(
      packageName: _firstNonEmpty([native.packageName, package.packageName]),
      appVersion: _firstNonEmpty([native.appVersion, package.appVersion]),
      systemVersion: _firstNonEmpty([
        native.systemVersion,
        _stringValue(device['systemVersion']),
        _stringValue(device['version.release']),
        _stringValue(_nested(device, 'version', 'release')),
        _stringValue(device['osRelease']),
      ]),
      brand: _firstNonEmpty([
        native.brand,
        _stringValue(device['brand']),
        _stringValue(device['manufacturer']),
      ]),
      model: model,
      deviceName: _firstNonEmpty([
        native.deviceName,
        _stringValue(device['name']),
        _stringValue(device['device']),
        model,
      ]),
      isEmulator: native.isEmulator != 0
          ? native.isEmulator
          : _isPhysicalDevice(device) == false
          ? 1
          : 0,
    );
  }

  Future<ReportPackageSnapshot> _safePackageInfo() async {
    try {
      return await _packageInfoProvider();
    } catch (_) {
      return const ReportPackageSnapshot(
        packageName: '',
        appVersion: '',
        buildNumber: '',
      );
    }
  }

  Future<Map<String, dynamic>> _safeDeviceInfo() async {
    try {
      return await _deviceInfoProvider();
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  static Future<ReportPackageSnapshot> _defaultPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    return ReportPackageSnapshot(
      packageName: info.packageName,
      appVersion: info.version,
      buildNumber: info.buildNumber,
    );
  }

  static Future<Map<String, dynamic>> _defaultDeviceInfo() async {
    final info = await DeviceInfoPlugin().deviceInfo;
    return info.data;
  }

  static String _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final text = _stringValue(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static Object? _nested(
    Map<String, dynamic> map,
    String firstKey,
    String secondKey,
  ) {
    final first = map[firstKey];
    if (first is Map) {
      return first[secondKey] ?? first[secondKey.toString()];
    }
    return null;
  }

  static bool? _isPhysicalDevice(Map<String, dynamic> map) {
    final value = map['isPhysicalDevice'];
    return value is bool ? value : null;
  }

  static String _stringValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }
}
