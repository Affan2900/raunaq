import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00A2FF);

    // Mock conversation data
    final List<Map<String, dynamic>> messages = [
      {
        'text': 'Hi! I wanted to ask about catering services for my wedding.',
        'isMe': false,
        'time': '10:30 AM',
      },
      {
        'text': 'Hello! I would be happy to help. When is your event?',
        'isMe': true,
        'time': '10:32 AM',
      },
      {
        'text':
            "It's scheduled for June 15th. We're expecting around 150 guests.",
        'isMe': false,
        'time': '10:35 AM',
      },
      {
        'text':
            'Perfect! We can definitely accommodate that. Would you prefer Italian or traditional cuisine?',
        'isMe': true,
        'time': '10:37 AM',
      },
      {
        'text': 'I think Italian would be great! What packages do you offer?',
        'isMe': false,
        'time': '10:40 AM',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final bool isMe = message['isMe'] as bool;
                return _buildMessageBubble(
                  text: message['text'] as String,
                  time: message['time'] as String,
                  isMe: isMe,
                  primaryColor: primaryColor,
                );
              },
            ),
          ),

          // Divider
          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // Message input area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Text field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        // No-op for now (mock screen)
                      },
                      icon: const Icon(
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

  Widget _buildMessageBubble({
    required String text,
    required String time,
    required bool isMe,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Bubble
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
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
