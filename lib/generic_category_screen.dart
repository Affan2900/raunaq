import 'package:flutter/material.dart';

/// A reusable vendor listing screen used by every category
/// (Catering, Photography, Decoration, Music, Planning).
///
/// Pass the [category] label, an [emoji] for the header,
/// and a [vendors] list. Search is wired and live.
class GenericCategoryScreen extends StatefulWidget {
  const GenericCategoryScreen({
    super.key,
    required this.category,
    required this.emoji,
    required this.vendors,
  });

  final String category;
  final String emoji;
  final List<Map<String, dynamic>> vendors;

  @override
  State<GenericCategoryScreen> createState() =>
      _GenericCategoryScreenState();
}

class _GenericCategoryScreenState extends State<GenericCategoryScreen> {
  static const primaryColor = Color(0xFF00A2FF);

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return widget.vendors;
    final q = _query.toLowerCase();
    return widget.vendors.where((v) {
      final name = (v['name'] as String).toLowerCase();
      final location = (v['location'] as String).toLowerCase();
      return name.contains(q) || location.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vendors = _filtered;

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
        title: Text(
          widget.category,
          style: const TextStyle(
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
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText:
                      'Search ${widget.category.toLowerCase()}...',
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search,
                      color: Colors.grey, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${vendors.length} provider${vendors.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vendor list
          Expanded(
            child: vendors.isEmpty
                ? const Center(
                    child: Text(
                      'No results found.',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: vendors.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, i) =>
                          _VendorCard(vendor: vendors[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Individual vendor card ──────────────────────────────────────────────────

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor});

  final Map<String, dynamic> vendor;
  static const primaryColor = Color(0xFF00A2FF);

  @override
  Widget build(BuildContext context) {
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
          // Emoji placeholder image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                vendor['emoji'] as String,
                style: const TextStyle(fontSize: 44),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vendor['name'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        '${vendor['rating']}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${vendor['reviews']})',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 5),

                // Location
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    vendor['location'] as String,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ]),

                // Specialty (optional field)
                if (vendor['specialty'] != null) ...[
                  const SizedBox(height: 5),
                  Row(children: [
                    Icon(Icons.star_outline,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      vendor['specialty'] as String,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ]),
                ],

                const SizedBox(height: 10),

                // Price + button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vendor['price'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
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

// ── Category-specific screens ───────────────────────────────────────────────
// Each one just provides its own data to GenericCategoryScreen.

class CateringScreen extends StatelessWidget {
  const CateringScreen({super.key});

  @override
  Widget build(BuildContext context) => GenericCategoryScreen(
        category: 'Catering',
        emoji: '🍽️',
        vendors: const [
          {
            'name': 'Lakhnavi Dastarkhwan',
            'location': 'Gulberg, Lahore',
            'rating': 4.8,
            'reviews': 210,
            'price': 'PKR 1,200/head',
            'specialty': 'Mughlai, BBQ, Live Stations',
            'emoji': '🍛',
          },
          {
            'name': 'Saveur Catering Co.',
            'location': 'DHA Phase 5, Lahore',
            'rating': 4.7,
            'reviews': 145,
            'price': 'PKR 1,500/head',
            'specialty': 'Continental & Pakistani fusion',
            'emoji': '🍽️',
          },
          {
            'name': 'Barbeque Tonight Events',
            'location': 'MM Alam Road, Lahore',
            'rating': 4.6,
            'reviews': 98,
            'price': 'PKR 900/head',
            'specialty': 'BBQ, Grills, Buffet',
            'emoji': '🔥',
          },
          {
            'name': 'The Kitchen Bridge',
            'location': 'Johar Town, Lahore',
            'rating': 4.5,
            'reviews': 67,
            'price': 'PKR 800/head',
            'specialty': 'Desi, Chinese, Fast Food',
            'emoji': '🥘',
          },
        ],
      );
}

class PhotographyScreen extends StatelessWidget {
  const PhotographyScreen({super.key});

  @override
  Widget build(BuildContext context) => GenericCategoryScreen(
        category: 'Photography',
        emoji: '📸',
        vendors: const [
          {
            'name': 'Shutter & Bloom Studio',
            'location': 'Model Town, Lahore',
            'rating': 4.9,
            'reviews': 312,
            'price': 'PKR 85,000/event',
            'specialty': 'Wedding, Candid, Drone',
            'emoji': '📷',
          },
          {
            'name': 'Pixels by Rizwan',
            'location': 'Bahria Town, Lahore',
            'rating': 4.8,
            'reviews': 178,
            'price': 'PKR 65,000/event',
            'specialty': 'Portrait, Cinematic Video',
            'emoji': '🎥',
          },
          {
            'name': 'Golden Frame Productions',
            'location': 'DHA Phase 4, Lahore',
            'rating': 4.7,
            'reviews': 231,
            'price': 'PKR 120,000/event',
            'specialty': 'Full Production + Editing',
            'emoji': '🎞️',
          },
          {
            'name': 'Moment Catchers',
            'location': 'Faisal Town, Lahore',
            'rating': 4.5,
            'reviews': 88,
            'price': 'PKR 45,000/event',
            'specialty': 'Affordable, Quick Delivery',
            'emoji': '📸',
          },
        ],
      );
}

class DecorationScreen extends StatelessWidget {
  const DecorationScreen({super.key});

  @override
  Widget build(BuildContext context) => GenericCategoryScreen(
        category: 'Decoration',
        emoji: '🎨',
        vendors: const [
          {
            'name': 'Blooms & Drapes Events',
            'location': 'Gulberg III, Lahore',
            'rating': 4.8,
            'reviews': 195,
            'price': 'PKR 150,000+',
            'specialty': 'Floral, Fairy lights, Stages',
            'emoji': '💐',
          },
          {
            'name': 'Deco Artisans',
            'location': 'DHA Phase 6, Lahore',
            'rating': 4.7,
            'reviews': 140,
            'price': 'PKR 80,000+',
            'specialty': 'Theme decor, Backdrops',
            'emoji': '🎀',
          },
          {
            'name': 'Elegant Touch Studio',
            'location': 'Johar Town, Lahore',
            'rating': 4.6,
            'reviews': 103,
            'price': 'PKR 60,000+',
            'specialty': 'Minimalist, Boho, Royal',
            'emoji': '✨',
          },
          {
            'name': 'Grand Affair Decor',
            'location': 'Bahria Town, Lahore',
            'rating': 4.5,
            'reviews': 72,
            'price': 'PKR 50,000+',
            'specialty': 'Budget-friendly packages',
            'emoji': '🎊',
          },
        ],
      );
}

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) => GenericCategoryScreen(
        category: 'Music',
        emoji: '🎵',
        vendors: const [
          {
            'name': 'SoundWave Events',
            'location': 'MM Alam Road, Lahore',
            'rating': 4.8,
            'reviews': 167,
            'price': 'PKR 70,000/event',
            'specialty': 'DJ, Sound System, Lighting',
            'emoji': '🎧',
          },
          {
            'name': 'Classical Strings',
            'location': 'Model Town, Lahore',
            'rating': 4.9,
            'reviews': 89,
            'price': 'PKR 40,000/event',
            'specialty': 'Qawwali, Ghazal, Live Band',
            'emoji': '🎻',
          },
          {
            'name': 'BassDrop Productions',
            'location': 'DHA Phase 5, Lahore',
            'rating': 4.6,
            'reviews': 122,
            'price': 'PKR 55,000/event',
            'specialty': 'EDM, Corporate Events',
            'emoji': '🎹',
          },
          {
            'name': 'Mehfil Music Group',
            'location': 'Gulberg, Lahore',
            'rating': 4.7,
            'reviews': 98,
            'price': 'PKR 30,000/event',
            'specialty': 'Traditional, Mehndi Nights',
            'emoji': '🥁',
          },
        ],
      );
}

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) => GenericCategoryScreen(
        category: 'Planning',
        emoji: '📋',
        vendors: const [
          {
            'name': 'Elite Event Planners',
            'location': 'DHA Phase 6, Lahore',
            'rating': 4.9,
            'reviews': 245,
            'price': 'PKR 200,000/event',
            'specialty': 'Full-service weddings, Corporate',
            'emoji': '📋',
          },
          {
            'name': 'My Big Day Co.',
            'location': 'Gulberg III, Lahore',
            'rating': 4.8,
            'reviews': 180,
            'price': 'PKR 120,000/event',
            'specialty': 'Weddings, Engagements',
            'emoji': '💍',
          },
          {
            'name': 'CelebratePK',
            'location': 'Johar Town, Lahore',
            'rating': 4.6,
            'reviews': 93,
            'price': 'PKR 80,000/event',
            'specialty': 'Birthday, Kids Parties',
            'emoji': '🎂',
          },
          {
            'name': 'Corporate Events Hub',
            'location': 'Faisal Town, Lahore',
            'rating': 4.7,
            'reviews': 67,
            'price': 'PKR 150,000/event',
            'specialty': 'Conferences, Gala Dinners',
            'emoji': '🏢',
          },
        ],
      );
}
