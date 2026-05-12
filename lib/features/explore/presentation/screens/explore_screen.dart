import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:athletehub_app/app_config.dart';
import 'package:athletehub_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:athletehub_app/features/auth/presentation/providers/user_provider.dart';
import 'package:athletehub_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:athletehub_app/features/chat/data/models/conversation_model.dart';
import 'package:athletehub_app/features/explore/presentation/screens/explore_event_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الهيدر: استكشف
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'استكشف',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // شريط البحث
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[400], size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          textDirection: TextDirection.rtl,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن مجموعة أو حدث...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // تصفّح حسب الرياضة (لا نطبق البحث هنا لتبقى واضحة)
                if (_searchQuery.isEmpty) ...[
                  const Text(
                    'تصفّح حسب الرياضة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  Consumer<UserProvider>(builder: (context, userProvider, _) => _buildSportsCategories(userProvider)),
                  const SizedBox(height: 28),
                ],

                // مجموعاتك
                _buildSectionTitle('المجموعات', ''),
                const SizedBox(height: 16),
                Consumer<ChatProvider>(builder: (context, chatProvider, _) => _buildRealGroups(context, chatProvider)),
                const SizedBox(height: 28),

                // أحداثك
                _buildSectionTitle('الأحداث', ''),
                const SizedBox(height: 16),
                Consumer<UserProvider>(builder: (context, userProvider, _) => _buildRealEvents(userProvider)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String actionLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        if (actionLabel.isNotEmpty)
          Text(actionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
      ],
    );
  }

  Widget _buildSportsCategories(UserProvider userProvider) {
    final List userSkills = userProvider.userProfile?['skills'] ?? [];

    if (userSkills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Center(
          child: Text(
            'لم يتم تحديد رياضات بعد',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: userSkills.map<Widget>((skill) {
        final name = skill['name'] ?? '';
        final emoji = _getEmojiForSport(name);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getEmojiForSport(String name) {
    final Map<String, String> emojis = {
      'جري': '🏃‍♂️',
      'دراجات': '🚴‍♂️',
      'سباحة': '🏊‍♂️',
      'يوغا': '🧘‍♂️',
      'كرة قدم': '⚽',
      'غوص': '🤿',
      'تسلّق': '🧗‍♂️',
      'كروس فت': '💪',
      'تنس': '🎾',
      'سلة': '🏀',
      'ركض': '🏃‍♂️',
    };
    return emojis[name] ?? '🏆';
  }

  Widget _buildRealGroups(BuildContext context, ChatProvider chatProvider) {
    final allGroups = chatProvider.conversations;
    final groups = _searchQuery.isEmpty 
        ? allGroups 
        : allGroups.where((g) => (g.name ?? '').toLowerCase().contains(_searchQuery)).toList();

    if (groups.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Center(
          child: Text(
            _searchQuery.isEmpty ? 'لم تنضم لأي مجموعة بعد' : 'لا توجد مجموعات تطابق بحثك',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFFFEF3C7),
      const Color(0xFFE0F2FE),
      const Color(0xFFFCE7F3),
      const Color(0xFFE0E7FF),
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final avatarUrl = AppConfig.mediaUrl(group.avatar);

          return Padding(
            key: ValueKey('explore_group_${group.id}'),
            padding: EdgeInsets.only(left: index < groups.length - 1 ? 16 : 0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: group.id,
                      title: group.name ?? 'مجموعة',
                    ),
                  ),
                );
              },
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          image: avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl.isEmpty
                            ? Center(
                                child: Text(
                                  group.type == ConversationType.group ? '👥' : '💬',
                                  style: const TextStyle(fontSize: 48),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text(
                            group.name ?? 'مجموعة',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${group.participants.length} عضو',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRealEvents(UserProvider userProvider) {
    final allEvents = userProvider.myEvents;
    final events = _searchQuery.isEmpty 
        ? allEvents 
        : allEvents.where((e) {
            final title = (e['title'] ?? '').toLowerCase();
            final groupName = (e['conversation']?['name'] ?? '').toLowerCase();
            return title.contains(_searchQuery) || groupName.contains(_searchQuery);
          }).toList();

    if (events.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Center(
          child: Text(
            _searchQuery.isEmpty ? 'لا توجد أحداث حالياً' : 'لا توجد أحداث تطابق بحثك',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        final date = DateTime.tryParse(event['event_date'] ?? '');
        final day = date != null ? _toArabicDigits(date.day.toString()) : '٠٠';
        final month = date != null ? _getMonthName(date.month) : 'شهر';
        final groupName = event['conversation']?['name'] ?? '';
        final title = event['title'] ?? 'حدث';

        return Padding(
          key: ValueKey('explore_event_${event['id'] ?? title}'),
          padding: const EdgeInsets.only(bottom: 12),
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
                    group: groupName.isEmpty ? 'مجموعة' : groupName,
                    bgColor: const Color(0xFFE0F2FE),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  // النص على اليمين
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        if (groupName.isNotEmpty)
                          Text(groupName, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // مربع التاريخ على اليسار
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        Text(month, style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
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

  String _toArabicDigits(String input) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.split('').map((c) {
      final d = int.tryParse(c);
      if (d != null) return digits[d];
      return c;
    }).join();
  }
}
