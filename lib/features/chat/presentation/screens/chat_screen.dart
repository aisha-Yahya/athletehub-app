import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_field.dart';
import 'group_info_screen.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/participant_model.dart';
import '../../../../app_config.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String title;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchMessages(widget.conversationId);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ChatProvider>();
      if (!provider.isLoadingMoreMessages && provider.hasMoreMessages) {
        provider.fetchMoreMessages(widget.conversationId);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreateEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.event, color: Color(0xFF6C3FA0)),
              SizedBox(width: 8),
              Text('إنشاء فعالية جديدة'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الفعالية *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'الموقع',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF6C3FA0)),
                  title: Text('${selectedDate.year}/${selectedDate.month}/${selectedDate.day}'),
                  subtitle: const Text('اختر التاريخ'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Color(0xFF6C3FA0)),
                  title: Text(selectedTime.format(context)),
                  subtitle: const Text('اختر الوقت'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال عنوان الفعالية')),
                  );
                  return;
                }

                final eventDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                context.read<ChatProvider>().sendEventMessage(
                  widget.conversationId,
                  {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'event_date': eventDateTime.toIso8601String(),
                    'location': locationController.text.trim(),
                  },
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إنشاء الفعالية بنجاح ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C3FA0)),
              child: const Text('إنشاء', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, provider, child) {
            final conv = provider.conversations.firstWhere(
              (c) => c.id == widget.conversationId,
              orElse: () => ConversationModel(
                id: 0,
                type: ConversationType.private,
                participants: [],
                updatedAt: DateTime.now(),
              ),
            );
            final isGroup = conv.type == ConversationType.group;
            
            return InkWell(
              onTap: isGroup ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupInfoScreen(
                      conversationId: widget.conversationId,
                      title: widget.title,
                    ),
                  ),
                );
              } : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isGroup ? const Color(0xFF6C3FA0).withOpacity(0.1) : Colors.grey[200],
                      backgroundImage: conv.avatar != null 
                        ? NetworkImage(AppConfig.mediaUrl(conv.avatar)) 
                        : null,
                      child: conv.avatar == null 
                        ? Text(
                            widget.title.isNotEmpty ? widget.title[0].toUpperCase() : 'G',
                            style: TextStyle(color: isGroup ? const Color(0xFF6C3FA0) : Colors.grey[600], fontWeight: FontWeight.bold),
                          )
                        : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isGroup)
                            Text(
                              '${conv.participants.length} عضو',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              final conv = provider.conversations.firstWhere(
                (c) => c.id == widget.conversationId,
                orElse: () => ConversationModel(
                  id: 0,
                  type: ConversationType.private,
                  participants: [],
                  updatedAt: DateTime.now(),
                ),
              );
              
              if (conv.type == ConversationType.group) {
                final currentParticipant = conv.participants.firstWhere(
                  (p) => p.id == provider.currentUserId,
                  orElse: () => ParticipantModel(id: 0, name: ''),
                );
                final isAdmin = currentParticipant.role == 'admin';

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'event' && isAdmin) {
                      _showCreateEventDialog(context);
                    } else if (value == 'info') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupInfoScreen(
                            conversationId: widget.conversationId,
                            title: widget.title,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (isAdmin)
                      const PopupMenuItem(
                        value: 'event',
                        child: Row(
                          children: [
                            Icon(Icons.event, color: Color(0xFF6C3FA0)),
                            SizedBox(width: 8),
                            Text('إنشاء فعالية'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('معلومات المجموعة'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WhatsApp Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE5DDD5),
              child: Opacity(
                opacity: 0.08,
                child: Image.network(
                  'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFE5DDD5).withOpacity(0.5)),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                if (chatProvider.isLoadingMessages && chatProvider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.messages.isEmpty) {
                  return const Center(child: Text('لا توجد رسائل بعد. ابدأ المحادثة!'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await chatProvider.fetchMessages(widget.conversationId, keepExistingMessages: true);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Show bottom-up
                    itemCount: chatProvider.messages.length + (chatProvider.isLoadingMoreMessages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final message = chatProvider.messages[index];
                      final isMe = message.userId == chatProvider.currentUserId;
                      
                      String? senderName;
                      final conv = chatProvider.conversations.firstWhere(
                        (c) => c.id == widget.conversationId,
                        orElse: () => ConversationModel(id: 0, type: ConversationType.private, participants: [], updatedAt: DateTime.now()),
                      );
                      if (conv.type == ConversationType.group && !isMe) {
                        final participant = conv.participants.firstWhere(
                          (p) => p.id == message.userId,
                          orElse: () => ParticipantModel(id: 0, name: 'Unknown'),
                        );
                        senderName = participant.name;
                      }

                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        senderName: senderName,
                        onRetry: () => chatProvider.retryMessage(message),
                        onDelete: () {
                          context.read<ChatProvider>().deleteMessage(message.id);
                        },
                        isAdmin: conv.participants.firstWhere(
                          (p) => p.id == chatProvider.currentUserId,
                          orElse: () => ParticipantModel(id: 0, name: '')
                        ).role == 'admin',
                        onRsvp: (status) {
                          if (message.event != null) {
                            context.read<ChatProvider>().rsvpToEvent(message.event!.id, status);
                          }
                        },
                        onReact: (emoji) {
                          chatProvider.toggleReaction(message.id, emoji);
                        },
                        onSwipe: (msg) {
                          chatProvider.setReplyToMessage(msg);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          ChatInputField(conversationId: widget.conversationId),
        ],
      ),
    ],
  ),
);
  }
}
