import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ConversationModel> createConversation(List<int> participantIds, {String? name, bool isGroup = false, String? avatarPath}) {
    return remoteDataSource.createConversation(participantIds, name: name, isGroup: isGroup, avatarPath: avatarPath);
  }

  @override
  Future<void> createEventMessage(int conversationId, Map<String, dynamic> eventData) {
    return remoteDataSource.createEventMessage(conversationId, eventData);
  }

  @override
  Future<bool> deleteMessage(int messageId) {
    return remoteDataSource.deleteMessage(messageId);
  }

  @override
  Future<List<dynamic>> getUsers() {
    return remoteDataSource.getUsers();
  }

  @override
  Future<List<ConversationModel>> getConversations({bool all = false}) {
    return remoteDataSource.getConversations(all: all);
  }

  @override
  Future<bool> joinConversation(int conversationId) {
    return remoteDataSource.joinConversation(conversationId);
  }

  @override
  Future<List<MessageModel>> getMessages(int conversationId, {int page = 1}) {
    return remoteDataSource.getMessages(conversationId, page: page);
  }

  @override
  Future<bool> markAsRead(int conversationId, {int? messageId}) {
    return remoteDataSource.markAsRead(conversationId, messageId: messageId);
  }

  @override
  Future<bool> addParticipant(int conversationId, int userId) {
    return remoteDataSource.addParticipant(conversationId, userId);
  }

  @override
  Future<bool> removeParticipant(int conversationId, int userId) {
    return remoteDataSource.removeParticipant(conversationId, userId);
  }

  @override
  Future<bool> changeParticipantRole(int conversationId, int userId, String role) {
    return remoteDataSource.changeParticipantRole(conversationId, userId, role);
  }

  @override
  Future<bool> leaveConversation(int conversationId) {
    return remoteDataSource.leaveConversation(conversationId);
  }

  @override
  Future<bool> updateConversation(int conversationId, {String? name, String? avatarPath}) {
    return remoteDataSource.updateConversation(conversationId, name: name, avatarPath: avatarPath);
  }

  @override
  Future<MessageModel> sendMessage(int conversationId, String content, {String? type, String? filePath, int? replyToId, void Function(int, int)? onSendProgress}) {
    return remoteDataSource.sendMessage(conversationId, content, type: type, filePath: filePath, replyToId: replyToId, onSendProgress: onSendProgress);
  }

  @override
  Future<void> rsvpToEvent(int eventId, String status) {
    return remoteDataSource.rsvpToEvent(eventId, status);
  }

  @override
  Future<List<dynamic>> toggleReaction(int messageId, String reaction) {
    return remoteDataSource.toggleReaction(messageId, reaction);
  }

  @override
  Future<List<dynamic>> getConversationEvents(int conversationId) {
    return remoteDataSource.getConversationEvents(conversationId);
  }
}
