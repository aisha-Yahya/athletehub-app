import 'event_model.dart';
import 'reaction_model.dart';

enum MessageType { text, image, video, event, audio, document }

class MessageModel {
  final int id;
  final int conversationId;
  final int userId;
  final String content;
  final String? fileUrl;
  final MessageType type;
  final DateTime createdAt;
  final String status;
  final EventModel? event;
  final MessageModel? replyTo;
  final double? uploadProgress;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.content,
    this.fileUrl,
    required this.type,
    required this.createdAt,
    this.status = 'sent',
    this.event,
    this.reactions = const [],
    this.replyTo,
    this.uploadProgress,
  });

  final List<ReactionModel> reactions;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      content: json['content'] ?? '',
      fileUrl: json['file_url'],
      type: _parseMessageType(json['type']),
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'sent',
      event: json['event'] != null ? EventModel.fromJson(json['event']) : null,
      reactions: (json['reactions'] as List?)?.map((r) => ReactionModel.fromJson(r)).toList() ?? [],
      replyTo: json['reply_to'] != null ? MessageModel.fromJson(json['reply_to']) : null,
      uploadProgress: json['upload_progress']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'content': content,
      'file_url': fileUrl,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'event': event?.toJson(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'reply_to': replyTo?.toJson(),
    };
  }

  MessageModel copyWith({
    int? id,
    int? conversationId,
    int? userId,
    String? content,
    String? fileUrl,
    MessageType? type,
    DateTime? createdAt,
    String? status,
    EventModel? event,
    List<ReactionModel>? reactions,
    MessageModel? replyTo,
    double? uploadProgress,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      event: event ?? this.event,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'event':
        return MessageType.event;
      case 'audio':
        return MessageType.audio;
      case 'document':
        return MessageType.document;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}
