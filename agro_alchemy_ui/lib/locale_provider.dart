import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String prefKey = 'locale';

  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  void setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, locale.languageCode);
  }

  void _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(prefKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }
}
