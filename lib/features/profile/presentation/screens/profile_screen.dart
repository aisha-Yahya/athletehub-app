import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:athletehub_app/app_config.dart';
import 'package:athletehub_app/features/auth/screens/login_screen.dart';
import 'package:athletehub_app/features/auth/presentation/providers/user_provider.dart';
import 'package:athletehub_app/features/profile/presentation/screens/subscription_billing_screen.dart';
import 'package:athletehub_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dio/dio.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        final dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          headers: {'Authorization': 'Bearer $token'},
        ));
        await dio.post('/logout');
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      await prefs.remove('is_profile_completed');

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final user = userProvider.userProfile;

    if (userProvider.isLoading && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      // Trigger data load if not already loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userProvider.loadAllData();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String name = user['name'] ?? '';
    final String username = user['username'] ?? '';
    final List skills = user['skills'] ?? [];
    final int groupsCount = chatProvider.conversations.length;
    final subscription = userProvider.activeSubscription;
    final String planName = subscription?['plan']?['name'] ?? 'مجانية';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header & Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: -50,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, name.length > 2 ? 2 : name.length) : 'U',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Name & Edit Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            if (username.isNotEmpty)
                              Text(
                                '@$username • مسقط',
                                style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w500),
                              ),
                            const SizedBox(height: 12),
                            if (skills.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: skills.map<Widget>((s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    s['name'] ?? '',
                                    style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                )).toList(),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('تعديل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Subscription Card
                    _buildSectionLabel('اشتراكك'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionBillingScreen()),
                        );
                      },
                      child: _buildSubscriptionCard(subscription, planName),
                    ),

                    const SizedBox(height: 32),

                    // Photos Section
                    _buildPhotosSection(),

                    const SizedBox(height: 32),

                    // Account Section
                    _buildSectionLabel('الحساب'),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      Icons.credit_card_outlined, 
                      'الاشتراك والفوترة', 
                      subtitle: planName,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionBillingScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(Icons.person_outline, 'مجموعاتي', subtitle: '$groupsCount مجموعة'),
                    _buildMenuItem(Icons.notifications_none_outlined, 'الإشعارات'),
                    _buildMenuItem(Icons.star_border, 'لوحة المشرف', subtitle: groupsCount > 0 ? chatProvider.conversations.first.name ?? 'Muscat Runners' : 'Muscat Runners'),

                    const SizedBox(height: 32),

                    // Support Section
                    _buildSectionLabel('الدعم'),
                    const SizedBox(height: 12),
                    _buildMenuItem(Icons.help_outline, 'المساعدة والدعم'),
                    _buildMenuItem(Icons.description_outlined, 'الشروط والخصوصية'),

                    const SizedBox(height: 16),

                    // Logout
                    _buildLogoutItem(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic>? subscription, String planName) {
    final String price = subscription?['plan']?['price']?.toString() ?? '0';
    final bool isActive = subscription != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isActive ? 'نشطة ' : 'غير نشطة ', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              if (isActive) const Text('⭐', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text('خطة $planName', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('$price ر.ع', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('/ شهر', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          const Text('إدارة ←', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    final placeholderColors = [
      const Color(0xFFDCFCE7), const Color(0xFFFEF3C7),
      const Color(0xFFFCE7F3), const Color(0xFFE0F2FE),
      const Color(0xFFE0E7FF), const Color(0xFFFEF9C3),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('الصور', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text('+ إضافة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[600])),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('8 صورة • مرئية للجميع', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index == 2) { // 3rd item is the Add button as shown in image
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid, width: 2), // Simulate dashed
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 28, color: Color(0xFF2563EB)),
                    SizedBox(height: 4),
                    Text('إضافة', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }
            final colorIndex = index > 2 ? index - 1 : index;
            return Container(
              decoration: BoxDecoration(
                color: placeholderColors[colorIndex % placeholderColors.length],
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400])),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0F172A), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null && subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w600)),
              ),
            Icon(Icons.arrow_back, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 22),
        ),
        title: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
        trailing: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F172A)),
        onTap: () => _logout(context),
      ),
    );
  }
}
