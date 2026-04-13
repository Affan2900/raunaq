import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raunaq/messages_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});
  static const primaryColor = Color(0xFF00A2FF);

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text('Messages',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: myUid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No conversations yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Send an inquiry to a vendor to start chatting.',
                      style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final chatId = docs[i].id;

              // Determine which name to show (the other person)
              final isClient = data['clientUid'] == myUid;
              final peerName = isClient ? (data['vendorName'] ?? 'Vendor') : (data['clientName'] ?? 'Client');
              final peerEmoji = data['vendorEmoji'] ?? '🏪';
              final lastMessage = data['lastMessage'] as String? ?? '';
              final lastTime = data['lastMessageTime'] as Timestamp?;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE5F5FF),
                  child: Text(peerEmoji, style: const TextStyle(fontSize: 24)),
                ),
                title: Text(peerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  lastMessage.isEmpty ? 'Tap to open chat' : lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: lastTime != null
                    ? Text(
                        _formatTime(lastTime.toDate()),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessagesScreen(chatId: chatId, peerName: peerName),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$hour:$min $period';
    }
    return '${dt.day}/${dt.month}';
  }
}
