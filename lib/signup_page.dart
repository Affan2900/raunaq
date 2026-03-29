import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raunaq/home_screen.dart';
import 'package:raunaq/vendor_dashboard_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static const primaryColor = Color(0xFF00A2FF);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Role selection: 'client' or 'vendor'
  String _selectedRole = 'client';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Save display name on Auth profile
      await credential.user?.updateDisplayName(name);

      // 3. Save user document in Firestore (role, name, email, timestamp)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 4. Route based on role
      if (_selectedRole == 'vendor') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Branding
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: primaryColor, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text('Raunaq',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),

            // Form
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text('Create Account',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),

                      // Role selector
                      const Text('I am a...',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _RoleChip(
                              label: 'Client',
                              icon: Icons.person_outline,
                              subtitle: 'Looking for vendors',
                              selected: _selectedRole == 'client',
                              onTap: () =>
                                  setState(() => _selectedRole = 'client'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoleChip(
                              label: 'Vendor',
                              icon: Icons.store_outlined,
                              subtitle: 'Offering services',
                              selected: _selectedRole == 'vendor',
                              onTap: () =>
                                  setState(() => _selectedRole = 'vendor'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _label('Full Name'),
                      _plainField(controller: _nameController, hint: 'Ali Haris', icon: Icons.person_outline),
                      const SizedBox(height: 16),

                      _label('Email Address'),
                      _plainField(controller: _emailController, hint: 'your@email.com', icon: Icons.email_outlined, type: TextInputType.emailAddress),
                      const SizedBox(height: 16),

                      _label('Password'),
                      _pwField(controller: _passwordController, hint: 'Min. 6 characters', obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                      const SizedBox(height: 16),

                      _label('Confirm Password'),
                      _pwField(controller: _confirmController, hint: 'Re-enter password', obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm), onSubmit: (_) => _signup()),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signup,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Login', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      );

  Widget _plainField({required TextEditingController controller, required String hint, required IconData icon, TextInputType type = TextInputType.text}) =>
      TextField(
        controller: controller,
        keyboardType: type,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: Icon(icon, color: Colors.black45),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );

  Widget _pwField({required TextEditingController controller, required String hint, required bool obscure, required VoidCallback onToggle, ValueChanged<String>? onSubmit}) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        textInputAction: onSubmit != null ? TextInputAction.done : TextInputAction.next,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.icon, required this.subtitle, required this.selected, required this.onTap});
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const primaryColor = Color(0xFF00A2FF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F5FF) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primaryColor : Colors.grey.shade200, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? primaryColor : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? primaryColor : Colors.black87)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: selected ? primaryColor.withValues(alpha: 0.7) : Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
