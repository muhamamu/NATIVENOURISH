import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _accentName = 'Teal';
  bool _disposed = false;
  int _revision = 0;
  late final Future<void> ready;
  Future<void> _writes = Future<void>.value();

  ThemeProvider() { ready = _load(); }
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get accentName => _accentName;

  Future<void> _load() async {
    final revision = _revision;
    try {
      final mode = await DatabaseHelper.instance.getSetting('theme_mode');
      final accent = await DatabaseHelper.instance.getSetting('accent');
      if (_disposed || revision != _revision) return;
      _themeMode = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
      AppColors.isDark = _themeMode == ThemeMode.dark;
      _accentName = AppColors.accentColors.containsKey(accent) ? accent! : 'Teal';
      AppColors.accent = AppColors.accentColors[_accentName]!;
      notifyListeners();
    } catch (error) { debugPrint('Could not load appearance: $error'); }
  }

  Future<void> _persist() {
    final mode = isDarkMode ? 'dark' : 'light';
    final accent = _accentName;
    final result = _writes.then((_) async {
      await DatabaseHelper.instance.setSetting('theme_mode', mode);
      await DatabaseHelper.instance.setSetting('accent', accent);
    });
    _writes = result.catchError((Object error) { debugPrint('Could not save appearance: $error'); });
    return result;
  }

  Future<void> toggleTheme(bool isDark) async {
    _revision++;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppColors.isDark = isDark;
    notifyListeners();
    await _persist();
  }

  Future<void> setAccent(String name) async {
    if (!AppColors.accentColors.containsKey(name)) return;
    _revision++;
    _accentName = name;
    AppColors.accent = AppColors.accentColors[name]!;
    notifyListeners();
    await _persist();
  }

  @override
  void dispose() { _disposed = true; super.dispose(); }
}
