import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/reaction_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository repository;

  ChatProvider({required this.repository});

  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  bool _isLoadingConversations = false;
  bool get isLoadingConversations => _isLoadingConversations;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  int? _activeConversationId;
  int? get activeConversationId => _activeConversationId;

  int _currentPage = 1;
  bool _isLoadingMoreMessages = false;
  bool get isLoadingMoreMessages => _isLoadingMoreMessages;

  bool _hasMoreMessages = true;
  bool get hasMoreMessages => _hasMoreMessages;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MessageModel? _replyToMessage;
  MessageModel? get replyToMessage => _replyToMessage;

  void setReplyToMessage(MessageModel? message) {
    _replyToMessage = message;
    notifyListeners();
  }

  void clearReplyToMessage() {
    _replyToMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Assuming current user ID is 1 for now, this should come from Auth state
  int _currentUserId = 1;
int get currentUserId => _currentUserId;

Future<void> loadCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  _currentUserId = prefs.getInt('user_id') ?? 1;
  notifyListeners();
}

  Future<void> fetchConversations() async {
    _isLoadingConversations = true;
    notifyListeners();

    try {
      _conversations = await repository.getConversations();
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء جلب المحادثات";
      debugPrint("Error fetching conversations: $e");
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int conversationId, {bool keepExistingMessages = false}) async {
    _activeConversationId = conversationId;
    // لا نمسح الرسائل القديمة حتى نجلب الجديدة بنجاح
    if (!keepExistingMessages && _messages.isEmpty) {
      _isLoadingMessages = true;
    }
    _currentPage = 1;
    _hasMoreMessages = true;
    notifyListeners();

    try {
      final newMessages = await repository.getMessages(conversationId, page: _currentPage);
      _messages = newMessages;
      if (newMessages.length < 20) {
        _hasMoreMessages = false;
      }
      // Mark as read with the latest message ID
      if (newMessages.isNotEmpty) {
        await repository.markAsRead(conversationId, messageId: newMessages.first.id);
      }
      
      // Update unread count in conversations list
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = ConversationModel(
          id: _conversations[index].id,
          name: _conversations[index].name,
          type: _conversations[index].type,
          lastMessage: _conversations[index].lastMessage,
          participants: _conversations[index].participants,
          unreadCount: 0,
          updatedAt: _conversations[index].updatedAt,
          avatar: _conversations[index].avatar,
        );
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreMessages(int conversationId) async {
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;

    _isLoadingMoreMessages = true;
    _currentPage++;
    notifyListeners();

    try {
      final moreMessages = await repository.getMessages(conversationId, page: _currentPage);
      if (moreMessages.isEmpty || moreMessages.length < 20) {
        _hasMoreMessages = false;
      }
      _messages.addAll(moreMessages);
    } catch (e) {
      debugPrint("Error fetching more messages: $e");
      _currentPage--;
    } finally {
      _isLoadingMoreMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int conversationId, String content, {String? type, String? filePath}) async {
    final replyId = _replyToMessage?.id;
    _replyToMessage = null; // Clear reply state immediately
    
    // Create temporary message for optimistic UI and progress tracking
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    // البحث عن الرسالة المراد الرد عليها
    MessageModel? replyToMsg;
    if (replyId != null) {
      try {
        replyToMsg = messages.firstWhere((m) => m.id == replyId);
      } catch (_) {
        replyToMsg = null;
      }
    }

    final tempMessage = MessageModel(
      id: tempId,
      conversationId: conversationId,
      userId: _currentUserId,
      content: content.isEmpty && type != 'text' ? (type == 'image' ? '📷 صورة' : '📁 ملف') : content,
      fileUrl: filePath,
      type: _parseMessageType(type),
      createdAt: DateTime.now(),
      status: 'sending',
      uploadProgress: (type == 'text' || filePath == null) ? null : 0.0,
      replyTo: replyToMsg,
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final newMessage = await repository.sendMessage(
        conversationId, 
        content, 
        type: type, 
        filePath: filePath, 
        replyToId: replyId,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            final index = _messages.indexWhere((m) => m.id == tempId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(uploadProgress: progress);
              notifyListeners();
            }
          }
        },
      );
      
      // Replace temp message with actual message
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = newMessage;
      } else {
        _messages.insert(0, newMessage);
      }
      
      // Update last message in conversation list
      _updateLastMessageInConversation(conversationId, newMessage);
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء إرسال الرسالة";
      debugPrint("Error sending message: $e");
      // بدلا من حذف الرسالة، نجعل حالتها 'failed' لتبقى في الشات مع زر إعادة الإرسال
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: 'failed', uploadProgress: null);
      }
    } finally {
      notifyListeners();
    }
  }

  MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image': return MessageType.image;
      case 'video': return MessageType.video;
      case 'audio': return MessageType.audio;
      case 'document': return MessageType.document;
      case 'event': return MessageType.event;
      default: return MessageType.text;
    }
  }

  Future<void> retryMessage(MessageModel failedMessage) async {
    final index = _messages.indexWhere((m) => m.id == failedMessage.id);
    if (index != -1) {
      // إرجاع حالة الرسالة إلى 'sending'
      _messages[index] = _messages[index].copyWith(
        status: 'sending',
        uploadProgress: failedMessage.fileUrl != null && _isLocalPath(failedMessage.fileUrl) ? 0.0 : null,
      );
      notifyListeners();
    }

    try {
      final String typeString = failedMessage.type.toString().split('.').last;
      final newMessage = await repository.sendMessage(
        failedMessage.conversationId, 
        failedMessage.content, 
        type: typeString, 
        filePath: failedMessage.fileUrl, 
        replyToId: failedMessage.replyTo?.id,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            final idx = _messages.indexWhere((m) => m.id == failedMessage.id);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(uploadProgress: progress);
              notifyListeners();
            }
          }
        },
      );
      
      final idx = _messages.indexWhere((m) => m.id == failedMessage.id);
      if (idx != -1) {
        _messages[idx] = newMessage;
      }
      _updateLastMessageInConversation(failedMessage.conversationId, newMessage);
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == failedMessage.id);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(status: 'failed', uploadProgress: null);
      }
    } finally {
      notifyListeners();
    }
  }

  bool _isLocalPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('/') || path.contains(':\\');
  }

  Future<void> sendEventMessage(int conversationId, Map<String, dynamic> eventData) async {
    _isSendingMessage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createEventMessage(conversationId, eventData);
      // Fetch messages to load the newly created event message without clearing list
      await fetchMessages(conversationId, keepExistingMessages: true);
      await fetchConversations(); // Update list preview
    } catch (e) {
      if (e is DioException) {
        _errorMessage = e.response?.data['message'] ?? "حدث خطأ أثناء إنشاء الفعالية";
      } else {
        _errorMessage = "حدث خطأ أثناء إنشاء الفعالية";
      }
      debugPrint("Error sending event: $e");
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }
  
  void _updateLastMessageInConversation(int conversationId, MessageModel message) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = ConversationModel(
        id: _conversations[index].id,
        name: _conversations[index].name,
        type: _conversations[index].type,
        lastMessage: message,
        participants: _conversations[index].participants,
        unreadCount: _conversations[index].unreadCount,
        updatedAt: message.createdAt,
        avatar: _conversations[index].avatar,
      );
      // Move to top
      final conv = _conversations.removeAt(index);
      _conversations.insert(0, conv);
      notifyListeners();
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      final success = await repository.deleteMessage(messageId);
      if (success) {
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  Future<bool> addParticipant(int conversationId, int userId) async {
    try {
      final success = await repository.addParticipant(conversationId, userId);
      if (success) await fetchConversations();
      return success;
    } catch (e) {
      debugPrint("Error adding participant: $e");
      return false;
    }
  }

  Future<bool> removeParticipant(int conversationId, int userId) async {
    try {
      final success = await repository.removeParticipant(conversationId, userId);
      if (success) await fetchConversations();
      return success;
    } catch (e) {
      debugPrint("Error removing participant: $e");
      return false;
    }
  }

  Future<bool> changeParticipantRole(int conversationId, int userId, String role) async {
    try {
      final success = await repository.changeParticipantRole(conversationId, userId, role);
      if (success) await fetchConversations();
      return success;
    } catch (e) {
      debugPrint("Error changing role: $e");
      return false;
    }
  }

  Future<bool> leaveConversation(int conversationId) async {
    try {
      final success = await repository.leaveConversation(conversationId);
      if (success) await fetchConversations();
      return success;
    } catch (e) {
      debugPrint("Error leaving conversation: $e");
      return false;
    }
  }

  void clearActiveConversation() {
    _activeConversationId = null;
    _messages = [];
  }

  Future<bool> updateConversation(int conversationId, {String? name, String? avatarPath}) async {
    try {
      final success = await repository.updateConversation(conversationId, name: name, avatarPath: avatarPath);
      if (success) await fetchConversations();
      return success;
    } catch (e) {
      debugPrint("Error updating conversation: $e");
      return false;
    }
  }

  Future<void> rsvpToEvent(int eventId, String status) async {
    // Optimistic update
    final msgIndex = _messages.indexWhere((m) => m.event?.id == eventId);
    if (msgIndex != -1) {
      final oldEvent = _messages[msgIndex].event!;
      final oldRsvp = oldEvent.userRsvp;
      int newCount = oldEvent.attendeesCount;

      if (oldRsvp != status) {
        if (status == 'attending' && oldRsvp != 'attending') {
          newCount++;
        } else if (status != 'attending' && oldRsvp == 'attending') {
          newCount--;
        }

        final updatedEvent = oldEvent.copyWith(
          userRsvp: status,
          attendeesCount: newCount,
        );
        _messages[msgIndex] = _messages[msgIndex].copyWith(event: updatedEvent);
        notifyListeners();
      }
    }

    try {
      await repository.rsvpToEvent(eventId, status);
    } catch (e) {
      debugPrint("Error updating RSVP: $e");
      // Revert could be added here
    }
  }

  Future<void> toggleReaction(int messageId, String reactionEmoji) async {
    final msgIndex = _messages.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final oldReactions = List<ReactionModel>.from(_messages[msgIndex].reactions);
    
    // Optimistic update
    final myReactionIndex = oldReactions.indexWhere((r) => r.userId == _currentUserId);
    
    List<ReactionModel> newReactions = List.from(oldReactions);
    if (myReactionIndex != -1) {
      if (oldReactions[myReactionIndex].reaction == reactionEmoji) {
        newReactions.removeAt(myReactionIndex);
      } else {
        newReactions[myReactionIndex] = ReactionModel(
          id: oldReactions[myReactionIndex].id,
          messageId: messageId,
          userId: _currentUserId,
          userName: "أنت",
          reaction: reactionEmoji,
        );
      }
    } else {
      newReactions.add(ReactionModel(
        id: 0,
        messageId: messageId,
        userId: _currentUserId,
        userName: "أنت",
        reaction: reactionEmoji,
      ));
    }

    _messages[msgIndex] = _messages[msgIndex].copyWith(reactions: newReactions);
    notifyListeners();

    try {
      final updatedReactionsJson = await repository.toggleReaction(messageId, reactionEmoji);
      final updatedReactions = updatedReactionsJson.map((r) => ReactionModel.fromJson(r)).toList();
      
      // Update with real data from server
      final latestIndex = _messages.indexWhere((m) => m.id == messageId);
      if (latestIndex != -1) {
        _messages[latestIndex] = _messages[latestIndex].copyWith(reactions: updatedReactions);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error toggling reaction: $e");
      // Revert
      final revertIndex = _messages.indexWhere((m) => m.id == messageId);
      if (revertIndex != -1) {
        _messages[revertIndex] = _messages[revertIndex].copyWith(reactions: oldReactions);
        notifyListeners();
      }
    }
  }
}
