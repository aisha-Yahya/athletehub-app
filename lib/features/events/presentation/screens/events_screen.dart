import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/presentation/providers/user_provider.dart';
import '../../../../features/explore/presentation/screens/explore_event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isUpcoming = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.myEvents.isEmpty) {
        userProvider.loadAllData();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
    final events = userProvider.myEvents;
    final now = DateTime.now();

    // Split events into upcoming and past based on date
    final List<Map<String, dynamic>> upcomingEvents = [];
    final List<Map<String, dynamic>> pastEvents = [];

    for (final event in events) {
      final date = DateTime.tryParse(event['event_date'] ?? '');
      if (date != null && date.isAfter(now)) {
        upcomingEvents.add(event);
      } else {
        pastEvents.add(event);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: userProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'أحداثي',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 24),
                      _buildSegmentedControl(),
                      const SizedBox(height: 32),
                      if (_isUpcoming) ...[
                        if (upcomingEvents.isEmpty)
                          _buildEmptyState('لا توجد أحداث قادمة')
                        else
                          ..._buildEventCards(upcomingEvents, isUpcoming: true),
                      ] else ...[
                        if (pastEvents.isEmpty)
                          _buildEmptyState('لا توجد أحداث سابقة')
                        else
                          ..._buildEventCards(pastEvents, isUpcoming: false),
                      ]
                    ],
                  ),
                ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      ),
    );
  }
  List<Widget> _buildEventCards(List<Map<String, dynamic>> events, {required bool isUpcoming}) {
    final dateColors = [
      const Color(0xFFFEF3C7),
      const Color(0xFFFCE7F3),
      const Color(0xFFE0F2FE),
      const Color(0xFFE0E7FF),
    ];
    final pastColor = const Color(0xFFCBD5E1);

    return events.asMap().entries.map((entry) {
      final index = entry.key;
      final event = entry.value;
      final date = DateTime.tryParse(event['event_date'] ?? '');
      final day = date != null ? _toArabicDigits(date.day.toString()) : '٠٠';
      final month = date != null ? _getMonthName(date.month) : 'شهر';
      final time = date != null
          ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
          : '00:00';
      final groupName = event['conversation']?['name'] ?? '';
      final title = event['title'] ?? 'حدث';
      final location = event['location'] ?? '';
      final rsvpStatus = event['user_rsvp'] ?? event['rsvp_status'] ?? '';
      final color = isUpcoming ? dateColors[index % dateColors.length] : pastColor;

      return Padding(
        key: ValueKey('event_card_${event['id'] ?? index}'),
        padding: const EdgeInsets.only(bottom: 16),
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
                  bgColor: color,
                ),
              ),
            );
          },
          child: _buildEventCard(
            title: title,
            location: location.isNotEmpty ? '$location • $time' : '$time',
            group: groupName,
            day: day,
            month: month,
            dateColor: color,
            statusType: isUpcoming
                ? (rsvpStatus == 'attending' ? EventStatusType.registered : EventStatusType.none)
                : EventStatusType.attended,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isUpcoming = true),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Text(
                  'قادمة',
                  style: TextStyle(
                    color: _isUpcoming ? const Color(0xFF2563EB) : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, color: const Color(0xFFF1F5F9)),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isUpcoming = false),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Text(
                  'سابقة',
                  style: TextStyle(
                    color: !_isUpcoming ? const Color(0xFF2563EB) : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String location,
    required String group,
    required String day,
    required String month,
    required Color dateColor,
    required EventStatusType statusType,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Date Block
          Container(
            width: 86,
            decoration: BoxDecoration(
              color: dateColor,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                Text(
                  month,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (location.isNotEmpty)
                    Row(
                      children: [
                        if (statusType != EventStatusType.attended) ...[
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            statusType == EventStatusType.attended ? location.replaceAll(RegExp(r'•.*'), '• مكتمل') : location,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (group.isNotEmpty)
                        Expanded(
                          child: Text(group, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      if (statusType == EventStatusType.registered)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('مسجّل', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.check, color: Color(0xFF059669), size: 12),
                            ],
                          ),
                        )
                      else if (statusType == EventStatusType.attended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text('حضرت', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum EventStatusType {
  none,
  registered,
  attended,
}
