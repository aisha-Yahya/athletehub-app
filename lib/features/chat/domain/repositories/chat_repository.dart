import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

abstract class ChatRepository {
  Future<List<dynamic>> getUsers();
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel> createConversation(List<int> participantIds, {String? name, bool isGroup = false, String? avatarPath});
  Future<List<MessageModel>> getMessages(int conversationId, {int page = 1});
  Future<MessageModel> sendMessage(int conversationId, String content, {String? type, String? filePath, int? replyToId, void Function(int, int)? onSendProgress});
  Future<bool> deleteMessage(int messageId);
  Future<void> createEventMessage(int conversationId, Map<String, dynamic> eventData);
  Future<bool> markAsRead(int conversationId, {int? messageId});
  Future<bool> addParticipant(int conversationId, int userId);
  Future<bool> removeParticipant(int conversationId, int userId);
  Future<bool> changeParticipantRole(int conversationId, int userId, String role);
  Future<bool> leaveConversation(int conversationId);
  Future<bool> updateConversation(int conversationId, {String? name, String? avatarPath});
  Future<void> rsvpToEvent(int eventId, String status);
  Future<List<dynamic>> toggleReaction(int messageId, String reaction);
}
