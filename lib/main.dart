import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:raunaq/state/admin_mode_notifier.dart';
import 'package:raunaq/home_screen.dart';
import 'package:raunaq/login_page.dart';
import 'firebase_options.dart'; // This was generated in Step 3
import 'auth_entry.dart';

/// Set when [.env] load, Firebase init, or validation fails — avoids a blank/black screen in release.
Object? _bootstrapError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');

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

    await _initializeFirebaseApp();

    // Avoids intermittent Firestore JS "INTERNAL ASSERTION FAILED" (e.g. b815) on web
    // tied to IndexedDB persistence / watch pipeline; OK to disable until SDK fixes land.
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
  } catch (e, st) {
    _bootstrapError = e;
    debugPrint('Raunaq bootstrap failed: $e\n$st');
  }

  runApp(
    ChangeNotifierProvider<AdminModeNotifier>(
      create: (_) => AdminModeNotifier(),
      child: _bootstrapError != null
          ? BootstrapFailureApp(error: _bootstrapError!)
          : const RaunaqApp(),
    ),
  );
}

Future<void> _initializeFirebaseApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // Android may already have default app from google-services.json native init.
    if (e.code == 'duplicate-app') return;
    rethrow;
  }
}

/// Visible error when startup fails (release builds show no red screen otherwise).
class BootstrapFailureApp extends StatelessWidget {
  const BootstrapFailureApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raunaq',
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Startup failed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$error',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Check that .env is listed under flutter assets in pubspec.yaml, '
                    'includes all Firebase keys for Android, was present when you ran '
                    'flutter build apk, and matches google-services.json.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
