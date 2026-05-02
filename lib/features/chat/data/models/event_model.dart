import 'participant_model.dart';

class EventModel {
  final int id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String? location;
  final int attendeesCount;
  final String? userRsvp; // 'attending', 'not_attending', or null
  final String status; // 'upcoming', 'ongoing', 'finished'
  final List<ParticipantModel> attendees;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.location,
    this.attendeesCount = 0,
    this.userRsvp,
    this.status = 'upcoming',
    this.attendees = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      eventDate: DateTime.parse(json['event_date']),
      location: json['location'],
      attendeesCount: json['attendees_count'] ?? 0,
      userRsvp: json['user_rsvp'],
      status: json['status'] ?? 'upcoming',
      attendees: (json['attendees'] as List<dynamic>?)
              ?.map((p) => ParticipantModel.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'location': location,
      'attendees_count': attendeesCount,
      'user_rsvp': userRsvp,
      'status': status,
      'attendees': attendees.map((p) => p.toJson()).toList(),
    };
  }

  EventModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
    int? attendeesCount,
    String? userRsvp,
    String? status,
    List<ParticipantModel>? attendees,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      userRsvp: userRsvp ?? this.userRsvp,
      status: status ?? this.status,
      attendees: attendees ?? this.attendees,
    );
  }

  /// Calculate time remaining until event
  Duration get timeUntilEvent => eventDate.difference(DateTime.now());

  /// Check if event is in the past
  bool get isPast => DateTime.now().isAfter(eventDate);

  /// Get Arabic day name
  String get arabicDayName {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[eventDate.weekday - 1];
  }

  /// Get Arabic month name
  String get arabicMonthName {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[eventDate.month - 1];
  }

  /// Formatted Arabic date (السبت، 1 مايو 2026)
  String get formattedArabicDate =>
      '$arabicDayName، ${eventDate.day} $arabicMonthName ${eventDate.year}';

  /// Formatted time with period (صباحاً 6:00)
  String get formattedArabicTime {
    final hour = eventDate.hour;
    final minute = eventDate.minute.toString().padLeft(2, '0');
    if (hour == 0) return '12:$minute صباحاً';
    if (hour < 12) return '$hour:$minute صباحاً';
    if (hour == 12) return '12:$minute مساءً';
    return '${hour - 12}:$minute مساءً';
  }

  /// Countdown text in Arabic
  String get countdownText {
    if (isPast) return 'انتهى الحدث';
    final diff = timeUntilEvent;
    if (diff.inDays > 0) {
      return '${diff.inDays} يوم ${diff.inHours % 24} ساعة';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ساعة ${diff.inMinutes % 60} دقيقة';
    } else {
      return '${diff.inMinutes} دقيقة';
    }
  }
}
