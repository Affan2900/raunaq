import 'package:flutter/material.dart';

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  static const primaryColor = Color(0xFF00A2FF);

  final TextEditingController _searchController = TextEditingController();

  // ── All venue data ──────────────────────────────────────────────────────────
  // Later you can replace this list with a Firestore StreamBuilder
  final List<Map<String, dynamic>> _allVenues = [
    {
      'name': 'Sunset Garden Venue',
      'location': 'DHA Phase 6, Lahore',
      'rating': 4.8,
      'reviews': 124,
      'price': 'PKR 350,000',
      'priceValue': 350000,
      'capacity': '200-500 guests',
      'emoji': '🌅',
    },
    {
      'name': 'Royal Crown Banquet',
      'location': 'Gulberg III, Lahore',
      'rating': 4.9,
      'reviews': 203,
      'price': 'PKR 500,000',
      'priceValue': 500000,
      'capacity': '300-800 guests',
      'emoji': '👑',
    },
    {
      'name': 'Pearl Continental Hall',
      'location': 'Mall Road, Lahore',
      'rating': 4.7,
      'reviews': 312,
      'price': 'PKR 600,000',
      'priceValue': 600000,
      'capacity': '250-600 guests',
      'emoji': '🏨',
    },
    {
      'name': 'Jasmine Lawn & Marquee',
      'location': 'Bahria Town, Lahore',
      'rating': 4.5,
      'reviews': 89,
      'price': 'PKR 250,000',
      'priceValue': 250000,
      'capacity': '150-400 guests',
      'emoji': '🌿',
    },
    {
      'name': 'The Grand Mughal',
      'location': 'Johar Town, Lahore',
      'rating': 4.6,
      'reviews': 156,
      'price': 'PKR 450,000',
      'priceValue': 450000,
      'capacity': '200-700 guests',
      'emoji': '🕌',
    },
    {
      'name': 'Rosewood Farm House',
      'location': 'Bedian Road, Lahore',
      'rating': 4.4,
      'reviews': 67,
      'price': 'PKR 180,000',
      'priceValue': 180000,
      'capacity': '100-300 guests',
      'emoji': '🌹',
    },
  ];

  // ── Filter state ────────────────────────────────────────────────────────────
  String _searchQuery = '';
  String _sortBy = 'rating';   // 'rating' | 'price_low' | 'price_high'
  double _minRating = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Computed filtered + sorted list ────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredVenues {
    var result = _allVenues.where((venue) {
      final name = (venue['name'] as String).toLowerCase();
      final location = (venue['location'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          location.contains(query);
      final matchesRating = (venue['rating'] as double) >= _minRating;

      return matchesSearch && matchesRating;
    }).toList();

    // Apply sort
    switch (_sortBy) {
      case 'price_low':
        result.sort((a, b) =>
            (a['priceValue'] as int).compareTo(b['priceValue'] as int));
        break;
      case 'price_high':
        result.sort((a, b) =>
            (b['priceValue'] as int).compareTo(a['priceValue'] as int));
        break;
      default: // 'rating'
        result.sort((a, b) =>
            (b['rating'] as double).compareTo(a['rating'] as double));
    }

    return result;
  }

  // ── Filter bottom sheet ─────────────────────────────────────────────────────
  void _showFilterSheet() {
    // Local copies so user can cancel without applying
    double tempRating = _minRating;
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters & Sort',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Sort options
                  const Text(
                    'Sort by',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _sortChip(
                        label: 'Top Rated',
                        value: 'rating',
                        current: tempSort,
                        onTap: (v) =>
                            setSheetState(() => tempSort = v),
                      ),
                      _sortChip(
                        label: 'Price: Low to High',
                        value: 'price_low',
                        current: tempSort,
                        onTap: (v) =>
                            setSheetState(() => tempSort = v),
                      ),
                      _sortChip(
                        label: 'Price: High to Low',
                        value: 'price_high',
                        current: tempSort,
                        onTap: (v) =>
                            setSheetState(() => tempSort = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Minimum rating slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Minimum rating',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        tempRating == 0
                            ? 'Any'
                            : '${tempRating.toStringAsFixed(1)}+',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: primaryColor,
                    onChanged: (v) =>
                        setSheetState(() => tempRating = v),
                  ),
                  const SizedBox(height: 12),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filter to actual state
                        setState(() {
                          _sortBy = tempSort;
                          _minRating = tempRating;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortChip({
    required String label,
    required String value,
    required String current,
    required ValueChanged<String> onTap,
  }) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final venues = _filteredVenues;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.black, size: 20),
        ),
        title: const Text(
          'Venues',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                // Every keystroke updates _searchQuery and rebuilds the list
                onChanged: (value) =>
                    setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search venues by name or location...',
                  hintStyle:
                      TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Results count + filter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${venues.length} venue${venues.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Row(
                    children: [
                      const Icon(Icons.tune,
                          color: Colors.grey, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Filters',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Venue list or empty state
          Expanded(
            child: venues.isEmpty
                ? const Center(
                    child: Text(
                      'No venues match your search.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: venues.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, index) {
                        final venue = venues[index];
                        return _buildVenueCard(
                          name: venue['name'] as String,
                          location: venue['location'] as String,
                          rating: venue['rating'] as double,
                          reviews: venue['reviews'] as int,
                          price: venue['price'] as String,
                          capacity: venue['capacity'] as String,
                          emoji: venue['emoji'] as String,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard({
    required String name,
    required String location,
    required double rating,
    required int reviews,
    required String price,
    required String capacity,
    required String emoji,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child:
                  Text(emoji, style: const TextStyle(fontSize: 48)),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          '$rating',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' ($reviews)',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Capacity
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 15, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      capacity,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Price + button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
