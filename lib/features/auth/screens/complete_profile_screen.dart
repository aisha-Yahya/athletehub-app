import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app_config.dart';
import '../../chat/presentation/screens/conversations_list_screen.dart';

/// شاشة إكمال الملف الشخصي — تظهر للمستخدمين الجدد فقط
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _error = '';

  // الرياضات المتاحة (سيتم جلبها من الـ API)
  List<Map<String, dynamic>> _skills = [];
  final Set<int> _selectedSkillIds = {};
  bool _loadingSkills = true;

  late Dio _dio;

  @override
  void initState() {
    super.initState();
    _initDio();
    _fetchSkills();
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

  Future<void> _fetchSkills() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {'Accept': 'application/json'},
      ));
      final res = await dio.get('/skills');
      final data = res.data['data'] ?? res.data;
      if (data is List) {
        setState(() {
          _skills = data.cast<Map<String, dynamic>>();
          _loadingSkills = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch skills error: $e');
      setState(() => _loadingSkills = false);
    }
  }

  void _toggleSkill(int id) {
    setState(() {
      if (_selectedSkillIds.contains(id)) {
        _selectedSkillIds.remove(id);
      } else {
        _selectedSkillIds.add(id);
      }
    });
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkillIds.isEmpty) {
      setState(() => _error = 'اختر رياضة واحدة على الأقل');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await _dio.post('/profile/complete', data: {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'skill_ids': _selectedSkillIds.toList(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_profile_completed', true);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ConversationsListScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('Complete profile error: $e');
      String errorMsg = 'حدث خطأ غير متوقع';
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        if (e.response?.data != null && e.response?.data is Map) {
          final errors = e.response?.data['errors'];
          if (errors != null && errors is Map) {
            errorMsg = (errors.values.first as List).first.toString();
          } else {
            errorMsg = e.response?.data['message'] ?? errorMsg;
          }
        }
      }
      setState(() => _error = errorMsg);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F8),
      body: SafeArea(
        child: Column(
          children: [
            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أيقونة
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5CF0),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF1B5CF0).withOpacity(0.32),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'أكمل ملفك',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1833),
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'خطوة أخيرة قبل أن تبدأ — أخبرنا عن نفسك',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9EA8BB),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // حقل الاسم
                      const Text(
                        'اسمك الكامل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5675),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF0D1833)),
                        decoration: const InputDecoration(
                          hintText: 'مثال: سالم الراشدي',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'الاسم مطلوب';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // حقل اسم المستخدم
                      const Text(
                        'اسم المستخدم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5675),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameController,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF0D1833)),
                        decoration: const InputDecoration(
                          hintText: 'مثال: salem_r',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'اسم المستخدم مطلوب';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // اختيار الرياضات
                      const Text(
                        'رياضاتك المفضّلة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5675),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_loadingSkills)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                                color: Color(0xFF1B5CF0)),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: _skills.map((skill) {
                            final id = skill['id'] as int;
                            final name = skill['name'] as String;
                            final isSelected = _selectedSkillIds.contains(id);
                            return GestureDetector(
                              onTap: () => _toggleSkill(id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1B5CF0)
                                      : const Color(0xFFF5F7FB),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1B5CF0)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF4B5675),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 6),

                      const Text(
                        'اختر رياضة واحدة على الأقل',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9EA8BB),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ملاحظة
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14,
                                color: const Color(0xFF1348C8).withOpacity(0.8)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'سنستخدم هذه المعلومات لاقتراح المجموعات والأحداث المناسبة لك',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1348C8),
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // رسالة خطأ
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
                    ],
                  ),
                ),
              ),
            ),

            // زر المتابعة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0x120D1833),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5CF0),
                    disabledBackgroundColor:
                        const Color(0xFF1B5CF0).withOpacity(0.6),
                    shadowColor: const Color(0xFF1B5CF0).withOpacity(0.32),
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
                      : const Text('متابعة ←'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
