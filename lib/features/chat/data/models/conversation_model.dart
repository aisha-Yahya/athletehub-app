import 'message_model.dart';
import 'participant_model.dart';

enum ConversationType { private, group }

class ConversationModel {
  final int id;
  final String? name; // For group chats
  final ConversationType type;
  final MessageModel? lastMessage;
  final List<ParticipantModel> participants;
  final int unreadCount;
  final DateTime updatedAt;
  final String? avatar;

  ConversationModel({
    required this.id,
    this.name,
    required this.type,
    this.lastMessage,
    required this.participants,
    this.unreadCount = 0,
    required this.updatedAt,
    this.avatar,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      name: json['name'],
      type: json['type'] == 'group' ? ConversationType.group : ConversationType.private,
      lastMessage: json['latest_message'] != null
          ? MessageModel.fromJson(json['latest_message'])
          : null,
      participants: (json['users'] as List<dynamic>?)
              ?.map((p) => ParticipantModel.fromJson(p))
              .toList() ??
          [],
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'last_message': lastMessage?.toJson(),
      'users': participants.map((p) => p.toJson()).toList(),
      'unread_count': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
      'avatar': avatar,
    };
  }

  String getDisplayName(int currentUserId) {
    if (type == ConversationType.group && name != null) {
      return name!;
    }
    // For private chat, return the other participant's name
    final otherParticipant = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => ParticipantModel(id: 0, name: 'Unknown User'),
    );
    return otherParticipant.name;
  }
}
