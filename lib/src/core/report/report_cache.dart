import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../json/json.dart';
import '../session/session_store.dart';
import 'report_models.dart';

abstract interface class ReportCache {
  Future<bool> markAppOpened();
  Future<void> setLoginAt(int millis);
  Future<int> getLoginAt();
  Future<bool> isAttributionInitialized();
  Future<void> setAttributionInitialized(bool value);
  Future<void> setAttributionLastStatus(String value);
  Future<String> getAttributionLastStatus();
  Future<void> saveLocation(ReportLocation location);
  Future<ReportLocation?> getLocation();
  Future<String> getLastMarketSignature();
  Future<void> setLastMarketSignature(String signature);
  Future<String> getLastPushToken();
  Future<void> setLastPushToken(String token);
  Future<bool> isLoggedIn();
  Future<void> clearSessionReportState();
}

class SharedPreferencesReportCache implements ReportCache {
  SharedPreferencesReportCache({required SessionStore sessionStore})
    : _sessionStore = sessionStore;

  static const _keyHasOpened = 'report.has_opened';
  static const _keyLoginAt = 'report.login_at';
  static const _keyAttributionInitialized = 'report.attribution_initialized';
  static const _keyAttributionLastStatus = 'report.attribution_last_status';
  static const _keyCachedLocation = 'report.cached_location';
  static const _keyLastMarketSignature = 'report.last_market_signature';
  static const _keyLastPushToken = 'report.last_push_token';

  final SessionStore _sessionStore;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  Future<bool> markAppOpened() async {
    final prefs = await _prefs();
    final firstLaunch = !(prefs.getBool(_keyHasOpened) ?? false);
    await prefs.setBool(_keyHasOpened, true);
    return firstLaunch;
  }

  @override
  Future<void> setLoginAt(int millis) async {
    await (await _prefs()).setInt(_keyLoginAt, millis);
  }

  @override
  Future<int> getLoginAt() async {
    return (await _prefs()).getInt(_keyLoginAt) ?? 0;
  }

  @override
  Future<bool> isAttributionInitialized() async {
    return (await _prefs()).getBool(_keyAttributionInitialized) ?? false;
  }

  @override
  Future<void> setAttributionInitialized(bool value) async {
    await (await _prefs()).setBool(_keyAttributionInitialized, value);
  }

  @override
  Future<void> setAttributionLastStatus(String value) async {
    await (await _prefs()).setString(_keyAttributionLastStatus, value);
  }

  @override
  Future<String> getAttributionLastStatus() async {
    return (await _prefs()).getString(_keyAttributionLastStatus) ?? '';
  }

  @override
  Future<void> saveLocation(ReportLocation location) async {
    await (await _prefs()).setString(
      _keyCachedLocation,
      jsonEncode(location.toCacheMap()),
    );
  }

  @override
  Future<ReportLocation?> getLocation() async {
    final raw = (await _prefs()).getString(_keyCachedLocation);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final map = Json.parse(raw).rawMapOrNull;
    if (map == null) {
      return null;
    }
    final location = ReportLocation.fromMap(map);
    return location.isValid ? location : null;
  }

  @override
  Future<String> getLastMarketSignature() async {
    return (await _prefs()).getString(_keyLastMarketSignature) ?? '';
  }

  @override
  Future<void> setLastMarketSignature(String signature) async {
    await (await _prefs()).setString(_keyLastMarketSignature, signature);
  }

  @override
  Future<String> getLastPushToken() async {
    return (await _prefs()).getString(_keyLastPushToken) ?? '';
  }

  @override
  Future<void> setLastPushToken(String token) async {
    await (await _prefs()).setString(_keyLastPushToken, token);
  }

  @override
  Future<bool> isLoggedIn() {
    return _sessionStore.isLoggedIn();
  }

  @override
  Future<void> clearSessionReportState() async {
    await (await _prefs()).remove(_keyCachedLocation);
  }
}
