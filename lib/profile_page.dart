import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
              _buildProfileListItem(
                icon: Icons.person_outline,
                title: 'My Profile',
                iconColor: const Color(0xFF00A2FF), // Light Blue
                backgroundColor: const Color(0xFFE5F5FF),
              ),
              const SizedBox(height: 16),
              _buildProfileListItem(
                icon: Icons
                    .person_outline, // Can change to another icon if preferred
                title: 'Switch to Admin View',
                iconColor: const Color(0xFF8A2BE2), // Purple
                backgroundColor: const Color(0xFFF3E5F5),
              ),
              const SizedBox(height: 16),
              _buildProfileListItem(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: Colors.red,
                backgroundColor: const Color(0xFFFFEBEE),
                textColor: Colors.red,
                isDestructive: true,
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
        color: const Color(
          0xFFFAFBFD,
        ), // Very subtle grey/blue background similar to design
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
