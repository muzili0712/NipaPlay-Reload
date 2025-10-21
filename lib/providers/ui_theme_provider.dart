import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

enum UIThemeType {
  nipaplay,
  fluentUI,
  liquidGlass,
}

class UIThemeProvider extends ChangeNotifier {
  static const String _key = 'ui_theme_type';
  static const String _fluentThemeModeKey = 'fluent_theme_mode';
  UIThemeType _currentTheme = UIThemeType.nipaplay;
  ThemeMode _fluentThemeMode = ThemeMode.dark;
  bool _isInitialized = false;

  UIThemeType get currentTheme => _currentTheme;
  bool get isInitialized => _isInitialized;
  ThemeMode get fluentThemeMode => _fluentThemeMode;

  bool get isNipaplayTheme => _currentTheme == UIThemeType.nipaplay;
  bool get isFluentUITheme => _currentTheme == UIThemeType.fluentUI;
  bool get isLiquidGlassTheme => _currentTheme == UIThemeType.liquidGlass;

  /// 获取当前平台允许的主题列表
  List<UIThemeType> get availableThemes {
    if (_isIOSPlatform() || _isAndroidPlatform()) {
      // iOS 和 Android 只允许默认主题和液态玻璃
      return [UIThemeType.nipaplay, UIThemeType.liquidGlass];
    } else {
      // 桌面平台允许所有主题
      return UIThemeType.values;
    }
  }

  /// 检查指定主题是否可用
  bool isThemeAvailable(UIThemeType theme) {
    return availableThemes.contains(theme);
  }

  UIThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasStoredTheme = prefs.containsKey(_key);
      final storedIndex = prefs.getInt(_key);

      if (storedIndex != null &&
          storedIndex >= 0 &&
          storedIndex < UIThemeType.values.length) {
        _currentTheme = UIThemeType.values[storedIndex];
      } else {
        _currentTheme = _defaultThemeForPlatform();
        await prefs.setInt(_key, _currentTheme.index);
      }

      // iOS 和 Android 限制只能是默认或液态玻璃
      if ((_isIOSPlatform() || _isAndroidPlatform()) &&
          _currentTheme != UIThemeType.nipaplay &&
          _currentTheme != UIThemeType.liquidGlass) {
        _currentTheme = _defaultThemeForPlatform();
        await prefs.setInt(_key, _currentTheme.index);
      } else if (!hasStoredTheme && _currentTheme != UIThemeType.nipaplay) {
        await prefs.setInt(_key, _currentTheme.index);
      }

      final storedMode = prefs.getString(_fluentThemeModeKey);
      if (storedMode != null) {
        _fluentThemeMode = _themeModeFromString(storedMode);
      }
    } catch (e) {
      debugPrint('加载UI主题设置失败: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setTheme(UIThemeType theme) async {
    // iOS 和 Android 只允许在默认主题和液态玻璃之间切换
    if (_isIOSPlatform() || _isAndroidPlatform()) {
      if (theme != UIThemeType.nipaplay && theme != UIThemeType.liquidGlass) {
        return;
      }
    }

    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_key, theme.index);
      } catch (e) {
        debugPrint('保存UI主题设置失败: $e');
      }
    }
  }

  Future<void> setFluentThemeMode(ThemeMode mode) async {
    if (_fluentThemeMode != mode) {
      _fluentThemeMode = mode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_fluentThemeModeKey, _themeModeToString(mode));
      } catch (e) {
        debugPrint('保存Fluent主题外观设置失败: $e');
      }
    }
  }

  String getThemeName(UIThemeType theme) {
    switch (theme) {
      case UIThemeType.nipaplay:
        return 'NipaPlay';
      case UIThemeType.fluentUI:
        return 'Fluent UI';
      case UIThemeType.liquidGlass:
        return 'Liquid Glass';
    }
  }

  UIThemeType _defaultThemeForPlatform() {
    // iOS 默认液态玻璃，Android 默认 NipaPlay
    if (_isIOSPlatform()) {
      return UIThemeType.liquidGlass;
    }
    return UIThemeType.nipaplay;
  }

  bool _isIOSPlatform() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool _isAndroidPlatform() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
