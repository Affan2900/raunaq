import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This was generated in Step 3

void main() async {
  // Ensure Flutter engine is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated options for your specific platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Connected')),
        body: const Center(child: Text('Connected to mad-project-b0caf')),
      ),
    );
  }
}
