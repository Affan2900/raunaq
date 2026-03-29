import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raunaq/main.dart';
import 'package:raunaq/vendor_dashboard_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const primaryColor = Color(0xFF00A2FF);
  String _role = 'client';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() => _role = doc.data()?['role'] ?? 'client');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const AuthGate()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Profile', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[200], height: 1)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Avatar card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE5F5FF),
                      child: Text(avatarLetter,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _role == 'vendor' ? const Color(0xFFF3E5F5) : const Color(0xFFE5F5FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _role == 'vendor' ? 'Vendor Account' : 'Client Account',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _role == 'vendor' ? const Color(0xFF8A2BE2) : primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Switch to vendor dashboard (only show for vendors)
              if (_role == 'vendor') ...[
                _menuItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Go to Vendor Dashboard',
                  iconColor: const Color(0xFF8A2BE2),
                  bgColor: const Color(0xFFF3E5F5),
                  onTap: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const VendorDashboardScreen())),
                ),
                const SizedBox(height: 16),
              ],

              _menuItem(
                icon: Icons.person_outline,
                title: 'My Profile',
                iconColor: primaryColor,
                bgColor: const Color(0xFFE5F5FF),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _logout(context),
                child: _menuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  iconColor: Colors.red,
                  bgColor: const Color(0xFFFFEBEE),
                  textColor: Colors.red,
                  isDestructive: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color bgColor,
    Color textColor = Colors.black87,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFFAFBFD), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor))),
            Icon(Icons.chevron_right, color: isDestructive ? Colors.red : Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}
