import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:athletehub_app/app_config.dart';
import '../../../../features/chat/presentation/providers/chat_provider.dart';
import '../../../../features/auth/presentation/providers/user_provider.dart';
import '../../../../features/chat/presentation/screens/group_info_screen.dart';
import '../../../../features/profile/presentation/screens/subscription_billing_screen.dart';
import '../../../../features/explore/presentation/screens/explore_event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchConversations();
      final userProvider = context.read<UserProvider>();
      if (userProvider.userProfile == null) {
        userProvider.loadAllData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading && userProvider.userProfile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final userName = userProvider.userProfile?['name'] ?? 'رياضي';
            final eventsCount = userProvider.myEvents.length;
            final streak = userProvider.streakCount;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(userName),
                  const SizedBox(height: 24),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, _) => _buildStatsRow(chatProvider.conversations.length, eventsCount, streak),
                  ),
                  const SizedBox(height: 24),
                  _buildSubscriptionCard(userProvider.activeSubscription),
                  const SizedBox(height: 32),
                  _buildSectionTitle('مجموعاتك', 'كل المجموعات ←'),
                  const SizedBox(height: 16),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, _) => _buildGroupsList(chatProvider),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('أحداثك القادمة', 'الكل ←'),
                  const SizedBox(height: 16),
                  _buildEventsList(userProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صباح الخير،',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_outlined, color: Color(0xFF3B82F6), size: 28),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int groupsCount, int eventsCount, int streak) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(groupsCount.toString(), 'مجموعة', Icons.person_outline, const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(eventsCount.toString(), 'حدث مسجل', Icons.calendar_today_outlined, const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(streak.toString(), 'يوم متتالي', Icons.local_fire_department, Colors.orange, isFire: true)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color iconColor, {bool isFire = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic>? activeSubscription) {
    final String planName = activeSubscription?['plan']?['name'] ?? 'خطة مجانية';
    final String planPrice = activeSubscription?['plan']?['price']?.toString() ?? '0';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionBillingScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.star, color: Colors.yellow, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اشتراكك النشط', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$planPrice ر.ع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
              Text('/شهر', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ],
      ),
    ),
  );
}

  Widget _buildSectionTitle(String title, String actionLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        Text(actionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
      ],
    );
  }

  Widget _buildGroupsList(ChatProvider provider) {
    final groups = provider.conversations;
    
    if (groups.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'لم تنضم لأي مجموعة بعد.',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final colors = [const Color(0xFFE0F2FE), const Color(0xFFFEF3C7), const Color(0xFFFCE7F3), const Color(0xFFE0E7FF)];
          final avatarUrl = AppConfig.mediaUrl(group.avatar);

          return Padding(
            key: ValueKey('home_group_${group.id}'),
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GroupInfoScreen(conversationId: group.id, title: group.name ?? 'مجموعة')),
                );
              },
              child: _buildGroupCard(
                group.name ?? 'مجموعة بدون اسم',
                'رياضة',
                '${group.participants.length} عضو',
                avatarUrl,
                colors[index % colors.length],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(String title, String type, String members, String avatarUrl, Color bgColor) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl.isEmpty
                  ? const Center(
                      child: Text('👥', style: TextStyle(fontSize: 48)),
                    )
                  : null,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$type • $members',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(UserProvider provider) {
    final now = DateTime.now();
    final events = provider.myEvents.where((e) {
      final date = DateTime.tryParse(e['event_date'] ?? '');
      return date != null && date.isAfter(now);
    }).toList();

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, color: Colors.grey[400], size: 48),
              const SizedBox(height: 8),
              Text(
                'لا توجد أحداث مشارك فيها',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        final date = DateTime.tryParse(event['event_date'] ?? '');
        final day = date != null ? date.day.toString() : '00';
        final month = date != null ? _getMonthName(date.month) : 'شهر';
        final time = date != null ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '00:00';
        final groupName = event['conversation']?['name'] ?? 'مجموعة';
        final title = event['title'] ?? 'حدث';

        return Padding(
          key: ValueKey('home_event_${event['id'] ?? event.hashCode}'),
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExploreEventDetailScreen(
                    event: event,
                    title: title,
                    day: day,
                    month: month,
                    group: groupName,
                    bgColor: const Color(0xFF3B82F6),
                  ),
                ),
              );
            },
            child: _buildEventCard(
              title,
              groupName,
              time,
              day,
              month,
              const Color(0xFF3B82F6),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Widget _buildEventCard(String title, String groupName, String time, String day, String month, Color dateColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: dateColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(day, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(month, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Text('$time • $groupName', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('مسجل', style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.check, color: Color(0xFF166534), size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
