import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:gal/gal.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/models/message_model.dart';
import '../../../../app_config.dart';
import 'event_card.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderName;
  final Color? senderColor;
  final VoidCallback? onDelete;
  final bool isAdmin;
  final Function(String)? onRsvp;
  final Function(String)? onReact;
  final Function(MessageModel)? onSwipe;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
    this.senderColor,
    this.onDelete,
    this.isAdmin = false,
    this.onRsvp,
    this.onReact,
    this.onSwipe,
    this.onRetry,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _initAudioPlayer(String url) {
    _audioPlayer ??= AudioPlayer();
    _audioPlayer!.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer!.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer!.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });
  }

  Future<void> _togglePlay(String url) async {
    _initAudioPlayer(url);
    if (_isPlaying) {
      await _audioPlayer!.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_isLocalPath(url)) {
        await _audioPlayer!.play(DeviceFileSource(url));
      } else {
        await _audioPlayer!.play(UrlSource(url));
      }
      setState(() => _isPlaying = true);
    }
  }

  String _formatAudioDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ملفات لارافل المخزنة في public storage
  String _formatUrl(String path) {
    return AppConfig.storageUrl(path);
  }

  // التحقق هل المسار محلي (ملف على الجهاز) أم مسار سيرفر
  bool _isLocalPath(String? path) {
    if (path == null || path.isEmpty) return false;
    // مسارات الجهاز المطلقة: تبدأ بـ / على أندرويد أو تحتوي :\ على ويندوز
    // مسارات السيرفر النسبية مثل messages/media/xyz.jpg لا تطابق هذا
    return path.startsWith('/') || path.contains(':\\');
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final senderName = widget.senderName;
    final senderColor = widget.senderColor;
    final onSwipe = widget.onSwipe;
    final onRsvp = widget.onRsvp;
    final isAdmin = widget.isAdmin;

    if (message.type == MessageType.event && message.event != null) {
      return EventCard(
        event: message.event!,
        isMe: isMe,
        createdAt: message.createdAt,
        onRsvp: onRsvp,
      );
    }

    return Dismissible(
      key: Key('message-${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        if (onSwipe != null) onSwipe(message);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: Colors.grey),
      ),
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 12),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 1, offset: const Offset(0, 1)),
              ],
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.replyTo != null) _buildReplyPreview(context),
                if (senderName != null && !isMe)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(
                      senderName,
                      style: TextStyle(color: senderColor ?? const Color(0xFF075E54), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                _buildMessageContent(context),
                _buildFooter(isMe, message),
                if (message.reactions.isNotEmpty) _buildReactionsDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final message = widget.message;
    switch (message.type) {
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.document:
        return _buildDocumentContent(context);
      case MessageType.video:
        return _buildVideoPlaceholder();
      case MessageType.audio:
        return _buildAudioPlaceholder();
      default:
        final bool isLocation = message.content.startsWith('📍 الموقع الحالي:');
        final bool isContact = message.content.startsWith('👤 جهة اتصال:');
        final bool isOldDocument = message.content.startsWith('📄 مستند:');
        
        if (isOldDocument) {
          return _buildDocumentContent(context);
        }

        if (isLocation) {
          return _buildLocationCard(context);
        }

        if (isContact) {
          return _buildContactCard(context);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(message.content, style: const TextStyle(color: Colors.black87, fontSize: 15)),
        );
    }
  }

  Widget _buildLocationCard(BuildContext context) {
    final message = widget.message;
    final urlRegex = RegExp(r'(https?://[^\s]+)');
    final match = urlRegex.firstMatch(message.content);
    final url = match?.group(0);

    return GestureDetector(
      onTap: () async {
        if (url != null) {
          try {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Could not launch location url: $e');
          }
        }
      },
      child: Container(
        width: 250,
        height: 150,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFA5D6A7), // لون مقارب لخلفية الخريطة
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // أيقونة الموقع الدائرية الشفافة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 40),
            ),
            // رابط جوجل ماب أسفل البطاقة (اختياري)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                child: const Text('الموقع المباشر', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final message = widget.message;
    final lines = message.content.split('\n');
    final name = lines.length > 1 ? lines[1] : 'جهة اتصال';
    final phone = lines.length > 2 ? lines[2].replaceAll('📞', '').trim() : '';

    return Container(
      width: 250,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: widget.isMe ? const Color(0xFFD9F4C7) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blueGrey,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '👤', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      const Text('جهة اتصال', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          InkWell(
            onTap: () async {
              if (phone.isNotEmpty) {
                final url = Uri.parse('tel:$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text('مراسلة', style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final message = widget.message;
    final bool isLocal = _isLocalPath(message.fileUrl);
    final url = isLocal ? message.fileUrl! : _formatUrl(message.fileUrl ?? '');
    
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GestureDetector(
        onTap: () {
          if (url.isEmpty) return;
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imageUrl: url, isLocal: isLocal),
          ));
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Hero(
                tag: url,
                child: isLocal
                  ? Image.file(File(url), height: 200, width: 200, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(height: 200, width: 200, color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      placeholder: (context, url) => Container(height: 200, width: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (context, url, error) => Container(height: 200, width: 200, color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)),
                      fit: BoxFit.cover,
                    ),
              ),
            ),
            if (message.uploadProgress != null && message.uploadProgress! < 1.0)
              Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: Center(
                  child: CircularProgressIndicator(
                    value: message.uploadProgress,
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContent(BuildContext context) {
    final message = widget.message;
    final bool isLocal = _isLocalPath(message.fileUrl);
    final url = isLocal ? message.fileUrl! : _formatUrl(message.fileUrl ?? '');
    final fileName = message.content.isNotEmpty ? message.content : 'مستند';
    
    return GestureDetector(
      onTap: () async {
        if (isLocal) {
          OpenFilex.open(url);
          return;
        }
        if (url.isEmpty || !url.startsWith('http')) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، هذا الملف قديم وغير متاح للتحميل')));
          }
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري التحميل وفتح الملف...'), duration: Duration(seconds: 1)));
        await _downloadAndOpenFile(context, url, fileName);
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                  if (message.uploadProgress != null && message.uploadProgress! < 1.0)
                    const SizedBox(
                      width: 30, height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.uploadProgress != null && message.uploadProgress! < 1.0 
                      ? 'جاري الرفع... ${ (message.uploadProgress! * 100).toInt()}%' 
                      : 'ملف مستند • انقر للفتح',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isLocal) const Icon(Icons.download_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
      child: const Center(child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white70)),
    );
  }

  Widget _buildAudioPlaceholder() {
    final message = widget.message;
    final bool isLocal = _isLocalPath(message.fileUrl);
    final url = isLocal ? message.fileUrl! : _formatUrl(message.fileUrl ?? '');
    final bool isUploading = message.uploadProgress != null && message.uploadProgress! < 1.0;

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // زر play/pause
          GestureDetector(
            onTap: isUploading ? null : () => _togglePlay(url),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF075E54),
              child: isUploading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white, value: message.uploadProgress))
                : Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: const Color(0xFF075E54),
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: const Color(0xFF075E54),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0,
                    onChanged: (v) {
                      if (_duration.inMilliseconds > 0) {
                        _audioPlayer?.seek(Duration(milliseconds: (v * _duration.inMilliseconds).toInt()));
                      }
                    },
                  ),
                ),
                if (isUploading)
                  Text('جاري الرفع... ${(message.uploadProgress! * 100).toInt()}%', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            _isPlaying ? _formatAudioDuration(_position) : _formatAudioDuration(_duration),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMe, MessageModel message) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 8, bottom: 2, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            DateFormat('h:mm a').format(message.createdAt.toUtc().add(const Duration(hours: 3))),
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            _buildStatusIcon(message),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageModel message) {
    // رسالة فاشلة
    if (message.status == 'failed') {
      return GestureDetector(
        onTap: widget.onRetry,
        child: const Icon(Icons.error, size: 16, color: Colors.red),
      );
    }

    if (message.uploadProgress != null && message.uploadProgress! < 1.0) {
      return const SizedBox(
        width: 10, height: 10,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blue),
      );
    }

    IconData icon = Icons.check;
    Color color = Colors.grey;

    if (message.status == 'seen' || message.status == 'read') {
      icon = Icons.done_all;
      color = Colors.blue;
    } else if (message.status == 'delivered') {
      icon = Icons.done_all;
    } else if (message.status == 'sending') {
      icon = Icons.access_time;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildReplyPreview(BuildContext context) {
    final message = widget.message;
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(right: BorderSide(color: Color(0xFF075E54), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo!.userId == message.userId ? 'أنت' : 'رسالة',
            style: const TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            message.replyTo!.content.isEmpty ? '📷 صورة' : message.replyTo!.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsDisplay() {
    final message = widget.message;
    final Map<String, int> counts = {};
    for (var r in message.reactions) {
      counts[r.reaction] = (counts[r.reaction] ?? 0) + 1;
    }
    return Container(
      margin: const EdgeInsets.only(top: 2, left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...counts.keys.take(3).map((emoji) => Text(emoji, style: const TextStyle(fontSize: 10))),
          if (message.reactions.length > 1)
            Text(' ${message.reactions.length}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final message = widget.message;
    final onReact = widget.onReact;
    final onSwipe = widget.onSwipe;
    final onDelete = widget.onDelete;
    final isMe = widget.isMe;
    final isAdmin = widget.isAdmin;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (onReact != null) onReact(emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('رد'),
              onTap: () {
                Navigator.pop(context);
                if (onSwipe != null) onSwipe(message);
              },
            ),
            if (isMe || isAdmin)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف لدي الجميع', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  if (onDelete != null) onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;

  const FullScreenImageViewer({super.key, required this.imageUrl, this.isLocal = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!isLocal)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () async {
                if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري التحميل...'), duration: Duration(seconds: 1)));
                final fileName = imageUrl.split('/').last.split('?').first;
                await _downloadAndOpenFile(context, imageUrl, fileName);
              },
            ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            child: isLocal
              ? Image.file(File(imageUrl), fit: BoxFit.contain)
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                ),
          ),
        ),
      ),
    );
  }
}

Future<void> _downloadAndOpenFile(BuildContext context, String url, String fileName) async {
  try {
    final ext = fileName.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    if (isImage) {
      // Use Gal for images to save directly to Gallery
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName';
      await Dio().download(url, filePath);
      
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }
      
      if (hasAccess) {
        await Gal.putImage(filePath);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الصورة في معرض الصور بنجاح')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم منح صلاحية الوصول للمعرض')));
        }
      }
      return;
    }

    // For documents, use flutter_file_downloader to save to public Downloads folder
    FileDownloader.downloadFile(
      url: url,
      name: fileName,
      onDownloadCompleted: (String path) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الملف في التنزيلات بنجاح')));
        }
        OpenFilex.open(path);
      },
      onDownloadError: (String error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التحميل: $error')));
        }
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء التحميل: $e')));
    }
  }
}
