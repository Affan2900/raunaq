import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raunaq/profile_page.dart';
import 'package:raunaq/messages_screen.dart';
import 'package:raunaq/venues_screen.dart';
import 'package:raunaq/catering_screen.dart';
import 'package:raunaq/photography_screen.dart';
import 'package:raunaq/decoration_screen.dart';
import 'package:raunaq/music_screen.dart';
import 'package:raunaq/add_event_plan_screen.dart';
import 'package:raunaq/event_plan_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _hoveredIndex = -1;

  /// First name for greeting: [User.displayName], else email local-part, else fallback.
  String _firstNameFromUser(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }
    final email = user?.email?.trim();
    if (email != null && email.contains('@')) {
      final local = email.split('@').first;
      if (local.isNotEmpty) return local;
    }
    return 'User';
  }

  Widget _buildCurrentPlansSection(BuildContext context) {
    const primaryColor = Color(0xFF00A2FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnap) {
              final uid =
                  authSnap.data?.uid ?? FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [_buildAddPlanCard(context)],
                );
              }
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('eventPlans')
                    .snapshots(),
                builder: (context, planSnap) {
                  if (planSnap.hasError) {
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [_buildAddPlanCard(context)],
                    );
                  }
                  if (planSnap.connectionState == ConnectionState.waiting &&
                      !planSnap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }
                  final docs = planSnap.data?.docs ?? [];
                  final sorted = List<QueryDocumentSnapshot>.from(docs);
                  sorted.sort((a, b) {
                    final mapA = a.data() as Map<String, dynamic>?;
                    final mapB = b.data() as Map<String, dynamic>?;
                    final ta = mapA?['createdAt'];
                    final tb = mapB?['createdAt'];
                    if (ta is Timestamp && tb is Timestamp) {
                      return tb.compareTo(ta);
                    }
                    return 0;
                  });

                  final rowChildren = <Widget>[];
                  for (final doc in sorted) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final raw = data?['planName']?.toString().trim();
                    final title =
                        raw != null && raw.isNotEmpty ? raw : 'Event plan';
                    rowChildren.add(
                      _buildCurrentPlanCard(
                        context,
                        planId: doc.id,
                        planName: title,
                      ),
                    );
                    rowChildren.add(const SizedBox(width: 16));
                  }
                  rowChildren.add(_buildAddPlanCard(context));

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: rowChildren,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00A2FF); // Light blue color
    const backgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.person_outline, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        // Use ScrollConfiguration to hide the scrollbar
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Greeting (reads Firebase Auth display name / email)
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
                    final firstName = _firstNameFromUser(user);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $firstName! 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Plan Your Dream Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Categories Title
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Categories Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0, // Make them square
                  children: [
                    _buildCategoryItem(
                      0,
                      '🏛️',
                      'Venues',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VenuesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildCategoryItem(
                      1,
                      '🍽️',
                      'Catering',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CateringScreen(),
                          ),
                        );
                      },
                    ),
                    _buildCategoryItem(
                      2,
                      '📸',
                      'Photography',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhotographyScreen(),
                          ),
                        );
                      },
                    ),
                    _buildCategoryItem(
                      3,
                      '🎨',
                      'Decoration',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DecorationScreen(),
                          ),
                        );
                      },
                    ),
                    _buildCategoryItem(
                      4,
                      '🎵',
                      'Music',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MusicScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _buildCurrentPlansSection(context),

                const SizedBox(height: 28),

                // Recommended for You Title
                const Text(
                  'Recommended for You',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Recommended List
                SizedBox(
                  height: 220, // Height for the horizontal list
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildRecommendedCard(
                        'Sunset Garden Venue',
                        '4.8',
                        r'$$$',
                      ),
                      const SizedBox(width: 16),
                      _buildRecommendedCard(
                        'Royal Crown Hotel',
                        '4.9',
                        r'$$$$',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // Extra space at the bottom
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            // Navigate to Messages screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Vendors',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    int index,
    String emoji,
    String title, {
    VoidCallback? onTap,
  }) {
    bool isHovered = _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isHovered
                ? const Color(0xFFE5F5FF)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isHovered ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlanCard(BuildContext context) {
    const primaryColor = Color(0xFF00A2FF);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const AddEventPlanScreen(),
          ),
        );
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 44, color: primaryColor),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'New plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(
    BuildContext context, {
    required String planId,
    required String planName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => EventPlanDetailScreen(planId: planId),
          ),
        );
      },
      child: Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF89CFF0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 32)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
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

  Widget _buildRecommendedCard(String title, String rating, String price) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Soft shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF89CFF0), // Light blue placeholder
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text('📷', style: TextStyle(fontSize: 32)),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
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
