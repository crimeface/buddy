import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';
import 'theme.dart';
import 'home_page.dart';
import 'Hostelpg_page.dart';
import 'service_page.dart';
import 'display pages/property_details.dart';
import './display pages/property_details.dart' as property_details;
import './display pages/flatmate_details.dart';
import 'edit_profile.dart';
import 'edit_property.dart';
import 'my_listings.dart';
import 'display pages/hostelpg_details.dart';
import 'privacy_page.dart';

// Add RouteObserver
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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
      navigatorObservers: [routeObserver], // Add route observer
      home: AuthStateHandler(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomeScreen(),
        '/hostelpg': (context) => const HostelPgPage(),
        '/services': (context) => const ServicesPage(),
        '/editProfile': (context) => const EditProfilePage(),
        '/myListings': (context) => const MyListingsPage(),
        '/editProperty': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return EditPropertyPage(propertyData: args['propertyData'] as Map<String, dynamic>);
        },
        '/hostelpg_details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final hostelId = args?['hostelId'] as String? ?? '';
          return HostelDetailsScreen(propertyId: hostelId);
        },
        '/propertyDetails': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final propertyId = args?['propertyId'] as String? ?? '';
          return PropertyDetailsScreen(propertyId: propertyId);
        },
        // '/flatmateDetails': (context) => const FlatmateDetailsPage(),
        '/privacyPolicy': (context) => const PrivacyPolicyPage(),
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