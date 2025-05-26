import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';
import 'theme.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BuddyApp());
}

class BuddyApp extends StatelessWidget {
  const BuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buddy',
      theme: BuddyTheme.lightTheme,
      darkTheme: BuddyTheme.darkTheme,
      themeMode: ThemeMode.system, // Use system theme by default
      debugShowCheckedModeBanner: false,
      home: AuthStateHandler(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}