import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raunaq/profile_page.dart';
import 'package:raunaq/conversations_screen.dart';
import 'package:raunaq/add_edit_vendor_screen.dart';
import 'package:raunaq/messages_screen.dart';
import 'package:raunaq/vendor_detail_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  static const primaryColor = Color(0xFF00A2FF);
  int _tab = 0;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _myName => FirebaseAuth.instance.currentUser?.displayName ?? 'Vendor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Vendor Dashboard',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            icon: const Icon(Icons.person_outline, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _tabBtn('My Listings', 0),
                const SizedBox(width: 12),
                _tabBtn('Inquiries', 1),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _tab == 0 ? _MyListings(ownerUid: _myUid) : _Inquiries(vendorUid: _myUid)),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditVendorScreen()),
              ),
              backgroundColor: primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationsScreen()));
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ),
    );
  }
}

// ── My Listings tab ──────────────────────────────────────────────────────────

class _MyListings extends StatelessWidget {
  const _MyListings({required this.ownerUid});
  final String ownerUid;
  static const primaryColor = Color(0xFF00A2FF);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .where('ownerUid', isEqualTo: ownerUid)
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
                const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('You have no listings yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Tap + Add Listing to create your first one.',
                    style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final doc = snapshot.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: const Color(0xFFE5F5FF), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(data['emoji'] ?? '🏪', style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(data['location'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text('${data['rating'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text(data['price'] ?? '', style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: primaryColor),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddEditVendorScreen(vendorId: doc.id, existingData: data)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, doc.id, data['name'] ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('vendors').doc(docId).delete();
    }
  }
}

// ── Inquiries tab ────────────────────────────────────────────────────────────

class _Inquiries extends StatelessWidget {
  const _Inquiries({required this.vendorUid});
  final String vendorUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('vendorUid', isEqualTo: vendorUid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No inquiries yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
          itemBuilder: (_, i) {
            final data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            final chatId = snapshot.data!.docs[i].id;
            final clientName = data['clientName'] ?? 'Client';
            final vendorName = data['vendorName'] ?? 'Your Listing';
            final lastMsg = data['lastMessage'] as String? ?? 'No messages yet';
            final ts = data['lastMessageTime'] as Timestamp?;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFF0F0F0),
                child: Text(clientName[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Re: $vendorName', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ],
              ),
              trailing: ts != null ? Text(_fmt(ts.toDate()), style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MessagesScreen(chatId: chatId, peerName: clientName)),
              ),
            );
          },
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${dt.day}/${dt.month}';
  }
}
