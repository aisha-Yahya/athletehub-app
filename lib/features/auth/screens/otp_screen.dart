import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app_config.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/user_provider.dart';
import '../../chat/presentation/screens/conversations_list_screen.dart';
import 'complete_profile_screen.dart';
import '../../../main_scaffold.dart';

/// شاشة التحقق من OTP
class OtpScreen extends StatefulWidget {
  final String email;
  final String? debugOtp;
  final bool isNewUser;

  const OtpScreen({
    super.key,
    required this.email,
    this.debugOtp,
    this.isNewUser = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<String> _digits = List.filled(6, '');
  int _cursor = 0;
  bool _loading = false;
  String _error = '';

  final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {'Accept': 'application/json'},
    extra: {'withCredentials': true},
  ));

  @override
  void initState() {
    super.initState();
    // تعبئة رمز OTP تلقائياً في وضع التطوير
    if (widget.debugOtp != null && widget.debugOtp!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _digits[i] = widget.debugOtp![i];
      }
      _cursor = 5;
    }
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_digits[_cursor].isNotEmpty) {
          _digits[_cursor] = '';
        } else if (_cursor > 0) {
          _cursor--;
          _digits[_cursor] = '';
        }
      } else {
        _digits[_cursor] = key;
        if (_cursor < 5) _cursor++;
      }
      _error = '';
    });
  }

  Future<void> _verify() async {
    final code = _digits.join();
    if (code.length < 6 || _digits.contains('')) {
      setState(() => _error = 'أدخل الرمز كاملاً');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await _dio.post('/verify-otp', data: {
        'email': widget.email,
        'code': code,
      });

      final data = res.data['data'] ?? res.data;
      final token = data['token'];
      // نعتبر الملف مكتملاً إذا كان المستخدم مسجلاً مسبقاً، أو إذا أكده السيرفر
      final isProfileCompleted = !widget.isNewUser || (data['is_profile_completed'] ?? false);

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('is_profile_completed', isProfileCompleted);

        // حفظ user_id
        final userData = data['user'];
        if (userData != null) {
          await prefs.setInt('user_id', userData['id']);
        }

        if (mounted) {
          // إذا كان المستخدم ليس جديداً (مسجل مسبقاً) أو أكمل ملفه، يذهب للرئيسية
          if (!widget.isNewUser || isProfileCompleted) {
            // تحديث بيانات المستخدم فوراً
            context.read<UserProvider>().loadAllData();
            
            // المستخدم أكمل ملفه أو مسجل مسبقاً → الصفحة الرئيسية
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => const MainScaffold()),
              (_) => false,
            );
          } else {
            // مستخدم جديد → إكمال الملف الشخصي
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const CompleteProfileScreen(),
                transitionsBuilder: (_, anim, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOut)),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
        }
      } else {
        setState(() => _error = 'حدث خطأ غير متوقع');
      }
    } catch (e) {
      debugPrint('OTP Error: $e');
      String errorMsg = 'حدث خطأ غير متوقع';
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        if (e.response?.data != null && e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        } else {
          errorMsg = 'خطأ اتصال: ${e.type.name}';
        }
      }
      setState(() => _error = errorMsg);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await _dio.post('/resend-otp', data: {'email': widget.email});
      setState(() {
        _digits.fillRange(0, 6, '');
        _cursor = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إرسال الرمز مجدداً'),
            backgroundColor: const Color(0xFF0D1833),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Resend error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: const Color(0xFF1B5CF0),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('تحقّق من بريدك'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    // أيقونة البريد
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF2FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        size: 28,
                        color: Color(0xFF1B5CF0),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'أدخل رمز التحقق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1833),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'أرسلنا رمزاً مكوّناً من ٦ أرقام إلى\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9EA8BB),
                        height: 1.6,
                      ),
                    ),

                    // عرض OTP التجريبي
                    if (widget.debugOtp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'الرمز التجريبي: ${widget.debugOtp}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B5CF0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // صناديق OTP
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          final isFilled = _digits[i].isNotEmpty;
                          final isCurrent = i == _cursor;
                          return Container(
                            width: 46,
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFFEBF2FF)
                                  : isFilled
                                      ? Colors.white
                                      : const Color(0xFFF5F7FB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF1B5CF0)
                                    : isFilled
                                        ? const Color(0xFF0D1833)
                                            .withOpacity(0.13)
                                        : Colors.transparent,
                                width: isCurrent ? 2 : 1.5,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1B5CF0)
                                            .withOpacity(0.12),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _digits[i],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D1833),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                    // لوحة أرقام
                    _buildNumpad(),

                    // رسالة الخطأ
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFD63B2F),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // زر التأكيد
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5CF0),
                          disabledBackgroundColor:
                              const Color(0xFF1B5CF0).withOpacity(0.6),
                          shadowColor:
                              const Color(0xFF1B5CF0).withOpacity(0.32),
                          elevation: 6,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('تأكيد الرمز'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // إعادة إرسال
                    GestureDetector(
                      onTap: _resendOtp,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 11, color: Color(0xFF9EA8BB)),
                          children: [
                            TextSpan(text: 'لم يصلك الرمز؟ '),
                            TextSpan(
                              text: 'إعادة الإرسال',
                              style: TextStyle(
                                color: Color(0xFF1B5CF0),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.0,
        ),
        itemCount: 12,
        itemBuilder: (_, i) {
          final key = keys[i];
          if (key.isEmpty) return const SizedBox();
          return Material(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _onKeyPress(key),
              child: Center(
                child: key == '⌫'
                    ? const Icon(Icons.backspace_outlined,
                        size: 20, color: Color(0xFF0D1833))
                    : Text(
                        key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1833),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
