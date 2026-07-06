import 'package:get/get.dart' as getx;
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore(this._preferences) : _persistentMemory = null;

  SessionStore.memory()
    : _preferences = null,
      _persistentMemory = <String, Object?>{};

  static SessionStore get instance => getx.Get.find<SessionStore>();

  static const loggedInKey = 'session.logged_in';
  static const phoneKey = 'session.phone';
  static const bungeeKey = 'session.bungee';
  static const gyrofrequencyKey = 'device_info.gyrofrequency';
  static const entertainersKey = 'device_info.entertainers';

  final SharedPreferencesAsync? _preferences;
  final Map<String, Object?>? _persistentMemory;
  final Map<String, Object?> _cache = <String, Object?>{};

  Future<bool> isLoggedIn() async {
    final memory = _persistentMemory;
    if (memory != null) {
      return memory[loggedInKey] == true;
    }
    return await _preferences!.getBool(loggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final memory = _persistentMemory;
    if (memory != null) {
      memory[loggedInKey] = value;
      return;
    }
    await _preferences!.setBool(loggedInKey, value);
  }

  Future<String> phone() async {
    return _persistentString(phoneKey);
  }

  Future<void> savePhone(String value) async {
    await _setPersistentString(phoneKey, value);
  }

  Future<String> gyrofrequency() async {
    return _persistentString(gyrofrequencyKey);
  }

  Future<String> bungee() async {
    return _persistentString(bungeeKey);
  }

  Future<void> saveBungee(String value) async {
    await _setPersistentString(bungeeKey, value);
  }

  Future<String> entertainers() async {
    return _persistentString(entertainersKey);
  }

  Future<void> saveDeviceInfo({
    required String gyrofrequency,
    required String entertainers,
  }) async {
    await _setPersistentString(gyrofrequencyKey, gyrofrequency);
    await _setPersistentString(entertainersKey, entertainers);
  }

  Future<void> saveCacheValue(String key, Object? value) async {
    _cache[key] = value;
  }

  Object? cacheValue(String key) {
    return _cache[key];
  }

  Future<void> clearPersistent() async {
    final memory = _persistentMemory;
    if (memory != null) {
      memory
        ..remove(loggedInKey)
        ..remove(bungeeKey)
        ..remove(gyrofrequencyKey)
        ..remove(entertainersKey);
      return;
    }
    await _preferences!.remove(loggedInKey);
    await _preferences.remove(bungeeKey);
    await _preferences.remove(gyrofrequencyKey);
    await _preferences.remove(entertainersKey);
  }

  Future<void> clearCache() async {
    _cache.clear();
  }

  Future<String> _persistentString(String key) async {
    final memory = _persistentMemory;
    if (memory != null) {
      return memory[key] as String? ?? '';
    }
    return await _preferences!.getString(key) ?? '';
  }

  Future<void> _setPersistentString(String key, String value) async {
    final memory = _persistentMemory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setString(key, value);
  }
}
