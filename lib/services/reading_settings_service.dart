import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * 🎨 READING SETTINGS SERVICE - DỊCH VỤ QUẢN LÝ CÀI ĐẶT ĐỌC SÁCH
 * 
 * Service này chịu trách nhiệm lưu trữ và quản lý tất cả các cài đặt cá nhân hóa
 * trải nghiệm đọc sách của người dùng:
 * 
 * 🎯 CHỨC NĂNG CHÍNH:
 * ✅ Lưu/Load cài đặt từ SharedPreferences (persistent storage)
 * ✅ Quản lý font chữ và kích thước (fontSize: 8-30px)
 * ✅ Điều chỉnh chiều cao dòng (lineHeight: 1.0-3.0)
 * ✅ Tùy chỉnh màu sắc (backgroundColor, textColor)
 * ✅ Chế độ đọc (vertical scroll vs horizontal page)
 * ✅ Cài đặt tự động cuộn (autoScrollSpeed)
 * ✅ Chế độ toàn màn hình (fullscreen mode)
 * 
 * 🔧 KIẾN TRÚC TECHNICAL:
 * - Sử dụng Singleton pattern để đảm bảo consistency
 * - Cache in-memory để tối ưu performance
 * - JSON serialization cho việc lưu trữ
 * - Type-safe getters/setters cho từng cài đặt
 * - Default fallback values để đảm bảo stability
 */
class ReadingSettingsService {
  // ========================================================================
  // 🏗️ SINGLETON PATTERN - ĐẢM BẢO CHỈ CÓ MỘT INSTANCE DUY NHẤT
  // ========================================================================
  static final ReadingSettingsService _instance =
      ReadingSettingsService._internal();
  factory ReadingSettingsService() => _instance;
  ReadingSettingsService._internal();

  // Constants for SharedPreferences keys
  static const String _settingsKey = 'reading_settings';
  static const String _fontSizeKey = 'epub_font_size';
  static const String _lineHeightKey = 'epub_line_height';
  static const String _fontFamilyKey = 'epub_font_family';
  static const String _backgroundColorKey = 'epub_background_color';
  static const String _textColorKey = 'epub_text_color';
  static const String _isHorizontalReadingKey = 'epub_is_horizontal_reading';
  static const String _autoScrollSpeedKey = 'epub_auto_scroll_speed';

  // Default values
  static const double defaultFontSize = 16.0;
  static const double defaultLineHeight = 1.5;
  static const String defaultFontFamily = 'Roboto';
  static const int defaultBackgroundColor = 0xFFFFFFFF; // White
  static const int defaultTextColor = 0xFF000000; // Black
  static const bool defaultIsHorizontalReading = false;
  static const double defaultAutoScrollSpeed = 50.0;

  // ========================================================================
  // 🎨 CÀI ĐẶT MẶC ĐỊNH - FALLBACK VALUES KHI CHƯA CÓ CÀI ĐẶT CỦA USER
  // ========================================================================
  static const Map<String, dynamic> _defaultSettings = {
    'fontSize': 16.0, // Kích thước font mặc định (16px - dễ đọc)
    'lineHeight': 1.6, // Chiều cao dòng (1.6 - tối ưu cho mắt)
    'fontFamily': 'Roboto', // Font chữ mặc định (Roboto - clean & readable)
    'backgroundColor': 0xFFFFFFFF, // Màu nền trắng (Colors.white)
    'textColor': 0xFF000000, // Màu chữ đen (Colors.black)
    'isHorizontalReading': false, // Mặc định đọc dọc (scroll mode)
    'autoScrollSpeed': 0.5, // Tốc độ auto-scroll trung bình
    'isFullScreen': false, // Mặc định không fullscreen
  };

  // ========================================================================
  // 💾 CACHE IN-MEMORY - TĂNG TỐC ĐỘ TRUY CẬP CÀI ĐẶT
  // ========================================================================
  Map<String, dynamic>?
      _cachedSettings; // Cache cài đặt trong memory để truy cập nhanh

  // Get all settings
  Future<Map<String, dynamic>> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      try {
        _cachedSettings = json.decode(settingsJson);
        // Ensure all default settings exist
        for (final key in _defaultSettings.keys) {
          if (!_cachedSettings!.containsKey(key)) {
            _cachedSettings![key] = _defaultSettings[key];
          }
        }
        return _cachedSettings!;
      } catch (e) {
        print('Error parsing settings: $e');
      }
    }

    // Return default settings if no saved settings found
    _cachedSettings = Map<String, dynamic>.from(_defaultSettings);
    return _cachedSettings!;
  }

  // Save all settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedSettings = settings;
      await prefs.setString(_settingsKey, json.encode(settings));
      print('Settings saved successfully');
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Get specific setting
  Future<T> getSetting<T>(String key, T defaultValue) async {
    final settings = await getSettings();
    return settings[key] ?? defaultValue;
  }

  // Save specific setting
  Future<void> saveSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  // Helper methods for common settings
  Future<double> getFontSize() async => await getSetting('fontSize', 16.0);
  Future<void> setFontSize(double size) async =>
      await saveSetting('fontSize', size);

  Future<double> getLineHeight() async => await getSetting('lineHeight', 1.6);
  Future<void> setLineHeight(double height) async =>
      await saveSetting('lineHeight', height);

  Future<String> getFontFamily() async =>
      await getSetting('fontFamily', 'Roboto');
  Future<void> setFontFamily(String family) async =>
      await saveSetting('fontFamily', family);

  Future<Color> getBackgroundColor() async {
    final colorValue = await getSetting('backgroundColor', 0xFFFFFFFF);
    return Color(colorValue);
  }

  Future<void> setBackgroundColor(Color color) async =>
      await saveSetting('backgroundColor', color.value);

  Future<Color> getTextColor() async {
    final colorValue = await getSetting('textColor', 0xFF000000);
    return Color(colorValue);
  }

  Future<void> setTextColor(Color color) async =>
      await saveSetting('textColor', color.value);

  Future<bool> getIsHorizontalReading() async =>
      await getSetting('isHorizontalReading', false);
  Future<void> setIsHorizontalReading(bool value) async =>
      await saveSetting('isHorizontalReading', value);

  Future<double> getAutoScrollSpeed() async =>
      await getSetting('autoScrollSpeed', 0.5);
  Future<void> setAutoScrollSpeed(double speed) async =>
      await saveSetting('autoScrollSpeed', speed);

  Future<bool> getIsFullScreen() async =>
      await getSetting('isFullScreen', false);
  Future<void> setIsFullScreen(bool value) async =>
      await saveSetting('isFullScreen', value);

  // Reset to default settings
  Future<void> resetToDefaults() async {
    _cachedSettings = Map<String, dynamic>.from(_defaultSettings);
    await saveSettings(_cachedSettings!);
  }

  // Clear cached settings (force reload from SharedPreferences)
  void clearCache() {
    _cachedSettings = null;
  }

  // Load settings from SharedPreferences
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'fontSize': prefs.getDouble(_fontSizeKey) ?? defaultFontSize,
      'lineHeight': prefs.getDouble(_lineHeightKey) ?? defaultLineHeight,
      'fontFamily': prefs.getString(_fontFamilyKey) ?? defaultFontFamily,
      'backgroundColor':
          prefs.getInt(_backgroundColorKey) ?? defaultBackgroundColor,
      'textColor': prefs.getInt(_textColorKey) ?? defaultTextColor,
      'isHorizontalReading':
          prefs.getBool(_isHorizontalReadingKey) ?? defaultIsHorizontalReading,
      'autoScrollSpeed':
          prefs.getDouble(_autoScrollSpeedKey) ?? defaultAutoScrollSpeed,
    };
  }

  // Save individual settings
  Future<bool> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(_fontSizeKey, fontSize);
  }

  Future<bool> saveLineHeight(double lineHeight) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(_lineHeightKey, lineHeight);
  }

  Future<bool> saveFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_fontFamilyKey, fontFamily);
  }

  Future<bool> saveBackgroundColor(Color backgroundColor) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(_backgroundColorKey, backgroundColor.value);
  }

  Future<bool> saveTextColor(Color textColor) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(_textColorKey, textColor.value);
  }

  Future<bool> saveIsHorizontalReading(bool isHorizontalReading) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_isHorizontalReadingKey, isHorizontalReading);
  }

  Future<bool> saveAutoScrollSpeed(double autoScrollSpeed) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(_autoScrollSpeedKey, autoScrollSpeed);
  }

  // Implementation moved above
}
