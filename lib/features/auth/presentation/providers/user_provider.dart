import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../app_config.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userProfile;
  List<dynamic> _myEvents = [];
  Map<String, dynamic>? _activeSubscription;
  int _streakCount = 0;
  bool _isLoading = false;

  Map<String, dynamic>? get userProfile => _userProfile;
  List<dynamic> get myEvents => _myEvents;
  Map<String, dynamic>? get activeSubscription => _activeSubscription;
  int get streakCount => _streakCount;
  bool get isLoading => _isLoading;

  late Dio _dio;

  UserProvider() {
    _initDio();
  }

  Future<void> _initDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    await _initDio(); // Ensure token is up to date

    await Future.wait([
      fetchProfile(),
      fetchMyEvents(),
      fetchSubscription(),
      calculateStreak(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      final res = await _dio.get('/profile');
      if (res.data['status'] == true || res.data['success'] == true) {
        _userProfile = res.data['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> fetchMyEvents() async {
    try {
      final res = await _dio.get('/my-events');
      if (res.data['status'] == true || res.data['success'] == true) {
        _myEvents = res.data['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching my events: $e');
    }
  }

  Future<void> fetchSubscription() async {
    try {
      final res = await _dio.get('/subscriptions/me');
      if (res.data['status'] == true || res.data['success'] == true) {
        _activeSubscription = res.data['data'];
      }
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    }
  }

  Future<void> calculateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    final lastLoginDate = prefs.getString('last_login_date');
    int currentStreak = prefs.getInt('streak_count') ?? 0;

    if (lastLoginDate == null) {
      // First login ever
      currentStreak = 1;
      await prefs.setString('last_login_date', today);
      await prefs.setInt('streak_count', currentStreak);
    } else if (lastLoginDate == yesterday) {
      // Logged in yesterday, increment streak
      currentStreak++;
      await prefs.setString('last_login_date', today);
      await prefs.setInt('streak_count', currentStreak);
    } else if (lastLoginDate != today) {
      // Missed a day, reset streak
      currentStreak = 1;
      await prefs.setString('last_login_date', today);
      await prefs.setInt('streak_count', currentStreak);
    }

    _streakCount = currentStreak;
  }
}
