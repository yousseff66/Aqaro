import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError();
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _themeKey = 'theme';
  static const String _langKey = 'lang';

  Future<void> setToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> setThemeMode(bool isDarkMode) async {
    await _prefs.setBool(_themeKey, isDarkMode);
  }

  bool? getThemeMode() {
    return _prefs.getBool(_themeKey);
  }

  Future<void> setLanguage(String langCode) async {
    await _prefs.setString(_langKey, langCode);
  }

  String? getLanguage() {
    return _prefs.getString(_langKey);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
