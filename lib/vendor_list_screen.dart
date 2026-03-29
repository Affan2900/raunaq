import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raunaq/vendor_detail_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key, required this.category});
  final String category; // 'all', 'venue', 'catering', etc.

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  static const primaryColor = Color(0xFF00A2FF);

  final _searchController = TextEditingController();
  String _query = '';
  String _sortBy = 'rating';
  double _minRating = 0;

  // Category display names
  static const Map<String, String> _categoryLabels = {
    'all': 'All Vendors',
    'venue': 'Venues',
    'catering': 'Catering',
    'photography': 'Photography',
    'decoration': 'Decoration',
    'music': 'Music',
    'planning': 'Planning',
  };

  static const Map<String, String> _categoryEmojis = {
    'all': '🏪', 'venue': '🏛️', 'catering': '🍽️',
    'photography': '📸', 'decoration': '🎨', 'music': '🎵', 'planning': '📋',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> get _baseQuery {
    final col = FirebaseFirestore.instance.collection('vendors');
    if (widget.category == 'all') {
      return col.orderBy('rating', descending: true);
    }
    return col.where('category', isEqualTo: widget.category).orderBy('rating', descending: true);
  }

  List<QueryDocumentSnapshot> _applyLocalFilters(List<QueryDocumentSnapshot> docs) {
    var result = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      final location = (data['location'] as String? ?? '').toLowerCase();
      final rating = (data['rating'] as num? ?? 0).toDouble();
      final q = _query.toLowerCase();
      return (q.isEmpty || name.contains(q) || location.contains(q)) && rating >= _minRating;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        result.sort((a, b) {
          final av = (a.data() as Map)['priceValue'] as int? ?? 0;
          final bv = (b.data() as Map)['priceValue'] as int? ?? 0;
          return av.compareTo(bv);
        });
      case 'price_high':
        result.sort((a, b) {
          final av = (a.data() as Map)['priceValue'] as int? ?? 0;
          final bv = (b.data() as Map)['priceValue'] as int? ?? 0;
          return bv.compareTo(av);
        });
    }
    return result;
  }

  void _showFilterSheet() {
    double tempRating = _minRating;
    String tempSort = _sortBy;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters & Sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Sort by', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                _chip('Top Rated', 'rating', tempSort, (v) => setS(() => tempSort = v)),
                _chip('Price: Low → High', 'price_low', tempSort, (v) => setS(() => tempSort = v)),
                _chip('Price: High → Low', 'price_high', tempSort, (v) => setS(() => tempSort = v)),
              ]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Min rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(tempRating == 0 ? 'Any' : '${tempRating.toStringAsFixed(1)}+'),
              ]),
              Slider(value: tempRating, min: 0, max: 5, divisions: 10, activeColor: primaryColor,
                  onChanged: (v) => setS(() => tempRating = v)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() { _sortBy = tempSort; _minRating = tempRating; });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, String current, ValueChanged<String> onTap) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: sel ? primaryColor : Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(color: sel ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _categoryLabels[widget.category] ?? 'Vendors';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20)),
        title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search $title...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Firestore stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _baseQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_categoryEmojis[widget.category] ?? '🏪', style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text('No vendors yet in this category.', style: TextStyle(color: Colors.grey)),
                    ],
                  ));
                }

                final vendors = _applyLocalFilters(snapshot.data!.docs);

                return Column(
                  children: [
                    // Results count + filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${vendors.length} found', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: Row(children: [
                              const Icon(Icons.tune, color: Colors.grey, size: 18),
                              const SizedBox(width: 4),
                              Text('Filters', style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: vendors.isEmpty
                          ? const Center(child: Text('No results match your search.', style: TextStyle(color: Colors.grey)))
                          : ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: vendors.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (_, i) {
                                  final doc = vendors[i];
                                  final data = doc.data() as Map<String, dynamic>;
                                  return _VendorCard(vendorId: doc.id, data: data);
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendorId, required this.data});
  final String vendorId;
  final Map<String, dynamic> data;
  static const primaryColor = Color(0xFF00A2FF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailScreen(vendorId: vendorId, data: data))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140, width: double.infinity,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Center(child: Text(data['emoji'] ?? '🏪', style: const TextStyle(fontSize: 48))),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text('${data['rating'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(' (${data['reviews'] ?? 0})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 15, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(data['location'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  if (data['capacity'] != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.people_outline, size: 15, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(data['capacity'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['price'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                        child: const Text('View Details', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
