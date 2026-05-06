import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raunaq/messages_screen.dart';

class VendorDetailScreen extends StatelessWidget {
  const VendorDetailScreen({super.key, required this.vendorId, required this.data});

  final String vendorId;
  final Map<String, dynamic> data;

  static const primaryColor = Color(0xFF00A2FF);

  String _buildChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _sendInquiry(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user is a vendor — vendors can't send inquiries to themselves
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = userDoc.data()?['role'] ?? 'client';
    if (role == 'vendor') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor accounts cannot send inquiries.')));
      }
      return;
    }

    final vendorOwnerUid = data['ownerUid'] as String?;
    if (vendorOwnerUid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This vendor has not set up their account yet.')));
      }
      return;
    }

    final chatId = _buildChatId(user.uid, vendorOwnerUid);

    // Create/update conversation metadata in Firestore so it shows in conversations list
    await FirebaseFirestore.instance.collection('conversations').doc(chatId).set({
      'participants': [user.uid, vendorOwnerUid],
      'clientUid': user.uid,
      'clientName': user.displayName ?? 'Client',
      'vendorUid': vendorOwnerUid,
      'vendorName': data['name'] ?? 'Vendor',
      'vendorEmoji': data['emoji'] ?? '🏪',
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(
          chatId: chatId,
          peerName: data['name'] ?? 'Vendor',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? '';
    final location = data['location'] ?? '';
    final rating = data['rating'] ?? 0;
    final reviews = data['reviews'] ?? 0;
    final price = data['price'] ?? '';
    final emoji = data['emoji'] ?? '🏪';
    final description = data['description'] ?? 'No description available.';
    final capacity = data['capacity'] as String?;
    final specialty = data['specialty'] as String?;
    final category = data['category'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: primaryColor.withValues(alpha: 0.2),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 80))),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('$rating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(' ($reviews)', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),
                  const SizedBox(height: 6),

                  // Category
                  Row(children: [
                    const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(category[0].toUpperCase() + category.substring(1),
                        style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),

                  if (capacity != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(capacity, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ]),
                  ],

                  if (specialty != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(specialty, style: const TextStyle(color: Colors.grey, fontSize: 14))),
                    ]),
                  ],

                  const SizedBox(height: 20),

                  // Price box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5F5FF), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Starting from', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text(price, style: const TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About section
                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(description, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.6)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom CTA
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _sendInquiry(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Send Inquiry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
