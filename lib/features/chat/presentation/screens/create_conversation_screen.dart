import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'package:image_picker/image_picker.dart';

class CreateConversationScreen extends StatefulWidget {
  const CreateConversationScreen({super.key});

  @override
  State<CreateConversationScreen> createState() => _CreateConversationScreenState();
}

class _CreateConversationScreenState extends State<CreateConversationScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _error = '';

  final Set<int> _selectedUserIds = {};
  bool _isGroup = false;
  final _nameController = TextEditingController();
  String? _avatarPath;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _avatarPath = file.path);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final remoteSource = context.read<ChatProvider>().repository;
      final users = await remoteSource.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _createConversation() async {
    if (_selectedUserIds.isEmpty) return;
    if (_isGroup && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المجموعة')),
      );
      return;
    }

    setState(() => _isCreating = true);
    final provider = context.read<ChatProvider>();
    
    try {
      // Call API to create conversation
      final newConv = await provider.repository.createConversation(
        _selectedUserIds.toList().toSet().toList(),
        isGroup: _isGroup,
        name: _isGroup ? _nameController.text.trim() : null,
        avatarPath: _isGroup ? _avatarPath : null,
      );

      // Refresh list
      await provider.fetchConversations();

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: newConv.id,
              title: newConv.getDisplayName(provider.currentUserId),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إنشاء المحادثة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroup ? 'مجموعة جديدة' : 'محادثة جديدة'),
        actions: [
          if (_selectedUserIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createConversation,
            )
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('إنشاء مجموعة'),
            value: _isGroup,
            onChanged: (val) {
              setState(() {
                _isGroup = val;
                if (!val && _selectedUserIds.length > 1) {
                  final first = _selectedUserIds.first;
                  _selectedUserIds.clear();
                  _selectedUserIds.add(first);
                }
              });
            },
          ),
          if (_isGroup) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: _avatarPath != null ? NetworkImage(_avatarPath!) : null,
                      child: _avatarPath == null ? const Icon(Icons.camera_alt) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المجموعة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error.isNotEmpty)
            Expanded(child: Center(child: Text(_error, style: const TextStyle(color: Colors.red))))
          else if (_users.isEmpty)
            const Expanded(child: Center(child: Text('لا يوجد مستخدمين.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isSelected = _selectedUserIds.contains(user['id']);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user['name']?.substring(0, 1) ?? 'U'),
                    ),
                    title: Text(user['name'] ?? 'Unknown'),
                    trailing: _isGroup
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(user['id']);
                              } else {
                                _selectedUserIds.remove(user['id']);
                              }
                            });
                          },
                        )
                      : Radio<int>(
                          value: user['id'],
                          groupValue: _selectedUserIds.isNotEmpty ? _selectedUserIds.first : null,
                          onChanged: (val) {
                            setState(() {
                              _selectedUserIds.clear();
                              if (val != null) _selectedUserIds.add(val);
                            });
                          },
                        ),
                  onTap: () {
                    setState(() {
                      if (_isGroup) {
                        if (isSelected) {
                          _selectedUserIds.remove(user['id']);
                        } else {
                          _selectedUserIds.add(user['id']);
                        }
                      } else {
                        _selectedUserIds.clear();
                        _selectedUserIds.add(user['id']);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
