import 'package:dio/dio.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app_config.dart';

class ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSource({required this.dio}) {
    dio.options.baseUrl = AppConfig.apiBaseUrl;
    dio.options.headers['Accept'] = 'application/json';
    
    // Setup interceptor to inject token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await dio.get('/conversations');
      // Laravel returns paginated: {success: true, data: {current_page: 1, data: [...]}}
      final responseData = response.data['data'] ?? response.data;
      List<dynamic> items;
      if (responseData is List) {
        items = responseData;
      } else if (responseData is Map && responseData['data'] is List) {
        items = responseData['data'];
      } else {
        items = [];
      }
      return items.map((e) => ConversationModel.fromJson(e)).toList();
    } catch (e) {
      print('Error in getConversations: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await dio.get('/users');
      return response.data['data'] ?? response.data;
    } catch (e) {
      print('Error in getUsers: $e');
      rethrow;
    }
  }

  Future<ConversationModel> createConversation(List<int> participantIds, {String? name, bool isGroup = false, String? avatarPath}) async {
    try {
      dynamic requestData;
      
      if (isGroup) {
        // Group: needs name + participants[]
        if (avatarPath != null) {
          final bytes = await (XFile(avatarPath)).readAsBytes();
          final formData = FormData();
          formData.fields.addAll([
            const MapEntry('type', 'group'),
            MapEntry('name', name ?? ''),
          ]);
          for (var id in participantIds) {
            formData.fields.add(MapEntry('participants[]', id.toString()));
          }
          formData.files.add(MapEntry(
            'avatar',
            MultipartFile.fromBytes(bytes, filename: 'avatar.jpg'),
          ));
          requestData = formData;
        } else {
          requestData = {
            'type': 'group',
            'name': name,
            'participants': participantIds,
          };
        }
      } else {
        // Private: needs user_id (single other user)
        requestData = {
          'type': 'private',
          'user_id': participantIds.first,
        };
      }

      final response = await dio.post('/conversations', data: requestData);
      final data = response.data['data'] ?? response.data;
      return ConversationModel.fromJson(data);
    } catch (e) {
      if (e is DioException) {
        print('Error in createConversation: ${e.response?.statusCode}');
        print('Response body: ${e.response?.data}');
      }
      print('Error in createConversation: $e');
      rethrow;
    }
  }

  Future<List<MessageModel>> getMessages(int conversationId, {int page = 1}) async {
    try {
      final response = await dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: {'page': page},
      );
      // Laravel returns paginated: {success: true, data: {current_page: 1, data: [...]}}
      final responseData = response.data['data'] ?? response.data;
      List<dynamic> items;
      if (responseData is List) {
        items = responseData;
      } else if (responseData is Map && responseData['data'] is List) {
        items = responseData['data'];
      } else {
        items = [];
      }
      return items.map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      print('Error in getMessages: $e');
      rethrow;
    }
  }

  Future<MessageModel> sendMessage(int conversationId, String content, {String? type, String? filePath, int? replyToId, void Function(int, int)? onSendProgress}) async {
    try {
      dynamic requestData;
      final msgType = type ?? 'text';
      final msgContent = content.isEmpty && msgType != 'text' ? '📷 صورة' : content;
      
      if (filePath != null) {
        final fileName = filePath.split('/').last.split('\\').last;
        requestData = FormData.fromMap({
          'content': msgContent,
          'type': msgType,
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
        });
      } else {
        requestData = {
          'content': msgContent,
          'type': msgType,
          if (replyToId != null) 'reply_to_id': replyToId,
        };
      }
 
      final response = await dio.post(
        '/conversations/$conversationId/messages', 
        data: requestData,
        onSendProgress: onSendProgress,
      );
      final data = response.data['data'] ?? response.data;
      return MessageModel.fromJson(data);
    } catch (e) {
      print('Error in sendMessage: $e');
      rethrow;
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    try {
      await dio.delete('/messages/$messageId');
      return true;
    } catch (e) {
      print('Error in deleteMessage: $e');
      rethrow;
    }
  }

  Future<void> createEventMessage(int conversationId, Map<String, dynamic> eventData) async {
    try {
      // POST /api/v1/events
      await dio.post('/events', data: {
        'conversation_id': conversationId,
        ...eventData,
      });
    } catch (e) {
      print('Error in createEventMessage: $e');
      rethrow;
    }
  }

  Future<bool> markAsRead(int conversationId, {int? messageId}) async {
    try {
      await dio.put('/conversations/$conversationId/messages/read', data: {
        if (messageId != null) 'message_id': messageId,
      });
      return true;
    } catch (e) {
      // Don't crash if mark-as-read fails
      print('Error in markAsRead: $e');
      return false;
    }
  }

  Future<bool> addParticipant(int conversationId, int userId) async {
    try {
      await dio.post('/conversations/$conversationId/participants', data: {'user_id': userId});
      return true;
    } catch (e) {
      print('Error in addParticipant: $e');
      rethrow;
    }
  }

  Future<bool> removeParticipant(int conversationId, int userId) async {
    try {
      await dio.delete('/conversations/$conversationId/participants/$userId');
      return true;
    } catch (e) {
      print('Error in removeParticipant: $e');
      rethrow;
    }
  }

  Future<bool> changeParticipantRole(int conversationId, int userId, String role) async {
    try {
      await dio.put('/conversations/$conversationId/participants/$userId', data: {'role': role});
      return true;
    } catch (e) {
      print('Error in changeParticipantRole: $e');
      rethrow;
    }
  }

  Future<bool> leaveConversation(int conversationId) async {
    try {
      await dio.delete('/conversations/$conversationId/leave');
      return true;
    } catch (e) {
      print('Error in leaveConversation: $e');
      rethrow;
    }
  }

  Future<bool> updateConversation(int conversationId, {String? name, String? avatarPath}) async {
    try {
      dynamic requestData;
      if (avatarPath != null) {
        final bytes = await (XFile(avatarPath)).readAsBytes();
        final formData = FormData();
        if (name != null) formData.fields.add(MapEntry('name', name));
        formData.fields.add(const MapEntry('_method', 'PUT'));
        formData.files.add(MapEntry(
          'avatar',
          MultipartFile.fromBytes(bytes, filename: 'avatar.jpg'),
        ));
        requestData = formData;
      } else {
        requestData = {};
        if (name != null) requestData['name'] = name;
        requestData['_method'] = 'PUT';
      }

      await dio.post('/conversations/$conversationId', data: requestData);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rsvpToEvent(int eventId, String status) async {
    try {
      await dio.post(
        '/events/$eventId/rsvp',
        data: {'status': status},
      );
    } catch (e) {
      print('Error in rsvpToEvent: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> toggleReaction(int messageId, String reaction) async {
    try {
      final response = await dio.post(
        '/messages/$messageId/react',
        data: {'reaction': reaction},
      );
      return response.data['data'] as List;
    } catch (e) {
      print('Error in toggleReaction: $e');
      rethrow;
    }
  }
}
