import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/event_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:athletehub_app/app_config.dart';
import 'chat_screen.dart';
import 'event_details_screen.dart';

class GroupInfoScreen extends StatefulWidget {
  final int conversationId;
  final String title;

  const GroupInfoScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> with SingleTickerProviderStateMixin {
  ConversationModel? _conversation;
  late TabController _tabController;
  List<EventModel> _events = [];
  bool _isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _loadConversationInfo();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadConversationInfo() {
    final provider = context.read<ChatProvider>();
    final convIndex = provider.conversations.indexWhere((c) => c.id == widget.conversationId);
    if (convIndex != -1) {
      setState(() {
        _conversation = provider.conversations[convIndex];
      });
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final provider = context.read<ChatProvider>();
      final eventsJson = await provider.repository.getConversationEvents(widget.conversationId);
      setState(() {
        _events = eventsJson.map((e) => EventModel.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _refreshData() async {
    await context.read<ChatProvider>().fetchConversations();
    _loadConversationInfo();
    await _loadEvents();
  }

  void _editGroupName() async {
    final nameController = TextEditingController(text: _conversation?.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل اسم المجموعة'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الجديد')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                final success = await context.read<ChatProvider>().updateConversation(widget.conversationId, name: newName);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الاسم بنجاح')));
                  _refreshData();
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _changeAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final success = await context.read<ChatProvider>().updateConversation(widget.conversationId, avatarPath: file.path);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة بنجاح')));
        _refreshData();
      }
    }
  }

  void _removeParticipant(ParticipantModel participant) async {
    final provider = context.read<ChatProvider>();
    final success = await provider.removeParticipant(widget.conversationId, participant.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إزالة ${participant.name}')));
      _refreshData();
    }
  }

  void _changeRole(ParticipantModel participant, String newRole) async {
    final provider = context.read<ChatProvider>();
    final success = await provider.changeParticipantRole(widget.conversationId, participant.id, newRole);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تغيير الدور بنجاح')));
      _refreshData();
    }
  }

  void _addMember() async {
    final provider = context.read<ChatProvider>();
    try {
      final allUsers = await provider.repository.getUsers();
      final currentMemberIds = _conversation!.participants.map((p) => p.id).toSet();
      final nonMembers = allUsers.where((u) => !currentMemberIds.contains(u['id'])).toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('إضافة عضو للمجموعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (nonMembers.isEmpty)
                  const Text('لا يوجد مستخدمين متاحين للإضافة')
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: nonMembers.length,
                      itemBuilder: (context, index) {
                        final user = nonMembers[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(user['name']?[0] ?? 'U')),
                          title: Text(user['name'] ?? ''),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await provider.addParticipant(widget.conversationId, user['id']);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة ${user['name']}')));
                              _refreshData();
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error fetching users for add: $e");
    }
  }

  void _leaveGroup() async {
    final provider = context.read<ChatProvider>();
    final success = await provider.leaveConversation(widget.conversationId);
    if (success && mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مغادرة المجموعة'),
        content: const Text('هل أنت متأكد أنك تريد مغادرة هذه المجموعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final provider = context.read<ChatProvider>();
    final myParticipant = _conversation!.participants.firstWhere(
      (p) => p.id == provider.currentUserId,
      orElse: () => ParticipantModel(id: 0, name: ''),
    );
    final iAmAdmin = myParticipant.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // SliverAppBar with group avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF6C3FA0),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _conversation!.avatar != null
                      ? Image.network(AppConfig.mediaUrl(_conversation!.avatar), fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.group, size: 80, color: Colors.white38),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                  if (iAmAdmin)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Row(
                        children: [
                          _miniActionButton(Icons.edit, _editGroupName, 'edit_name'),
                          const SizedBox(width: 8),
                          _miniActionButton(Icons.camera_alt, _changeAvatar, 'edit_avatar'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Group info header
          SliverToBoxAdapter(child: _buildGroupHeader()),
          // TabBar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF6C3FA0),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF6C3FA0),
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.event), text: 'الأحداث'),
                  Tab(icon: Icon(Icons.people_outline), text: 'الأعضاء'),
                  Tab(icon: Icon(Icons.info_outline), text: 'المعلومات'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEventsTab(),
            _buildMembersTab(iAmAdmin, provider),
            _buildInfoTab(iAmAdmin),
          ],
        ),
      ),
    );
  }

  Widget _miniActionButton(IconData icon, VoidCallback onTap, String heroTag) {
    return FloatingActionButton.small(
      onPressed: onTap,
      backgroundColor: Colors.white,
      heroTag: heroTag,
      child: Icon(icon, color: const Color(0xFF6C3FA0), size: 18),
    );
  }

  // ============ Group Header ============
  Widget _buildGroupHeader() {
    final conv = _conversation!;
    // Example sport tags - derived from group name or metadata
    final List<String> sportTags = ['رياضة', 'تدريب'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            conv.name ?? 'المجموعة',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.people, '${conv.participants.length} عضو'),
              const SizedBox(width: 12),
              _infoChip(Icons.sports_soccer, 'رياضة'),
              const SizedBox(width: 12),
              _infoChip(Icons.location_on, 'الموقع'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: sportTags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12, color: Color(0xFF6C3FA0))),
              backgroundColor: const Color(0xFF6C3FA0).withOpacity(0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  // ============ Tab 1: Events ============
  Widget _buildEventsTab() {
    if (_isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('لا توجد أحداث', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('لم يتم إنشاء أي أحداث في هذه المجموعة بعد', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          final isPast = event.isPast;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date Block (Right side in RTL)
                      Container(
                        width: 85,
                        decoration: BoxDecoration(
                          color: isPast ? Colors.grey[300] : const Color(0xFFFDF1E3), // Light peach color
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${event.eventDate.day}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isPast ? Colors.grey[500] : Colors.white,
                                shadows: isPast ? [] : [
                                  const Shadow(
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  )
                                ],
                              ),
                            ),
                            Text(
                              event.arabicMonthName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isPast ? Colors.grey[500] : Colors.white,
                                shadows: isPast ? [] : [
                                  const Shadow(
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Details Block (Left side in RTL)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${event.location ?? 'موقع غير محدد'} • ${event.formattedArabicTime}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (event.userRsvp == 'attending') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F0FF),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'مسجل ✓',
                                        style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPast ? Colors.grey[200] : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${event.attendeesCount} سيحضرون',
                                      style: TextStyle(
                                        color: isPast ? Colors.grey[600] : Colors.green[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============ Tab 3: Members ============
  Widget _buildMembersTab(bool iAmAdmin, ChatProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (iAmAdmin)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.person_add, color: Colors.white)),
              title: const Text('إضافة عضو', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
              onTap: _addMember,
            ),
          ),
        const SizedBox(height: 8),
        ..._conversation!.participants.map((participant) {
          final isAdmin = participant.role == 'admin';
          final isMe = participant.id == provider.currentUserId;

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF6C3FA0).withOpacity(0.1),
                child: Text(participant.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6C3FA0), fontWeight: FontWeight.bold)),
              ),
              title: Text(isMe ? '${participant.name} (أنت)' : participant.name),
              subtitle: Text(isAdmin ? 'مشرف المجموعة' : 'عضو', style: TextStyle(fontSize: 12, color: isAdmin ? Colors.green : Colors.grey)),
              trailing: isAdmin
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4)),
                      child: const Text('مشرف', style: TextStyle(color: Colors.green, fontSize: 10)),
                    )
                  : (iAmAdmin && !isMe)
                      ? PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'remove') {
                              _removeParticipant(participant);
                            } else if (val == 'promote') {
                              _changeRole(participant, 'admin');
                            } else if (val == 'demote') {
                              _changeRole(participant, 'member');
                            }
                          },
                          itemBuilder: (context) => [
                            if (!isAdmin) const PopupMenuItem(value: 'promote', child: Text('ترقية لمشرف')),
                            if (isAdmin) const PopupMenuItem(value: 'demote', child: Text('إزالة من الإشراف')),
                            const PopupMenuItem(value: 'remove', child: Text('إزالة من المجموعة', style: TextStyle(color: Colors.red))),
                          ],
                        )
                      : null,
            ),
          );
        }),
      ],
    );
  }

  // ============ Tab 4: Info ============
  Widget _buildInfoTab(bool iAmAdmin) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Mute notifications
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                title: const Text('وصف المجموعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'مجموعة ${_conversation!.name ?? widget.title} - ${_conversation!.participants.length} عضو',
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                ),
                leading: const Icon(Icons.description, color: Color(0xFF6C3FA0)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                title: const Text('تاريخ الإنشاء', style: TextStyle(fontSize: 15)),
                subtitle: Text('${_conversation!.updatedAt.day}/${_conversation!.updatedAt.month}/${_conversation!.updatedAt.year}'),
                leading: const Icon(Icons.calendar_today, color: Colors.grey),
              ),
              const Divider(height: 1, indent: 70),
              ListTile(
                title: const Text('عدد الأعضاء', style: TextStyle(fontSize: 15)),
                subtitle: Text('${_conversation!.participants.length} عضو'),
                leading: const Icon(Icons.people, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Leave & Report
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                title: const Text('مغادرة المجموعة', style: TextStyle(color: Colors.red, fontSize: 16)),
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                onTap: _showLeaveDialog,
              ),
              const Divider(height: 1, indent: 70),
              ListTile(
                title: const Text('الإبلاغ عن مجموعة', style: TextStyle(color: Colors.red, fontSize: 16)),
                leading: const Icon(Icons.thumb_down, color: Colors.red),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ميزة "الإبلاغ عن مجموعة" ستكون متاحة قريباً في التحديث القادم'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// Delegate for pinned TabBar inside NestedScrollView
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
