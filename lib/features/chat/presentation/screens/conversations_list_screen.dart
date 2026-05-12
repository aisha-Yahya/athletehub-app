import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:athletehub_app/app_config.dart';
import '../providers/chat_provider.dart';
import '../../data/models/conversation_model.dart';
import 'chat_screen.dart';
import 'package:athletehub_app/app_router.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> with RouteAware {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatProvider>().loadCurrentUser();
      await context.read<ChatProvider>().fetchConversations();
    });
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Search
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'المجموعات',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Icon(Icons.search, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFilterChip('الكل', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('مجموعاتي', 1),
                    const SizedBox(width: 8),
                    _buildFilterChip('متاحة في خطتك', 2),
                    const SizedBox(width: 8),
                    _buildFilterChip('مقفلة 🔒', 3),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Group List
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    if (chatProvider.isLoadingConversations) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allConversations = chatProvider.conversations;

                    // Apply filters
                    List<ConversationModel> filteredConversations;
                    if (_selectedFilterIndex == 1) {
                      // مجموعاتي - groups only
                      filteredConversations = allConversations
                          .where((c) => c.type == ConversationType.group)
                          .toList();
                    } else {
                      filteredConversations = allConversations;
                    }

                    if (filteredConversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مجموعات بعد',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => chatProvider.fetchConversations(),
                              child: const Text('تحديث'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => chatProvider.fetchConversations(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredConversations.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final conversation = filteredConversations[index];
                          final title = conversation.getDisplayName(chatProvider.currentUserId);
                          final membersCount = conversation.participants.length;
                          final isGroup = conversation.type == ConversationType.group;
                          final avatarUrl = AppConfig.mediaUrl(conversation.avatar);
                          final colors = [
                            const Color(0xFFFEF3C7),
                            const Color(0xFFE0F2FE),
                            const Color(0xFFFCE7F3),
                            const Color(0xFFE0E7FF),
                            const Color(0xFFDCFCE7),
                            const Color(0xFFFEF9C3),
                          ];

                          return _buildGroupListItem(
                            title: title,
                            subtitle: isGroup 
                                ? '$membersCount عضو'
                                : (conversation.lastMessage?.content ?? 'محادثة جديدة'),
                            avatarUrl: avatarUrl,
                            isGroup: isGroup,
                            bgColor: colors[index % colors.length],
                            isJoined: true,
                            isLocked: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId: conversation.id,
                                    title: title,
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

              // Bottom Banner
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.star, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'افتح المزيد من المجموعات',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'ترقية خطتك للوصول لجميع المجموعات',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupListItem({
    required String title,
    required String subtitle,
    required String avatarUrl,
    required bool isGroup,
    required Color bgColor,
    required bool isJoined,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            // Icon / Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                image: avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl.isEmpty
                  ? Center(
                      child: Text(isGroup ? '👥' : '💬', style: const TextStyle(fontSize: 28)),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Text & Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isJoined) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('منضم', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                              SizedBox(width: 2),
                              Icon(Icons.check, color: Color(0xFF166534), size: 10),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFFB45309), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'يتطلب خطة احترافي',
                          style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            
            // Arrow
            const SizedBox(width: 8),
            Icon(
              isLocked ? Icons.lock_outline : Icons.arrow_back,
              color: isLocked ? const Color(0xFFB45309) : const Color(0xFF3B82F6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
