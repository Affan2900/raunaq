import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This was generated in Step 3
import 'splash_screen.dart'; // The new splash screen

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
      title: 'Raunaq',
      debugShowCheckedModeBanner: false, // Hiding the debug banner
      theme: ThemeData(
        primaryColor: const Color(0xFF00A2FF),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
