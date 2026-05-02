import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'package:athletehub_app/app_config.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // We can also listen to updates if we use a Provider or Stream,
    // but for now we'll just display the passed event or fetch it.
    // Ideally we pass the event from the provider to get real-time updates.
    final chatProvider = context.watch<ChatProvider>();
    
    // Find the latest version of the event from the provider's messages
    EventModel currentEvent = event;
    for (var msg in chatProvider.messages) {
      if (msg.event?.id == event.id) {
        currentEvent = msg.event!;
        break;
      }
    }

    final isAttending = currentEvent.userRsvp == 'attending';
    final isNotAttending = currentEvent.userRsvp == 'not_attending';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('تفاصيل الفعالية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF6C3FA0),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image/Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF2196F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: currentEvent.status == 'finished'
                          ? Colors.red.withOpacity(0.8)
                          : currentEvent.status == 'ongoing'
                              ? Colors.orange.withOpacity(0.8)
                              : Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentEvent.status == 'finished'
                          ? 'منتهية'
                          : currentEvent.status == 'ongoing'
                              ? 'جارية الآن'
                              : 'قادمة',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.directions_run, color: Colors.white, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    currentEvent.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Time & Date
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'التاريخ',
                          value: currentEvent.formattedArabicDate,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.access_time,
                          title: 'الوقت',
                          value: currentEvent.formattedArabicTime,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (currentEvent.location != null && currentEvent.location!.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: 'الموقع',
                      value: currentEvent.location!,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // RSVP section
                  const Text('هل ستحضر؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRsvpButton(
                          label: 'سأحضر',
                          iconData: Icons.check_circle,
                          isSelected: isAttending,
                          selectedColor: const Color(0xFF4CAF50),
                          onTap: () => chatProvider.rsvpToEvent(currentEvent.id, 'attending'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRsvpButton(
                          label: 'لن أحضر',
                          iconData: Icons.cancel,
                          isSelected: isNotAttending,
                          selectedColor: Colors.red,
                          onTap: () => chatProvider.rsvpToEvent(currentEvent.id, 'not_attending'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (currentEvent.description.isNotEmpty) ...[
                    const Text('وصف الفعالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        currentEvent.description,
                        style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Attendees
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${currentEvent.attendeesCount} الحضور', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const Text('المشاركين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (currentEvent.attendees.isEmpty)
                    const Center(child: Text('لا يوجد مشاركين حتى الآن.', style: TextStyle(color: Colors.grey)))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentEvent.attendees.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final attendee = currentEvent.attendees[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF6C3FA0).withValues(alpha: 0.1),
                              backgroundImage: attendee.avatarUrl != null && attendee.avatarUrl!.isNotEmpty
                                  ? NetworkImage(AppConfig.storageUrl(attendee.avatarUrl))
                                  : null,
                              child: attendee.avatarUrl == null || attendee.avatarUrl!.isEmpty
                                  ? Text(attendee.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6C3FA0), fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            title: Text(attendee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildRsvpButton({
    required String label,
    required IconData iconData,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: selectedColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: isSelected ? Colors.white : Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
