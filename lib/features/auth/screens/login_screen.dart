import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../app_config.dart';
import 'otp_screen.dart';

/// شاشة إدخال البريد الإلكتروني — نقطة الدخول الموحّدة (تسجيل + دخول)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _error = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {'Accept': 'application/json'},
    extra: {'withCredentials': true},
  ));

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await _dio.post('/send-otp', data: {
        'email': _emailController.text.trim(),
      });

      final data = res.data['data'] ?? {};
      final otp = data['otp']?.toString();
      final isNewUser = data['is_new_user'] ?? false;

      if (otp != null) {
        debugPrint('🔑 DEBUG OTP: $otp');
      }

      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => OtpScreen(
              email: _emailController.text.trim(),
              debugOtp: otp,
              isNewUser: isNewUser,
            ),
            transitionsBuilder: (_, anim, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      debugPrint('SendOTP Error: $e');
      String errorMsg = 'حدث خطأ غير متوقع';
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg = 'لا يمكن الاتصال بالسيرفر. تأكد من الاتصال بالشبكة';
        } else if (e.response?.statusCode == 422) {
          errorMsg = 'البريد الإلكتروني غير صالح';
        } else {
          errorMsg = e.response?.data?['message'] ?? 'خطأ في الاتصال';
        }
      }
      setState(() => _error = errorMsg);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة التطبيق
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5CF0),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5CF0).withOpacity(0.32),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // العنوان
                    const Text(
                      'أهلاً بك',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1833),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'أدخل بريدك للدخول أو إنشاء حساب جديد\nسنرسل لك رمز تحقّق سريع',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9EA8BB),
                        height: 1.65,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // حقل البريد الإلكتروني
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'البريد الإلكتروني',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B5675),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0D1833),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'البريد الإلكتروني مطلوب';
                              }
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(value.trim())) {
                                return 'أدخل بريد إلكتروني صحيح';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _sendOtp(),
                          ),
                        ],
                      ),
                    ),

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
                          style: const TextStyle(
                            color: Color(0xFFD63B2F),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // زر المتابعة
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
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
                            : const Text('متابعة'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // الشروط والخصوصية
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9EA8BB),
                          height: 1.65,
                        ),
                        children: [
                          TextSpan(text: 'بالاستمرار، فإنك توافق على '),
                          TextSpan(
                            text: 'الشروط والخصوصية',
                            style: TextStyle(
                              color: Color(0xFF1B5CF0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
