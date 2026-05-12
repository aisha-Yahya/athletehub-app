import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // عنوان IP الكمبيوتر على الشبكة المحلية
  // غيّري هذا إلى عنوان IP جهازك (استخدمي ipconfig في CMD)
  static const String _localIp = '127.0.0.1';

  static String get baseUrl {
    // نستخدم IP الشبكة لكي يعمل Reverb و API بانسجام
    return 'http://$_localIp:8000';
  }

  static String get apiBaseUrl => '$baseUrl/api/v1';

  // إعدادات Laravel Reverb
  static String get reverbHost => _localIp;
  static const int reverbPort = 8080;
  static const String reverbAppKey = 'athletehub-key'; // المفتاح من ملف .env في Laravel


  // بناء رابط كامل للملفات والصور
  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$apiBaseUrl/media?path=$path';
  }

  // بناء رابط التخزين
  static String storageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl/storage/$path';
  }
}
