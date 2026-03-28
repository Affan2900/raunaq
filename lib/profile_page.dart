import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raunaq/main.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const primaryColor = Color(0xFF00A2FF);

  // ── Firebase logout ─────────────────────────────────────────────────────────
  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    // Go back to AuthGate — it will detect the user is null and show LoginPage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Read the currently logged-in user from Firebase
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    // First letter of name for the avatar
    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            children: [
              // ── Avatar card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Circular avatar with first letter
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE5F5FF),
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name and email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Menu items ──
              _buildProfileListItem(
                icon: Icons.person_outline,
                title: 'My Profile',
                iconColor: primaryColor,
                backgroundColor: const Color(0xFFE5F5FF),
              ),
              const SizedBox(height: 16),
              _buildProfileListItem(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Switch to Admin View',
                iconColor: const Color(0xFF8A2BE2),
                backgroundColor: const Color(0xFFF3E5F5),
              ),
              const SizedBox(height: 16),

              // Logout — wrapped in GestureDetector to call _logout
              GestureDetector(
                onTap: () => _logout(context),
                child: _buildProfileListItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  iconColor: Colors.red,
                  backgroundColor: const Color(0xFFFFEBEE),
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

  Widget _buildProfileListItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color backgroundColor,
    Color textColor = Colors.black87,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDestructive ? Colors.red : Colors.grey[400],
            size: 24,
          ),
        ],
      ),
    );
  }
}
