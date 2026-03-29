import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.chatId, required this.peerName});
  final String chatId;
  final String peerName;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const primaryColor = Color(0xFF00A2FF);
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final DatabaseReference _messagesRef;
  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance.ref('chats/${widget.chatId}/messages');
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // Write to Realtime Database (for fast real-time delivery)
    await _messagesRef.push().set({
      'senderId': _myUid,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });

    // Update Firestore conversation metadata (for conversations list preview)
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.chatId)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(int ms) {
    if (ms == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: Text(widget.peerName,
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _messagesRef.orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final raw = snapshot.data?.snapshot.value;
                if (raw == null) {
                  return const Center(
                    child: Text('No messages yet.\nSay hello! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15)),
                  );
                }
                final map = Map<String, dynamic>.from(raw as Map);
                final messages = map.values
                    .map((v) => Map<String, dynamic>.from(v as Map))
                    .toList()
                  ..sort((a, b) => (a['timestamp'] as int? ?? 0).compareTo(b['timestamp'] as int? ?? 0));
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg['senderId'] == _myUid;
                    return _Bubble(
                        text: msg['text'] as String? ?? '',
                        time: _formatTime(msg['timestamp'] as int? ?? 0),
                        isMe: isMe);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.time, required this.isMe});
  final String text, time;
  final bool isMe;
  static const primaryColor = Color(0xFF00A2FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? primaryColor : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14, height: 1.4)),
          ),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
