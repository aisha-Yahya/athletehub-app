import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // عنوان IP الكمبيوتر على الشبكة المحلية
  // غيّري هذا إلى عنوان IP جهازك (استخدمي ipconfig في CMD)
  static const String _localIp = '192.168.8.123';

  static String get baseUrl {
    // نفضل استخدام localhost لأنه يعمل بشكل ممتاز مع adb reverse tcp:8000 tcp:8000
    // إذا كنت تستخدم الواي فاي بدون كيبل، استبدل localhost بـ $_localIp
    return 'http://localhost:8000';
  }

  static String get apiBaseUrl => '$baseUrl/api/v1';

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
