import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoStore {
  DeviceInfoStore(this._preferences) : _memory = null;

  DeviceInfoStore.memory() : _preferences = null, _memory = <String, String>{};

  static const gyrofrequencyKey = 'device_info.gyrofrequency';
  static const entertainersKey = 'device_info.entertainers';

  final SharedPreferencesAsync? _preferences;
  final Map<String, String>? _memory;

  Future<String> gyrofrequency() async {
    final memory = _memory;
    if (memory != null) {
      return memory[gyrofrequencyKey] ?? '';
    }
    return await _preferences!.getString(gyrofrequencyKey) ?? '';
  }

  Future<String> entertainers() async {
    final memory = _memory;
    if (memory != null) {
      return memory[entertainersKey] ?? '';
    }
    return await _preferences!.getString(entertainersKey) ?? '';
  }

  Future<void> save({
    required String gyrofrequency,
    required String entertainers,
  }) async {
    final memory = _memory;
    if (memory != null) {
      memory[gyrofrequencyKey] = gyrofrequency;
      memory[entertainersKey] = entertainers;
      return;
    }
    await _preferences!.setString(gyrofrequencyKey, gyrofrequency);
    await _preferences.setString(entertainersKey, entertainers);
  }
}
