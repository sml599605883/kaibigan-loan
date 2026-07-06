import 'package:shared_preferences/shared_preferences.dart';

import '../client/client_bridge.dart';
import '../session/session_store.dart';

typedef AuthExpiredHandler = Future<void> Function();
typedef TimestampProvider = int Function();
typedef RandomDigitsProvider = String Function(int length);

class ApiConfig {
  ApiConfig({
    this.apiBaseUrl = 'http://8.220.135.86/boltonite',
    this.webBaseUrl = 'http://8.220.135.86',
    this.remoteConfigUrl = '',
    this.signatureSecret = '75a27d5e3777eab04a2efdc2389219f7',
    this.encryptKey = 'c1a4f87da09bab88',
    this.encryptIv = 'e250269f537f3f9b',
    ClientBridge? clientBridge,
    SessionStore? sessionStore,
    this.authExpiredHandler,
    this.timestampProvider,
    this.randomDigitsProvider,
  }) : clientBridge = clientBridge ?? ClientBridge(),
       _sessionStore = sessionStore;

  String apiBaseUrl;
  String webBaseUrl;
  String remoteConfigUrl;
  String signatureSecret;
  String encryptKey;
  String encryptIv;
  ClientBridge clientBridge;
  SessionStore? _sessionStore;
  AuthExpiredHandler? authExpiredHandler;
  TimestampProvider? timestampProvider;
  RandomDigitsProvider? randomDigitsProvider;

  SessionStore get sessionStore {
    return _sessionStore ??= SessionStore(SharedPreferencesAsync());
  }
}
