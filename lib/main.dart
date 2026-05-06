import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:raunaq/home_screen.dart';
import 'package:raunaq/login_page.dart';
import 'firebase_options.dart'; // This was generated in Step 3
import 'auth_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  if (kIsWeb) {
    final apiKey = dotenv.env['FIREBASE_WEB_API_KEY']?.trim() ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID']?.trim() ?? '';
    if (apiKey.isEmpty || projectId.isEmpty) {
      throw StateError(
        'Web Firebase config is missing. Add FIREBASE_WEB_API_KEY and FIREBASE_PROJECT_ID '
        '(and other keys) to your project root `.env`. See `.env.example` and copy values '
        'from Firebase Console → Project settings → General → Your apps → Web.',
      );
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Avoids intermittent Firestore JS "INTERNAL ASSERTION FAILED" (e.g. b815) on web
  // tied to IndexedDB persistence / watch pipeline; OK to disable until SDK fixes land.
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  runApp(const RaunaqApp());
}

class RaunaqApp extends StatelessWidget {
  const RaunaqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raunaq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00A2FF),
        useMaterial3: true,
      ),
      home: const AuthEntry(),
    );
  }
}

/// Listens to Firebase auth state and routes accordingly.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginPage();
      },
    );
  }
}
