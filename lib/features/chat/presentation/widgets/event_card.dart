import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';
import '../screens/event_details_screen.dart';

class EventCard extends StatefulWidget {
  final EventModel event;
  final bool isMe;
  final DateTime createdAt;
  final Function(String rsvp)? onRsvp;

  const EventCard({
    super.key,
    required this.event,
    required this.isMe,
    required this.createdAt,
    this.onRsvp,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String _countdownText = '';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownText = widget.event.countdownText;
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _countdownText = widget.event.countdownText);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event))),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: Text(event.status == 'finished' ? 'منتهية' : 'قادمة', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _buildRow(Icons.calendar_today, event.formattedArabicDate),
                    _buildRow(Icons.access_time, event.formattedArabicTime),
                    if (event.location != null) _buildRow(Icons.location_on, event.location!, color: Colors.red),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('👥 ${event.attendeesCount} سيحضر', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('⏳ $_countdownText', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildBtn('سأحضر', Colors.green, event.userRsvp == 'attending', () => widget.onRsvp?.call('attending'))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildBtn('لن أحضر', Colors.red, event.userRsvp == 'not_attending', () => widget.onRsvp?.call('not_attending'))),
                      ],
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

  Widget _buildRow(IconData icon, String text, {Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildBtn(String label, Color color, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: selected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
