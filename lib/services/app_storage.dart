import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppStorageKey {
  csrfCookie,
  accessToken,
  fcmToken,
  savedCred,
  encryptedCred,
  savedCredDev,
  encryptedCredDev,
  rememberMe,
  rememberMeDev,
}

enum AppStorageType { secureStorage, sharedPrefs }

class AppStorage {
  static final AppStorage _instance = AppStorage._internal();
  factory AppStorage() => _instance;

  AppStorage._internal();

  late final FlutterSecureStorage storage;
  late final SharedPreferences prefs;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    storage = const FlutterSecureStorage();
    prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
          'AppStorage is not initialized. Call initialize() first.');
    }
  }

  // these are stored in secure storage
  static const String tokenKey = 'accessToken';
  static const String fcmTokenKey = 'fcmToken';
  static const String cookieKey = 'csrfCookie';
  static const String savedCredKey = 'savedCred';
  static const String savedCredDevKey = 'savedCredDev';
  static const String encryptedCredKey = 'encryptedCred';
  static const String encryptedCredDevKey = 'encryptedCredDev';

  // these are stored in shared preferences
  static const String rememberMeKey = 'rememberMe';
  static const String rememberMeDevKey = 'rememberMeDev';

  String _getKeyStr(AppStorageKey key) {
    switch (key) {
      case AppStorageKey.csrfCookie:
        return cookieKey;
      case AppStorageKey.accessToken:
        return tokenKey;
      case AppStorageKey.fcmToken:
        return fcmTokenKey;
      case AppStorageKey.savedCred:
        return savedCredKey;
      case AppStorageKey.encryptedCred:
        return encryptedCredKey;
      case AppStorageKey.savedCredDev:
        return savedCredDevKey;
      case AppStorageKey.encryptedCredDev:
        return encryptedCredDevKey;
      case AppStorageKey.rememberMe:
        return rememberMeKey;
      case AppStorageKey.rememberMeDev:
        return rememberMeDevKey;
    }
  }

  AppStorageType _getStorageType(AppStorageKey key) {
    switch (key) {
      case AppStorageKey.csrfCookie:
      case AppStorageKey.accessToken:
      case AppStorageKey.fcmToken:
      case AppStorageKey.savedCred:
      case AppStorageKey.encryptedCred:
      case AppStorageKey.savedCredDev:
      case AppStorageKey.encryptedCredDev:
        return AppStorageType.secureStorage;
      case AppStorageKey.rememberMe:
      case AppStorageKey.rememberMeDev:
        return AppStorageType.sharedPrefs;
    }
  }

  Future<String?> read(AppStorageKey key) async {
    AppStorageType type = _getStorageType(key);
    String keyStr = _getKeyStr(key);
    String? value;

    _ensureInitialized();

    switch (type) {
      case AppStorageType.secureStorage:
        value = await storage.read(key: keyStr);
        break;
      case AppStorageType.sharedPrefs:
        value = prefs.getString(keyStr);
        break;
    }
    return value;
  }

  Future<void> write(AppStorageKey key, String value) async {
    AppStorageType type = _getStorageType(key);
    String keyStr = _getKeyStr(key);

    _ensureInitialized();

    switch (type) {
      case AppStorageType.secureStorage:
        await storage.write(key: keyStr, value: value);
      case AppStorageType.sharedPrefs:
        await prefs.setString(keyStr, value);
    }
  }

  Future<void> delete(AppStorageKey key) async {
    AppStorageType type = _getStorageType(key);
    String keyStr = _getKeyStr(key);

    _ensureInitialized();

    switch (type) {
      case AppStorageType.secureStorage:
        await storage.delete(key: keyStr);
      case AppStorageType.sharedPrefs:
        await prefs.remove(keyStr);
    }
  }

  Future<void> clear() async {
    _ensureInitialized();

    await storage.deleteAll();
    await prefs.clear();
  }
}
