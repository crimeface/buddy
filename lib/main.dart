import 'package:buddy/display%20pages/service_details.dart';
import 'package:buddy/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for SystemChrome
import 'login.dart';
import 'signup.dart';
import 'theme.dart';
import 'home_page.dart';
import 'Hostelpg_page.dart';
import 'service_page.dart';
import 'display pages/property_details.dart';
import 'edit_profile.dart';
import 'edit_property.dart';
import 'edit_service.dart';
import 'my_listings.dart';
import 'display pages/hostelpg_details.dart';
import 'privacy_page.dart';
import 'edit_hostelpg.dart';
import 'onboarding_screen.dart'; // Changed from landing_screen.dart
import 'authentication_options.dart'; // Importing the new Authentication Options page
import 'phone_verification.dart'; // Added import for phone verification
import 'api/firebase_api.dart'; // Import Firebase API for notifications
import 'package:firebase_messaging/firebase_messaging.dart';

// Add RouteObserver
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hide system navigation and status bars at app startup
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();

  runApp(const BuddyApp());
}

Future<void> _setupFirebaseNotifications() async {
  final firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();

  // Handle background/terminated message tapping
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    // You can navigate user based on payload here
    print('User tapped notification: ${message.data}');
  });
}

class BuddyApp extends StatelessWidget {
  const BuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buddy',
      theme: BuddyTheme.lightTheme,
      darkTheme: BuddyTheme.darkTheme,
      themeMode: ThemeMode.dark, // Use system theme by default
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver], // Add route observer
      home: AuthStateHandler(),
      routes: {
        '/auth-options':
            (context) =>
                const AuthOptionsPage(), // New route for Authentication Options
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/phone-verification':
            (context) =>
                PhoneVerificationPage(), // Added route for phone verification
        '/home': (context) => const HomeScreen(),
        '/editProfile': (context) => const EditProfilePage(),
        '/myListings': (context) => const MyListingsPage(),
        '/editProperty': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>;
          return EditPropertyPage(
            propertyData: args['propertyData'] as Map<String, dynamic>,
          );
        },
        '/editHostelPG': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          if (args == null || args['hostelData'] == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid hostel data')),
            );
          }
          return EditHostelPGPage(
            hostelData: args['hostelData'] as Map<String, dynamic>,
          );
        },
        '/hostelpg_details': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
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
        '/service_details': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final serviceId = args?['serviceId'] as String? ?? '';
          return ServiceDetailsScreen(serviceId: serviceId);
        },
        '/editService': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid service data')),
            );
          }
          return EditServicePage(
            serviceId: args['serviceId'] as String,
            serviceData: args['serviceData'] as Map<String, dynamic>,
          );
        },
        // '/flatmateDetails': (context) => const FlatmateDetailsPage(),
        '/privacyPolicy': (context) => const PrivacyPolicyPage(),
      },
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

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
          // Show OnboardingScreen first, then navigate to LoginPage
          return OnboardingScreenWrapper(); // Changed from LandingScreenWrapper
        }
      },
    );
  }
}

class OnboardingScreenWrapper extends StatefulWidget {
  // Renamed class
  @override
  State<OnboardingScreenWrapper> createState() =>
      _OnboardingScreenWrapperState();
}

class _OnboardingScreenWrapperState extends State<OnboardingScreenWrapper> {
  // Updated class name
  bool _showOnboarding = true; // Renamed variable

  void _onOnboardingComplete() {
    // Renamed method
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: _onOnboardingComplete,
      ); // Changed to OnboardingScreen
    } else {
      return const LoginPage();
    }
  }
}
