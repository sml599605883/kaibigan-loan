class ReportLocation {
  const ReportLocation({
    this.province,
    this.locality,
    required this.fullAddress,
    required this.countryCode,
    required this.country,
    required this.street,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.permissionStatus = '',
  });

  factory ReportLocation.fromMap(Map<String, dynamic> map) {
    return ReportLocation(
      province: _nullableString(map['province']),
      locality: _nullableString(map['locality'] ?? map['subAdminArea']),
      fullAddress: _stringValue(map['fullAddress']),
      countryCode: _stringValue(map['countryCode']),
      country: _stringValue(map['country']),
      street: _stringValue(map['street']),
      latitude: _stringValue(map['latitude']),
      longitude: _stringValue(map['longitude']),
      city: _stringValue(map['city']),
      permissionStatus: _stringValue(map['permissionStatus']),
    );
  }

  final String? province;
  final String? locality;
  final String fullAddress;
  final String countryCode;
  final String country;
  final String street;
  final String latitude;
  final String longitude;
  final String city;
  final String permissionStatus;

  bool get isValid {
    return latitude.isNotEmpty ||
        longitude.isNotEmpty ||
        fullAddress.isNotEmpty ||
        street.isNotEmpty ||
        city.isNotEmpty ||
        country.isNotEmpty;
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'province': province,
      'locality': locality,
      'fullAddress': fullAddress,
      'countryCode': countryCode,
      'country': country,
      'street': street,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'permissionStatus': permissionStatus,
    };
  }

  static String _stringValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }

  static String? _nullableString(Object? value) {
    final text = _stringValue(value);
    return text.isEmpty ? null : text;
  }
}

class NativeDeviceSnapshot {
  const NativeDeviceSnapshot({
    this.idfv = '',
    this.idfa = '',
    this.deviceId = '',
    this.batteryLevel = 0,
    this.isCharging = 0,
    this.elapsedMillis = 0,
    this.uptimeMillis = '0',
    this.isUsingProxy = 0,
    this.isUsingVpn = 0,
    this.isJailbroken = 0,
    this.isEmulator = 0,
    this.language = '',
    this.carrier = '',
    this.networkType = '',
    this.timeZoneName = '',
    this.cpuCoreCount = 0,
    this.brand = '',
    this.deviceName = '',
    this.model = '',
    this.systemVersion = '',
    this.appVersion = '',
    this.packageName = '',
    this.screenHeight = 0,
    this.screenWidth = 0,
    this.screenSize = '0',
    this.innerIp = '',
    this.currentWifiName = '',
    this.currentWifiBssid = '',
    this.wifiCount = 0,
    this.availableStorage = '0',
    this.totalStorage = '0',
    this.totalMemory = '0',
    this.availableMemory = '0',
    this.pushToken = '',
    this.riskDeviceId = '',
  });

  factory NativeDeviceSnapshot.fromMap(Map<String, dynamic> map) {
    return NativeDeviceSnapshot(
      idfv: _stringValue(map['idfv']),
      idfa: _stringValue(map['idfa']),
      deviceId: _stringValue(map['deviceId']),
      batteryLevel: _intValue(map['batteryLevel']),
      isCharging: _intValue(map['isCharging']),
      elapsedMillis: _intValue(map['elapsedMillis']),
      uptimeMillis: _stringValue(map['uptimeMillis'], fallback: '0'),
      isUsingProxy: _intValue(map['isUsingProxy']),
      isUsingVpn: _intValue(map['isUsingVpn']),
      isJailbroken: _intValue(map['isJailbroken']),
      isEmulator: _intValue(map['isEmulator']),
      language: _stringValue(map['language']),
      carrier: _stringValue(map['carrier']),
      networkType: _stringValue(map['networkType']),
      timeZoneName: _stringValue(map['timeZoneName']),
      cpuCoreCount: _intValue(map['cpuCoreCount']),
      brand: _stringValue(map['brand']),
      deviceName: _stringValue(map['deviceName']),
      model: _stringValue(map['model']),
      systemVersion: _stringValue(map['systemVersion']),
      appVersion: _stringValue(map['appVersion']),
      packageName: _stringValue(map['packageName']),
      screenHeight: _intValue(map['screenHeight']),
      screenWidth: _intValue(map['screenWidth']),
      screenSize: _stringValue(map['screenSize']),
      innerIp: _stringValue(map['innerIp']),
      currentWifiName: _stringValue(map['currentWifiName']),
      currentWifiBssid: _stringValue(map['currentWifiBssid']),
      wifiCount: _intValue(map['wifiCount']),
      availableStorage: _stringValue(map['availableStorage'], fallback: '0'),
      totalStorage: _stringValue(map['totalStorage'], fallback: '0'),
      totalMemory: _stringValue(map['totalMemory'], fallback: '0'),
      availableMemory: _stringValue(map['availableMemory'], fallback: '0'),
      pushToken: _stringValue(map['pushToken']),
      riskDeviceId: _stringValue(map['riskDeviceId']),
    );
  }

  final String idfv;
  final String idfa;
  final String deviceId;
  final int batteryLevel;
  final int isCharging;
  final int elapsedMillis;
  final String uptimeMillis;
  final int isUsingProxy;
  final int isUsingVpn;
  final int isJailbroken;
  final int isEmulator;
  final String language;
  final String carrier;
  final String networkType;
  final String timeZoneName;
  final int cpuCoreCount;
  final String brand;
  final String deviceName;
  final String model;
  final String systemVersion;
  final String appVersion;
  final String packageName;
  final int screenHeight;
  final int screenWidth;
  final String screenSize;
  final String innerIp;
  final String currentWifiName;
  final String currentWifiBssid;
  final int wifiCount;
  final String availableStorage;
  final String totalStorage;
  final String totalMemory;
  final String availableMemory;
  final String pushToken;
  final String riskDeviceId;

  NativeDeviceSnapshot copyWith({
    String? idfv,
    String? idfa,
    String? deviceId,
    int? batteryLevel,
    int? isCharging,
    int? elapsedMillis,
    String? uptimeMillis,
    int? isUsingProxy,
    int? isUsingVpn,
    int? isJailbroken,
    int? isEmulator,
    String? language,
    String? carrier,
    String? networkType,
    String? timeZoneName,
    int? cpuCoreCount,
    String? brand,
    String? deviceName,
    String? model,
    String? systemVersion,
    String? appVersion,
    String? packageName,
    int? screenHeight,
    int? screenWidth,
    String? screenSize,
    String? innerIp,
    String? currentWifiName,
    String? currentWifiBssid,
    int? wifiCount,
    String? availableStorage,
    String? totalStorage,
    String? totalMemory,
    String? availableMemory,
    String? pushToken,
    String? riskDeviceId,
  }) {
    return NativeDeviceSnapshot(
      idfv: idfv ?? this.idfv,
      idfa: idfa ?? this.idfa,
      deviceId: deviceId ?? this.deviceId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      elapsedMillis: elapsedMillis ?? this.elapsedMillis,
      uptimeMillis: uptimeMillis ?? this.uptimeMillis,
      isUsingProxy: isUsingProxy ?? this.isUsingProxy,
      isUsingVpn: isUsingVpn ?? this.isUsingVpn,
      isJailbroken: isJailbroken ?? this.isJailbroken,
      isEmulator: isEmulator ?? this.isEmulator,
      language: language ?? this.language,
      carrier: carrier ?? this.carrier,
      networkType: networkType ?? this.networkType,
      timeZoneName: timeZoneName ?? this.timeZoneName,
      cpuCoreCount: cpuCoreCount ?? this.cpuCoreCount,
      brand: brand ?? this.brand,
      deviceName: deviceName ?? this.deviceName,
      model: model ?? this.model,
      systemVersion: systemVersion ?? this.systemVersion,
      appVersion: appVersion ?? this.appVersion,
      packageName: packageName ?? this.packageName,
      screenHeight: screenHeight ?? this.screenHeight,
      screenWidth: screenWidth ?? this.screenWidth,
      screenSize: screenSize ?? this.screenSize,
      innerIp: innerIp ?? this.innerIp,
      currentWifiName: currentWifiName ?? this.currentWifiName,
      currentWifiBssid: currentWifiBssid ?? this.currentWifiBssid,
      wifiCount: wifiCount ?? this.wifiCount,
      availableStorage: availableStorage ?? this.availableStorage,
      totalStorage: totalStorage ?? this.totalStorage,
      totalMemory: totalMemory ?? this.totalMemory,
      availableMemory: availableMemory ?? this.availableMemory,
      pushToken: pushToken ?? this.pushToken,
      riskDeviceId: riskDeviceId ?? this.riskDeviceId,
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') {
      return fallback;
    }
    return text;
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }
}

class FaceReportPayload {
  const FaceReportPayload({
    required this.livenessId,
    required this.requestId,
    required this.resultCode,
    required this.resultMessage,
  });

  final String livenessId;
  final String requestId;
  final String resultCode;
  final String resultMessage;
}
