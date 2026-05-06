import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditVendorScreen extends StatefulWidget {
  const AddEditVendorScreen({super.key, this.vendorId, this.existingData});
  final String? vendorId;
  final Map<String, dynamic>? existingData;

  @override
  State<AddEditVendorScreen> createState() => _AddEditVendorScreenState();
}

class _AddEditVendorScreenState extends State<AddEditVendorScreen> {
  static const primaryColor = Color(0xFF00A2FF);

  bool get _isEditing => widget.vendorId != null;

  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _priceValueCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();

  String _category = 'venue';
  String _emoji = '🏛️';
  bool _isLoading = false;

  static const List<Map<String, String>> _categories = [
    {'value': 'venue', 'label': 'Venue', 'emoji': '🏛️'},
    {'value': 'catering', 'label': 'Catering', 'emoji': '🍽️'},
    {'value': 'photography', 'label': 'Photography', 'emoji': '📸'},
    {'value': 'decoration', 'label': 'Decoration', 'emoji': '🎨'},
    {'value': 'music', 'label': 'Music', 'emoji': '🎵'},
    {'value': 'planning', 'label': 'Planning', 'emoji': '📋'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.existingData != null) {
      final d = widget.existingData!;
      _nameCtrl.text = d['name'] ?? '';
      _locationCtrl.text = d['location'] ?? '';
      _priceCtrl.text = d['price'] ?? '';
      _priceValueCtrl.text = '${d['priceValue'] ?? ''}';
      _descriptionCtrl.text = d['description'] ?? '';
      _capacityCtrl.text = d['capacity'] ?? '';
      _specialtyCtrl.text = d['specialty'] ?? '';
      _category = d['category'] ?? 'venue';
      _emoji = d['emoji'] ?? '🏛️';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _priceValueCtrl.dispose();
    _descriptionCtrl.dispose();
    _capacityCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name, location and price are required.')));
      return;
    }

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final data = {
      'name': _nameCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'price': _priceCtrl.text.trim(),
      'priceValue': int.tryParse(_priceValueCtrl.text.trim()) ?? 0,
      'description': _descriptionCtrl.text.trim(),
      'capacity': _capacityCtrl.text.trim(),
      'specialty': _specialtyCtrl.text.trim(),
      'category': _category,
      'emoji': _emoji,
      'ownerUid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).update(data);
      } else {
        // New listing — add default rating and reviews
        await FirebaseFirestore.instance.collection('vendors').add({
          ...data,
          'rating': 0.0,
          'reviews': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving listing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            icon: const Icon(Icons.close, color: Colors.black)),
        title: Text(_isEditing ? 'Edit Listing' : 'Add Listing',
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category picker
            _sectionLabel('Category'),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((cat) {
                  final selected = _category == cat['value'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _category = cat['value']!;
                      _emoji = cat['emoji']!;
                    }),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFE5F5FF) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? primaryColor : Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['emoji']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(cat['label']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? primaryColor : Colors.black54)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Business Name *'),
            _field(_nameCtrl, 'e.g. Sunset Garden Venue'),
            const SizedBox(height: 16),

            _sectionLabel('Location *'),
            _field(_locationCtrl, 'e.g. DHA Phase 6, Lahore'),
            const SizedBox(height: 16),

            _sectionLabel('Price Display *'),
            _field(_priceCtrl, 'e.g. PKR 350,000 or PKR 1,200/head'),
            const SizedBox(height: 16),

            _sectionLabel('Price Value (number only, for sorting)'),
            _field(_priceValueCtrl, 'e.g. 350000', type: TextInputType.number),
            const SizedBox(height: 16),

            _sectionLabel('Description'),
            _field(_descriptionCtrl, 'Describe your services...', lines: 4),
            const SizedBox(height: 16),

            _sectionLabel('Capacity (optional)'),
            _field(_capacityCtrl, 'e.g. 200-500 guests'),
            const SizedBox(height: 16),

            _sectionLabel('Specialty (optional)'),
            _field(_specialtyCtrl, 'e.g. Mughlai, BBQ, Live Stations'),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(_isEditing ? 'Update Listing' : 'Publish Listing',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      );

  Widget _field(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text, int lines = 1}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );
}
