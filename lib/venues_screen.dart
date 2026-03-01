import 'package:flutter/material.dart';

class VenuesScreen extends StatelessWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00A2FF);

    // Mock venue data
    final List<Map<String, dynamic>> venues = [
      {
        'name': 'Sunset Garden Venue',
        'location': 'DHA Phase 6, Lahore',
        'rating': 4.8,
        'reviews': 124,
        'price': 'PKR 350,000',
        'capacity': '200-500 guests',
        'emoji': '🌅',
      },
      {
        'name': 'Royal Crown Banquet',
        'location': 'Gulberg III, Lahore',
        'rating': 4.9,
        'reviews': 203,
        'price': 'PKR 500,000',
        'capacity': '300-800 guests',
        'emoji': '👑',
      },
      {
        'name': 'Pearl Continental Hall',
        'location': 'Mall Road, Lahore',
        'rating': 4.7,
        'reviews': 312,
        'price': 'PKR 600,000',
        'capacity': '250-600 guests',
        'emoji': '🏨',
      },
      {
        'name': 'Jasmine Lawn & Marquee',
        'location': 'Bahria Town, Lahore',
        'rating': 4.5,
        'reviews': 89,
        'price': 'PKR 250,000',
        'capacity': '150-400 guests',
        'emoji': '🌿',
      },
      {
        'name': 'The Grand Mughal',
        'location': 'Johar Town, Lahore',
        'rating': 4.6,
        'reviews': 156,
        'price': 'PKR 450,000',
        'capacity': '200-700 guests',
        'emoji': '🕌',
      },
      {
        'name': 'Rosewood Farm House',
        'location': 'Bedian Road, Lahore',
        'rating': 4.4,
        'reviews': 67,
        'price': 'PKR 180,000',
        'capacity': '100-300 guests',
        'emoji': '🌹',
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search venues...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${venues.length} venues found',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.tune, color: Colors.grey, size: 18),
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
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Venue list
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: venues.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final venue = venues[index];
                  return _buildVenueCard(
                    name: venue['name'] as String,
                    location: venue['location'] as String,
                    rating: venue['rating'] as double,
                    reviews: venue['reviews'] as int,
                    price: venue['price'] as String,
                    capacity: venue['capacity'] as String,
                    emoji: venue['emoji'] as String,
                    primaryColor: primaryColor,
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
    required Color primaryColor,
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
              child: Text(emoji, style: const TextStyle(fontSize: 48)),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & rating row
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
                        const Icon(Icons.star, color: Colors.amber, size: 16),
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
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Capacity
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 15,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      capacity,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Price & button
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
                        horizontal: 16,
                        vertical: 8,
                      ),
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
