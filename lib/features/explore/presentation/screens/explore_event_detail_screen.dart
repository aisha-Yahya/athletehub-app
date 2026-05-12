import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:athletehub_app/app_config.dart';
import 'package:athletehub_app/features/chat/presentation/screens/group_info_screen.dart';

class ExploreEventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;
  final String title;
  final String day;
  final String month;
  final String group;
  final Color bgColor;

  const ExploreEventDetailScreen({
    super.key,
    required this.event,
    required this.title,
    required this.day,
    required this.month,
    required this.group,
    this.bgColor = const Color(0xFFFEF3C7),
  });

  @override
  Widget build(BuildContext context) {
    final description = event['description'] ?? 'لا يوجد وصف متاح لهذا الحدث.';
    final rsvps = (event['rsvps'] as List<dynamic>?) ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // الهيدر العلوي
                    _buildHeader(context),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // بطاقتي التاريخ والموقع
                          _buildDateLocationRow(),
                          const SizedBox(height: 16),

                          // المجموعة المنظّمة
                          _buildOrganizerCard(context),
                          const SizedBox(height: 24),

                          // الوصف
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text('الوصف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.7),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 24),

                          // سيحضرون
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('سيحضرون (${rsvps.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                          ),
                          const SizedBox(height: 12),
                          _buildAttendees(rsvps),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // الزر السفلي
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 30, right: 20, left: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // زر الرجوع
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF475569)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            group.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateLocationRow() {
    final location = event['location'] ?? 'غير محدد';
    final dateObj = DateTime.tryParse(event['event_date'] ?? '');
    final timeStr = dateObj != null ? '${dateObj.hour}:${dateObj.minute.toString().padLeft(2, '0')}' : '00:00';
    
    return Row(
      children: [
        // التاريخ
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Text('التاريخ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 6),
                Text('$day $month', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(timeStr, style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // الموقع
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Text('الموقع', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 6),
                Text(location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                const Text('الخريطة →', style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerCard(BuildContext context) {
    final conversation = event['conversation'];
    final avatarPath = conversation?['avatar'];
    final avatarUrl = AppConfig.mediaUrl(avatarPath);
    final isGroup = conversation?['type'] == 'group';
    final convId = conversation?['id'];

    return GestureDetector(
      onTap: () {
        if (convId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupInfoScreen(
                conversationId: convId,
                title: group,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            // الأيقونة
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                image: avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl.isEmpty
                  ? Center(child: Text(isGroup ? '👥' : '💬', style: const TextStyle(fontSize: 24)))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المجموعة المنظّمة', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text(group, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendees(List<dynamic> rsvps) {
    if (rsvps.isEmpty) {
      return Text('لا يوجد مسجلين حتى الآن.', style: TextStyle(color: Colors.grey[500], fontSize: 13));
    }

    final attending = rsvps.where((r) => r['status'] == 'attending').toList();
    if (attending.isEmpty) {
      return Text('لا يوجد مسجلين حتى الآن.', style: TextStyle(color: Colors.grey[500], fontSize: 13));
    }

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];

    final displayCount = attending.length > 5 ? 5 : attending.length;

    return Row(
      children: [
        ...List.generate(displayCount, (i) {
          final user = attending[i]['user'];
          final name = user?['name'] ?? 'م';
          final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
          
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: colors[i % colors.length],
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          );
        }),
        if (attending.length > 5) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('+${attending.length - 5}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomButton() {
    final status = event['user_rsvp'] ?? event['rsvp_status'];
    final isAttending = status == 'attending';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            // يمكننا إضافة منطق تعديل التسجيل هنا في المستقبل
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isAttending ? const Color(0xFFDCFCE7) : const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            isAttending ? 'أنت مسجل ✓' : 'سجل حضورك الآن',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isAttending ? const Color(0xFF166534) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
