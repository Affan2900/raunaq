import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raunaq/home_screen.dart';
import 'package:raunaq/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const primaryColor = Color(0xFF00A2FF);
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true, _loading = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      _err('Please enter your email and password.'); return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passwordCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } on FirebaseAuthException catch (e) {
      _err(_msg(e.code));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _reset() async {
    if (_emailCtrl.text.trim().isEmpty) { _err('Enter your email first.'); return; }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailCtrl.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent.')));
  }

  void _err(String m) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red.shade700)); }
  String _msg(String c) { switch (c) { case 'user-not-found': return 'No account for this email.'; case 'wrong-password': case 'invalid-credential': return 'Incorrect email or password.'; case 'too-many-requests': return 'Too many attempts. Try again later.'; default: return 'Login failed. Try again.'; } }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(bottom: false, child: Column(children: [
        Expanded(flex: 3, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_outlined, color: primaryColor, size: 40)),
          const SizedBox(height: 16),
          const Text('Raunaq', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Plan your dream event with ease', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ]))),
        Expanded(flex: 5, child: Container(width: double.infinity, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
          child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Center(child: Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            const SizedBox(height: 32),
            const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
              decoration: InputDecoration(hintText: 'your@email.com', hintStyle: const TextStyle(color: Colors.black38), prefixIcon: const Icon(Icons.email_outlined, color: Colors.black45), filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16))),
            const SizedBox(height: 20),
            const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(controller: _passwordCtrl, obscureText: _obscure, textInputAction: TextInputAction.done, onSubmitted: (_) => _login(),
              decoration: InputDecoration(hintText: 'Enter your password', hintStyle: const TextStyle(color: Colors.black38), prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45), onPressed: () => setState(() => _obscure = !_obscure)), filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16))),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _reset, child: const Text('Forgot Password?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't have an account? ", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
                  child: const Text('Sign Up', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
            ]),
          ])),
        )),
      ])),
    );
  }
}
