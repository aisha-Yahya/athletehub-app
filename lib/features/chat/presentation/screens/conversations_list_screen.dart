import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../../data/models/conversation_model.dart';
import 'chat_screen.dart';
import 'create_conversation_screen.dart';
import 'package:athletehub_app/app_router.dart';
import 'package:athletehub_app/app_config.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> with RouteAware {
  bool _isSearching = false;
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<ChatProvider>().fetchConversations();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatProvider>().loadCurrentUser();
      await context.read<ChatProvider>().fetchConversations();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return DateFormat('HH:mm').format(date);
    } else if (dateToCheck == yesterday) {
      return 'أمس';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'البحث...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.black87),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text('واتساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateConversationScreen()),
          );
        },
        backgroundColor: const Color(0xFF25D366),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('الكل', 0),
                const SizedBox(width: 8),
                _buildFilterChip('غير مقروءة', 1),
                const SizedBox(width: 8),
                _buildFilterChip('المجموعات', 2),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoadingConversations) {
                  return const Center(child: CircularProgressIndicator());
                }

                var filteredConversations = chatProvider.conversations.where((c) {
                  final name = c.getDisplayName(chatProvider.currentUserId).toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (_selectedFilterIndex == 1) {
                  filteredConversations = filteredConversations.where((c) => c.unreadCount > 0).toList();
                } else if (_selectedFilterIndex == 2) {
                  filteredConversations = filteredConversations.where((c) => c.type == ConversationType.group).toList();
                }

                if (filteredConversations.isEmpty) {
                  return Center(child: Text(_searchQuery.isEmpty ? 'لا توجد محادثات بعد.' : 'لا توجد نتائج للبحث.'));
                }

                return RefreshIndicator(
                  onRefresh: () => chatProvider.fetchConversations(),
                  child: ListView.separated(
                    itemCount: filteredConversations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 16),
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];
                      final isGroup = conversation.type == ConversationType.group;
                      final displayName = conversation.getDisplayName(chatProvider.currentUserId);
                      final lastMessage = conversation.lastMessage;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: (conversation.avatar != null)
                              ? NetworkImage(AppConfig.mediaUrl(conversation.avatar))
                              : null,
                          backgroundColor: isGroup ? Colors.blue[100] : Colors.grey[200],
                          child: conversation.avatar == null
                              ? Icon(
                                  isGroup ? Icons.group : Icons.person,
                                  color: isGroup ? Colors.blue : Colors.grey[600],
                                  size: 30,
                                )
                              : null,
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        subtitle: Row(
                          children: [
                            if (lastMessage != null && lastMessage.userId == chatProvider.currentUserId) ...[
                              Icon(
                                lastMessage.status == 'seen' || lastMessage.status == 'read' || lastMessage.status == 'delivered'
                                    ? Icons.done_all
                                    : Icons.check,
                                size: 16,
                                color: lastMessage.status == 'seen' || lastMessage.status == 'read'
                                    ? Colors.blue
                                    : Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                lastMessage?.content ?? (isGroup ? 'مجموعة جديدة' : 'محادثة جديدة'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDate(conversation.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: (conversation.unreadCount > 0 &&
                                    conversation.lastMessage?.userId != chatProvider.currentUserId)
                                    ? const Color(0xFF25D366) : Colors.grey[500],
                                fontWeight: (conversation.unreadCount > 0 &&
                                    conversation.lastMessage?.userId != chatProvider.currentUserId)
                                    ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (conversation.unreadCount > 0 &&
                                conversation.lastMessage?.userId != chatProvider.currentUserId)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conversation.id,
                                title: displayName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF25D366) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
