import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = AppTheme.lightTheme;

  ThemeData get themeData => _themeData;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final stored = LocalStorageService.getThemeMode();
    if (stored == 'dark') {
      _themeData = AppTheme.darkTheme;
    } else {
      _themeData = AppTheme.lightTheme;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeData = mode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    await LocalStorageService.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
