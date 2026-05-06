import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raunaq/profile_page.dart';
import 'package:raunaq/conversations_screen.dart';
import 'package:raunaq/vendor_dashboard_screen.dart';
import 'package:raunaq/vendor_detail_screen.dart';
import 'package:raunaq/vendor_list_screen.dart';
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
  /// Loaded from Firestore in a follow-up; `'vendor'` shows vendor dashboard.
  final String _userRole = 'user';

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
    // Vendors get a completely different home screen
    if (_userRole == 'vendor') {
      return const VendorDashboardScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Raunaq',
            style: TextStyle(
                color: primaryColor, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            icon: const Icon(Icons.person_outline, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

                const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
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
                const Text('Featured Vendors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Live featured vendors from Firestore
                _FeaturedVendorsList(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen(category: 'all')));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen(category: 'all')));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationsScreen()));
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Vendors'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
}

/// Featured vendors from Firestore (horizontal list).
class _FeaturedVendorsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .orderBy('rating', descending: true)
            .limit(6)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No vendors yet.', style: TextStyle(color: Colors.grey)));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _FeaturedCard(vendorId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.vendorId, required this.data});
  final String vendorId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VendorDetailScreen(vendorId: vendorId, data: data))),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF89CFF0),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Center(child: Text(data['emoji'] ?? '🏛️', style: const TextStyle(fontSize: 36))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text('${data['rating'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ]),
                      Text(data['price'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
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
