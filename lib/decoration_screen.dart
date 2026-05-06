import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:raunaq/state/admin_mode_notifier.dart';

class DecorationScreen extends StatefulWidget {
  const DecorationScreen({super.key});

  @override
  State<DecorationScreen> createState() => _DecorationScreenState();
}

class _DecorationScreenState extends State<DecorationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  void _showAddDecorationDialog(BuildContext context) {
    if (_currentUserEmail == null) return;

    final nameController = TextEditingController();
    final themeController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Decorator'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              TextField(
                controller: themeController,
                decoration: const InputDecoration(
                  labelText: 'Style (e.g. Floral, Minimal)',
                ),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Starting Price (e.g. PKR 150k)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _firestore
                    .collection('categories')
                    .doc('decoration')
                    .collection('items')
                    .add({
                      'name': nameController.text,
                      'theme': themeController.text,
                      'price': priceController.text,
                      'rating': 0.0,
                      'reviews': 0,
                      'emoji': '✨',
                      'ownerEmail': _currentUserEmail,
                      'created_at': FieldValue.serverTimestamp(),
                    });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDecorationDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    if (_currentUserEmail == null) return;

    final nameController =
        TextEditingController(text: data['name']?.toString() ?? '');
    final themeController =
        TextEditingController(text: data['theme']?.toString() ?? '');
    final priceController =
        TextEditingController(text: data['price']?.toString() ?? '');

    void disposeControllers() {
      nameController.dispose();
      themeController.dispose();
      priceController.dispose();
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Decorator'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              TextField(
                controller: themeController,
                decoration: const InputDecoration(
                  labelText: 'Style (e.g. Floral, Minimal)',
                ),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Starting Price (e.g. PKR 150k)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _firestore
                    .collection('categories')
                    .doc('decoration')
                    .collection('items')
                    .doc(docId)
                    .update({
                  'name': nameController.text.trim(),
                  'theme': themeController.text.trim(),
                  'price': priceController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(disposeControllers);
  }

  void _deleteDecoration(String docId) async {
    await _firestore
        .collection('categories')
        .doc('decoration')
        .collection('items')
        .doc(docId)
        .delete();
  }

  void _showRegisterDialog(
    BuildContext context,
    String itemId,
    String itemName,
  ) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Register for $itemName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              ListTile(
                title: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : 'Time: ${selectedTime!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) setState(() => selectedTime = time);
                },
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedDate != null && selectedTime != null)
                  ? () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await _firestore.collection('registrations').add({
                          'userId': user.uid,
                          'userEmail': user.email,
                          'category': 'decoration',
                          'itemId': itemId,
                          'itemName': itemName,
                          'date': selectedDate,
                          'time': selectedTime!.format(context),
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registration successful!'),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00A2FF);
    final adminMode = context.watch<AdminModeNotifier>().isAdminView;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text(
          'Decoration & Theme',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (adminMode && _currentUserEmail != null)
            IconButton(
              onPressed: () => _showAddDecorationDialog(context),
              icon: const Icon(Icons.add_circle_outline, color: primaryColor),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search decors...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey, size: 20),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('categories')
                  .doc('decoration')
                  .collection('items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Error loading data'));
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Center(child: Text('No decorations found'));

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String ownerEmail = data['ownerEmail'] ?? '';
                    final bool isOwner =
                        _currentUserEmail != null &&
                        ownerEmail == _currentUserEmail;

                    return GestureDetector(
                      onTap: () {
                        if (isOwner && adminMode) {
                          _showEditDecorationDialog(context, doc.id, data);
                        } else if (!isOwner) {
                          _showRegisterDialog(context, doc.id, data['name']);
                        }
                      },
                      child: Stack(
                        children: [
                          _buildCard(data, primaryColor),
                          if (isOwner && adminMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () => _deleteDecoration(doc.id),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                data['emoji'] ?? '✨',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${data['rating'] ?? 0.0} (${data['reviews'] ?? 0})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['theme'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['price'] ?? '',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'View Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
