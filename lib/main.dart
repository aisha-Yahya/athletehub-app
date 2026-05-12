import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/presentation/screens/conversations_list_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/presentation/providers/user_provider.dart';
import 'main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // التحقق من وجود token محفوظ
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final isProfileCompleted = prefs.getBool('is_profile_completed') ?? false;

  runApp(MyApp(
    initialToken: token,
    isProfileCompleted: isProfileCompleted,
  ));
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  final bool isProfileCompleted;

  const MyApp({
    super.key,
    this.initialToken,
    required this.isProfileCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final dio = Dio();
          final remoteDataSource = ChatRemoteDataSource(dio: dio);
          final repository =
              ChatRepositoryImpl(remoteDataSource: remoteDataSource);
          return ChatProvider(repository: repository);
        }),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Athlete Hub',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: _getInitialScreen(),
      ),
    );
  }

  Widget _getInitialScreen() {
    if (initialToken != null && isProfileCompleted) {
      return const MainScaffold();
    }
    return const LoginScreen();
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF1B5CF0);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Tahoma',
      fontFamilyFallback: const [
        'Segoe UI Emoji',
        'Apple Color Emoji',
      ],
      scaffoldBackgroundColor: const Color(0xFFEEF2F8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0D1833),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0D1833),
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: const Color(0xFF0D1833).withOpacity(0.13)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: const Color(0xFF0D1833).withOpacity(0.13)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9EA8BB),
          fontSize: 13,
        ),
      ),
    );
  }
}
