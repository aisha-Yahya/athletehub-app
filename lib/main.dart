import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/presentation/screens/conversations_list_screen.dart';
import 'app_router.dart';
import 'app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final dio = Dio();
          final remoteDataSource = ChatRemoteDataSource(dio: dio);
          final repository = ChatRepositoryImpl(remoteDataSource: remoteDataSource);
          return ChatProvider(repository: repository);
        }),
      ],
      child: MaterialApp(
        title: 'Athlete Hub',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C3FA0)),
          useMaterial3: true,
          fontFamilyFallback: const ['Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji'],
        ),
        // navigatorObservers: [routeObserver],
        home: const LoginScreen(),
      ),
    );
  }
}

// ─── شاشة تسجيل الدخول ───────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String _error = '';

  final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {
      'Accept': 'application/json',
    },
    extra: {'withCredentials': true},
  ));

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    try {
      await _dio.post('/login', data: {'email': _emailController.text});
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OtpScreen(email: _emailController.text),
        ));
      }
    } catch (e) {
      print('Login Error: $e');
      String errorMsg = 'حدث خطأ غير متوقع';
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg = 'لا يمكن الاتصال بالسيرفر. تأكد من الاتصال بالشبكة';
        } else if (e.response?.statusCode == 404 || e.response?.statusCode == 422) {
          errorMsg = 'البريد الإلكتروني غير مسجل';
        } else {
          errorMsg = e.response?.data?['message'] ?? 'خطأ في الاتصال';
        }
      }
      setState(() { _error = errorMsg; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C3FA0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text('Athlete Hub',
                style: TextStyle(fontSize: 28, color: Colors.white,
                    fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('تسجيل الدخول',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3FA0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إرسال رمز التحقق',
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── شاشة OTP ────────────────────────────────────────
class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String _error = '';

  final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {
      'Accept': 'application/json',
    },
    extra: {'withCredentials': true},
  ));

  Future<void> _verify() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await _dio.post('/verify-otp', data: {
        'email': widget.email,
        'code': _otpController.text,
      });

      // الـ token ممكن يكون في مكانين
      final token = res.data['token'] ?? res.data['data']?['token'];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

// احفظي user_id أيضاً
final userData = res.data['data']?['user'] ?? res.data['user'];
        if (userData != null) {
          await prefs.setInt('user_id', userData['id']);
        }
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => const ConversationsListScreen(),
          ));
        }
      } else {
        setState(() { _error = 'حدث خطأ'; });
      }
    } catch (e) {
      print('OTP Error: $e');
      String errorMsg = 'حدث خطأ غير متوقع';
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Error type: ${e.type}');
        if (e.response?.data != null && e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        } else {
          errorMsg = 'خطأ اتصال: ${e.type.name}';
        }
      }
      setState(() { _error = errorMsg; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C3FA0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text('تحقق من الرمز',
                style: TextStyle(fontSize: 24, color: Colors.white,
                    fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('أرسلنا رمزاً إلى ${widget.email}',
                      style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3FA0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('تحقق',
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


