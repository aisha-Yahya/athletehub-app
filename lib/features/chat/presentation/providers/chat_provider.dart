import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/reaction_model.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../app_config.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository repository;

  // ============ نظام Polling للرسائل الفورية ============
  Timer? _messagePollingTimer;
  Timer? _conversationPollingTimer;
  bool _isPollingMessages = false;

  /// بدء المراقبة الدورية للرسائل الجديدة (كل 3 ثواني)
  void startMessagePolling(int conversationId) {
    stopMessagePolling(); // إيقاف أي مراقبة سابقة
    _activeConversationId = conversationId; // تعيين المحادثة النشطة
    debugPrint("🔄 بدء مراقبة الرسائل الجديدة للمحادثة: $conversationId");
    
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isPollingMessages) return; // تجنب التداخل
      _isPollingMessages = true;
      
      try {
        // تحقق أن المحادثة النشطة لم تتغير قبل الطلب
        if (_activeConversationId != conversationId) return;
        
        final newMessages = await repository.getMessages(conversationId, page: 1);
        
        // تحقق مرة أخرى بعد الطلب (ربما تغيرت المحادثة أثناء الانتظار)
        if (_activeConversationId != conversationId) return;
        
        if (newMessages.isNotEmpty) {
          bool hasNewMessages = false;
          
          for (final msg in newMessages) {
            // تأكد أن الرسالة تنتمي لنفس المحادثة النشطة
            if (msg.conversationId != conversationId) continue;
            
            // إضافة الرسائل الجديدة فقط (التي لا توجد في القائمة الحالية)
            if (!_messages.any((m) => m.id == msg.id) && msg.id > 0) {
              _messages.insert(0, msg);
              hasNewMessages = true;
              debugPrint("✨ رسالة جديدة وصلت: ID=${msg.id}");
            }
          }
          
          if (hasNewMessages) {
            // ترتيب الرسائل حسب الوقت (الأحدث أولاً)
            _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            // إزالة التكرارات
            final seen = <int>{};
            _messages.removeWhere((m) => !seen.add(m.id));
            
            _updateLastMessageInConversation(conversationId, _messages.first);
            
            // إرسال طلب للمقروئية مباشرة بما أن المستخدم فاتح المحادثة
            repository.markAsRead(conversationId, messageId: _messages.first.id).catchError((_) => false);
            
            notifyListeners();
          }
        }
      } catch (e) {
        // لا نطبع الخطأ حتى لا نزعج المستخدم
      } finally {
        _isPollingMessages = false;
      }
    });
  }

  /// إيقاف مراقبة الرسائل
  void stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
    _isPollingMessages = false;
  }

  /// بدء مراقبة المحادثات الجديدة (كل 5 ثواني)
  void startConversationPolling() {
    _conversationPollingTimer?.cancel();
    _conversationPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final freshConversations = await repository.getConversations();
        if (freshConversations.isNotEmpty) {
          // تصفير العداد محلياً للمحادثة المفتوحة حالياً حتى لا يظهر الإشعار بالخطأ
          for (int i = 0; i < freshConversations.length; i++) {
            if (freshConversations[i].id == _activeConversationId) {
              freshConversations[i] = ConversationModel(
                id: freshConversations[i].id,
                name: freshConversations[i].name,
                type: freshConversations[i].type,
                lastMessage: freshConversations[i].lastMessage,
                participants: freshConversations[i].participants,
                unreadCount: 0,
                updatedAt: freshConversations[i].updatedAt,
                avatar: freshConversations[i].avatar,
              );
            }
          }
          _conversations = freshConversations;
          notifyListeners();
        }
      } catch (e) {
        // صامت
      }
    });
  }

  /// إيقاف مراقبة المحادثات
  void stopConversationPolling() {
    _conversationPollingTimer?.cancel();
    _conversationPollingTimer = null;
  }

  // ============ واجهات التوافق مع الكود القديم ============
  
  Future<void> initGlobalRealTimeConnection() async {
    // استبدال بـ Polling للمحادثات
    startConversationPolling();
  }

  Future<void> initRealTimeConnection(int conversationId) async {
    // استبدال بـ Polling للرسائل
    startMessagePolling(conversationId);
  }

  Future<void> disconnectRealTime() async {
    stopMessagePolling();
    debugPrint("🛑 تم إيقاف مراقبة الرسائل");
  }

  Future<void> disconnectAllRealTime() async {
    stopMessagePolling();
    stopConversationPolling();
    debugPrint("🛑 تم إيقاف جميع المراقبات");
  }

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
  
  // تفعيل الاتصال العام بعد جلب معرّف المستخدم
  initGlobalRealTimeConnection();
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
      
      // بدء الاتصال اللحظي بعد تحميل الرسائل بنجاح
      initRealTimeConnection(conversationId);
      
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
        unreadCount: conversationId == _activeConversationId ? 0 : _conversations[index].unreadCount,
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
    stopMessagePolling(); // إيقاف polling أولاً
    _activeConversationId = null;
    _messages = [];
    debugPrint("🧹 تم مسح المحادثة النشطة وإيقاف المراقبة");
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
