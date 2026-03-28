import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MessagesScreen extends StatefulWidget {
  /// [chatId]   — unique key used in the Realtime Database path /chats/{chatId}
  ///              Build it with two sorted UIDs: "uid1_uid2"
  /// [peerName] — displayed in the AppBar (e.g. vendor name)
  const MessagesScreen({
    super.key,
    required this.chatId,
    required this.peerName,
  });

  final String chatId;
  final String peerName;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const primaryColor = Color(0xFF00A2FF);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  // Reference to this chat's messages node in Firebase Realtime Database
  // Path: /chats/{chatId}/messages
  late final DatabaseReference _messagesRef;

  // The UID of the currently logged-in user
  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance
        .ref('chats/${widget.chatId}/messages');
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Send a message to Firebase ──────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Clear input immediately so it feels fast
    _controller.clear();

    // push() creates a new unique child node under /messages
    // ServerValue.timestamp is replaced by Firebase with the real server time
    await _messagesRef.push().set({
      'senderId': _myUid,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });

    // Scroll to the latest message after it appears
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

  // ── Format a Firebase server timestamp into "3:45 PM" ──────────────────────
  String _formatTime(int timestampMs) {
    if (timestampMs == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
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
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.black, size: 20),
        ),
        title: Text(
          widget.peerName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Message list — streams live from Firebase ──
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              // onValue fires every time any message is added/changed
              stream: _messagesRef.orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                // Show spinner while waiting for first data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // No messages yet
                final rawValue = snapshot.data?.snapshot.value;
                if (rawValue == null) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                // Firebase returns a Map<dynamic, dynamic>; convert it
                final rawMap = Map<String, dynamic>.from(rawValue as Map);

                // Convert map values to a list and sort by timestamp
                final messages = rawMap.values
                    .map((v) => Map<String, dynamic>.from(v as Map))
                    .toList()
                  ..sort((a, b) =>
                      (a['timestamp'] as int? ?? 0)
                          .compareTo(b['timestamp'] as int? ?? 0));

                // Auto-scroll to bottom when new messages arrive
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg['senderId'] == _myUid;
                    final time =
                        _formatTime(msg['timestamp'] as int? ?? 0);
                    return _buildMessageBubble(
                      text: msg['text'] as String? ?? '',
                      time: time,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // ── Text input + send button ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Text field
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
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

  // ── Single message bubble ───────────────────────────────────────────────────
  Widget _buildMessageBubble({
    required String text,
    required String time,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // The bubble itself
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              // Blue for my messages, light grey for theirs
              color: isMe ? primaryColor : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Timestamp
          Text(
            time,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
