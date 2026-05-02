import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_provider.dart';
import '../../data/models/message_model.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class ChatInputField extends StatefulWidget {
  final int conversationId;

  const ChatInputField({super.key, required this.conversationId});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _showEmoji = false;

  // ─── تسجيل الصوت ───
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _isTyping = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _controller.text += emoji.emoji;
  }

  void _onBackspacePressed() {
    _controller
      ..text = _controller.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() => _showEmoji = !_showEmoji);
  }

  // ═══════════════════════════════════════════════════════
  // ─── تسجيل الصوت الحقيقي ───
  // ═══════════════════════════════════════════════════════
  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _recordPath = path;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى السماح بصلاحية المايكروفون')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في بدء التسجيل: $e')),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path != null && mounted) {
        final duration = _formatDuration(_recordDuration);
        context.read<ChatProvider>().sendMessage(
          widget.conversationId,
          '🎤 رسالة صوتية ($duration)',
          type: 'audio',
          filePath: path,
        );
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _recorder.stop();
      // حذف الملف المسجل
      if (_recordPath != null) {
        final file = File(_recordPath!);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
      _recordPath = null;
    });
  }

  String _formatDuration(int totalSeconds) {
    final min = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  // ═══════════════════════════════════════════════════════
  // ─── 1. اختيار صورة (كاميرا / معرض) مع معاينة ───
  // ═══════════════════════════════════════════════════════
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.photo, color: Color(0xFF075E54)),
            SizedBox(width: 8),
            Text('معاينة الصورة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(image.path, height: 250, fit: BoxFit.contain)
                  : Image.file(File(image.path), height: 250, fit: BoxFit.contain),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ChatProvider>().sendMessage(
                widget.conversationId, '', type: 'image', filePath: image.path,
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            label: const Text('إرسال', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
          ),
        ],
      ),
    );
  }

  // ─── 2. اختيار مستند ───
  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
    );
    if (result == null || !mounted) return;
    
    final file = result.files.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('إرسال مستند'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, size: 50, color: Colors.deepPurple),
              const SizedBox(height: 8),
              Text(
                file.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ChatProvider>().sendMessage(
                widget.conversationId, file.name, type: 'document', filePath: file.path,
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            label: const Text('إرسال', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  // ─── 3. اختيار ملف صوتي من المعرض ───
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || !mounted) return;
    
    final file = result.files.first;
    context.read<ChatProvider>().sendMessage(
      widget.conversationId, '🎵 ${file.name}', type: 'audio', filePath: file.path,
    );
  }

  // ─── 4. مشاركة الموقع ───
  Future<void> _showLocationPicker() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) Navigator.pop(context);
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading

      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      context.read<ChatProvider>().sendMessage(
        widget.conversationId,
        '📍 الموقع الحالي:\n$mapsUrl',
        type: 'text',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الموقع ✅'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في جلب الموقع: $e')));
      }
    }
  }

  // ─── 5. مشاركة جهة اتصال ───
  Future<void> _showContactPicker() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تفعيل صلاحية جهات الاتصال')));
        await openAppSettings();
      }
      return;
    }

    if (!mounted) return;
    
    try {
      final String? contactId = await FlutterContacts.native.showPicker();
      if (contactId == null || !mounted) return;

      final contact = await FlutterContacts.get(contactId, properties: ContactProperties.all);
      if (contact == null || !mounted) return;

      final displayName = contact.displayName ?? 'بدون اسم';
      final phone = contact.phones.isNotEmpty ? contact.phones.first.number : null;

      if (phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن إرسال جهة اتصال بدون رقم')));
        return;
      }

      context.read<ChatProvider>().sendMessage(
        widget.conversationId,
        '👤 جهة اتصال:\n$displayName\n📞 $phone',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // ─── قائمة المرفقات ───
  // ═══════════════════════════════════════════════════════
  void _showAttachmentMenu() {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.description, 'label': 'مستند', 'color': Colors.deepPurple, 'onTap': _pickDocument},
      {'icon': Icons.camera_alt, 'label': 'كاميرا', 'color': Colors.pink, 'onTap': () => _pickImage(ImageSource.camera)},
      {'icon': Icons.photo, 'label': 'المعرض', 'color': Colors.purple, 'onTap': () => _pickImage(ImageSource.gallery)},
      {'icon': Icons.headphones, 'label': 'صوت', 'color': Colors.orange, 'onTap': _pickAudioFile},
      {'icon': Icons.location_on, 'label': 'الموقع', 'color': Colors.green, 'onTap': _showLocationPicker},
      {'icon': Icons.person, 'label': 'جهة اتصال', 'color': Colors.blue, 'onTap': _showContactPicker},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 16),
          itemCount: items.length,
          itemBuilder: (context, index) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  items[index]['onTap']();
                },
                borderRadius: BorderRadius.circular(30),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: items[index]['color'],
                  child: Icon(items[index]['icon'], color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(height: 8),
              Text(items[index]['label'], style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ─── BUILD ───
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // شريط الرد على رسالة
        Consumer<ChatProvider>(
          builder: (context, provider, child) {
            if (provider.replyToMessage == null) return const SizedBox.shrink();
            return _buildReplyBar(provider);
          },
        ),
        // شريط التسجيل أو الإدخال
        _isRecording ? _buildRecordingBar() : _buildInputBar(),
        _buildEmojiPicker(),
      ],
    );
  }

  // ─── شريط معاينة الرد (مثل واتساب) ───
  Widget _buildReplyBar(ChatProvider provider) {
    final reply = provider.replyToMessage!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: const Border(right: BorderSide(color: Color(0xFF075E54), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reply.userId == provider.currentUserId ? 'أنت' : 'رد على رسالة',
                  style: const TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  reply.type == MessageType.image ? '📷 صورة'
                    : reply.type == MessageType.audio ? '🎤 رسالة صوتية'
                    : reply.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => provider.clearReplyToMessage(),
          ),
        ],
      ),
    );
  }

  // ─── شريط التسجيل (مثل واتساب) ───
  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // زر حذف التسجيل
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 28),
            onPressed: _cancelRecording,
          ),
          // مؤشر التسجيل + المؤقت
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: Row(
                children: [
                  // نقطة حمراء متحركة
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.3, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: const Icon(Icons.circle, color: Colors.red, size: 12),
                    ),
                    onEnd: () {},
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_recordDuration),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  const Spacer(),
                  const Text('◀ اسحب للإلغاء', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // زر إرسال التسجيل
          GestureDetector(
            onTap: _stopAndSendRecording,
            child: const CircleAvatar(
              backgroundColor: Color(0xFF075E54),
              radius: 24,
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── شريط الإدخال (مثل واتساب) ───
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // حقل الإدخال
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.grey),
                    onPressed: _toggleEmoji,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onTap: () => setState(() => _showEmoji = false),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: _showAttachmentMenu,
                  ),
                  if (!_isTyping)
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.grey),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // زر إرسال / مايكروفون
          GestureDetector(
            onTap: _isTyping
                ? () {
                    context.read<ChatProvider>().sendMessage(widget.conversationId, _controller.text);
                    _controller.clear();
                  }
                : _startRecording,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF075E54),
              radius: 24,
              child: Icon(
                _isTyping ? Icons.send : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Offstage(
      offstage: !_showEmoji,
      child: SizedBox(
        height: 250,
        child: EmojiPicker(
          onEmojiSelected: _onEmojiSelected,
          onBackspacePressed: _onBackspacePressed,
          config: Config(
            height: 256,
            checkPlatformCompatibility: false,
            emojiTextStyle: kIsWeb
                ? const TextStyle(fontSize: 24, fontFamilyFallback: ['Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji'])
                : null,
            emojiViewConfig: EmojiViewConfig(
              columns: 7,
              emojiSizeMax: 32,
              backgroundColor: const Color(0xFFF2F2F2),
            ),
            categoryViewConfig: const CategoryViewConfig(),
            bottomActionBarConfig: const BottomActionBarConfig(),
            searchViewConfig: const SearchViewConfig(),
          ),
        ),
      ),
    );
  }
}
