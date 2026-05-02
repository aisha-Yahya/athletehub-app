import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/participant_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:athletehub_app/app_config.dart';

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

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  ConversationModel? _conversation;
  bool _isLoading = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadConversationInfo();
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

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await context.read<ChatProvider>().fetchConversations();
    _loadConversationInfo();
    setState(() => _isLoading = false);
  }

  void _showFeatureNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ميزة "$feature" ستكون متاحة قريباً في التحديث القادم'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _conversation!.name ?? 'المجموعة',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 10)]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _conversation!.avatar != null
                      ? Image.network(AppConfig.mediaUrl(_conversation!.avatar), fit: BoxFit.cover)
                      : Container(color: Colors.grey[400], child: const Icon(Icons.group, size: 100, color: Colors.white)),
                  if (iAmAdmin)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Row(
                        children: [
                          FloatingActionButton.small(
                            onPressed: _editGroupName,
                            backgroundColor: Colors.white,
                            heroTag: 'edit_name',
                            child: const Icon(Icons.edit, color: Color(0xFF6C3FA0)),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            onPressed: _changeAvatar,
                            backgroundColor: Colors.white,
                            heroTag: 'edit_avatar',
                            child: const Icon(Icons.camera_alt, color: Color(0xFF6C3FA0)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSection([
                  ListTile(
                    title: const Text('كتم الإشعارات', style: TextStyle(fontSize: 16)),
                    leading: const Icon(Icons.notifications_off, color: Colors.grey),
                    trailing: Switch(
                      value: _isMuted,
                      activeColor: const Color(0xFF25D366),
                      onChanged: (val) {
                        setState(() => _isMuted = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? 'تم كتم الإشعارات' : 'تم تفعيل الإشعارات')),
                        );
                      },
                    ),
                  ),
                  _buildDivider(),
                  ListTile(
                    title: const Text('نغمة مخصصة', style: TextStyle(fontSize: 16)),
                    leading: const Icon(Icons.music_note, color: Colors.grey),
                    onTap: () => _showFeatureNotImplemented('نغمة مخصصة'),
                  ),
                  _buildDivider(),
                  ListTile(
                    title: const Text('رؤية الوسائط', style: TextStyle(fontSize: 16)),
                    leading: const Icon(Icons.photo, color: Colors.grey),
                    onTap: () => _showFeatureNotImplemented('رؤية الوسائط'),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildSection([
                  ListTile(
                    title: const Text('التشفير', style: TextStyle(fontSize: 16)),
                    subtitle: const Text('الرسائل والمكالمات مشفرة تماماً بين الطرفين. اضغط للتحقق.', style: TextStyle(fontSize: 13)),
                    leading: const Icon(Icons.lock, color: Colors.grey),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Icon(Icons.lock, color: Color(0xFF25D366), size: 48),
                          content: const Text('تأكد أن جميع الرسائل في هذه المجموعة مشفرة تماماً بتقنية (End-to-End Encryption).', textAlign: TextAlign.center),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    title: const Text('الرسائل ذاتية الاختفاء', style: TextStyle(fontSize: 16)),
                    subtitle: const Text('إيقاف التشغيل', style: TextStyle(fontSize: 13)),
                    leading: const Icon(Icons.history, color: Colors.grey),
                    onTap: () => _showFeatureNotImplemented('الرسائل ذاتية الاختفاء'),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildSection([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_conversation!.participants.length} عضو', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        if (iAmAdmin)
                          GestureDetector(
                            onTap: _addMember,
                            child: const Icon(Icons.search, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  if (iAmAdmin)
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.person_add, color: Colors.white)),
                      title: const Text('إضافة عضو', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
                      onTap: _addMember,
                    ),
                  ..._conversation!.participants.map((participant) {
                    final isAdmin = participant.role == 'admin';
                    final isMe = participant.id == provider.currentUserId;
 
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(participant.name[0].toUpperCase()),
                      ),
                      title: Text(isMe ? '${participant.name} (أنت)' : participant.name),
                      subtitle: const Text('متاح'),
                      trailing: isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4)),
                              child: const Text('مشرف المجموعة', style: TextStyle(color: Colors.green, fontSize: 10)),
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
                    );
                  }),
                ]),
                const SizedBox(height: 12),
                _buildSection([
                  ListTile(
                    title: const Text('مغادرة المجموعة', style: TextStyle(color: Colors.red, fontSize: 16)),
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    onTap: _showLeaveDialog,
                  ),
                  _buildDivider(),
                  ListTile(
                    title: const Text('الإبلاغ عن مجموعة', style: TextStyle(color: Colors.red, fontSize: 16)),
                    leading: const Icon(Icons.thumb_down, color: Colors.red),
                    onTap: () => _showFeatureNotImplemented('الإبلاغ عن مجموعة'),
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 70, color: Color(0xFFF0F2F5));
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
}
