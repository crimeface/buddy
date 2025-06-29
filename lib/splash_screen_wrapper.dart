import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';
import 'home_page.dart';

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({Key? key}) : super(key: key);

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _bannersLoaded = false;
  bool _showSplash = true;
  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
    
    // Add a safety timeout to prevent getting stuck
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _showSplash) {
        print('Splash screen timeout - forcing navigation to home');
        setState(() {
          _showSplash = false;
          _bannersLoaded = true;
        });
      }
    });
  }

  Future<void> _loadBanners() async {
    try {
      // Add a timeout to prevent getting stuck
      final bannersSnap = await FirebaseFirestore.instance
          .collection('promo_banners')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          if (bannersSnap.docs.isNotEmpty) {
            _banners = bannersSnap.docs.map((d) => d.data()).toList();
          } else {
            // If no banners in Firestore, use default banners
            _banners = [
              {
                'title': 'Find Your Perfect Room',
                'subtitle': 'Discover amazing rooms near your campus',
                'icon': 'home_work',
                'image': '',
                'color': '#FF6B6B',
              },
              {
                'title': 'Connect with Flatmates',
                'subtitle': 'Find compatible roommates for your journey',
                'icon': 'group',
                'image': '',
                'color': '#4ECDC4',
              },
              {
                'title': 'Premium Hostels & PG',
                'subtitle': 'Safe and comfortable accommodations',
                'icon': 'hotel',
                'image': '',
                'color': '#45B7D1',
              },
              {
                'title': 'Student Services',
                'subtitle': 'Everything you need for campus life',
                'icon': 'school',
                'image': '',
                'color': '#96CEB4',
              },
            ];
          }
          _bannersLoaded = true;
        });
        
        // Wait a bit for the splash animation to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      }
    } catch (e) {
      print('Error loading banners: $e');
      // If there's an error, still proceed with default banners
      if (mounted) {
        setState(() {
          _banners = [
            {
              'title': 'Find Your Perfect Room',
              'subtitle': 'Discover amazing rooms near your campus',
              'icon': 'home_work',
              'image': '',
              'color': '#FF6B6B',
            },
            {
              'title': 'Connect with Flatmates',
              'subtitle': 'Find compatible roommates for your journey',
              'icon': 'group',
              'image': '',
              'color': '#4ECDC4',
            },
            {
              'title': 'Premium Hostels & PG',
              'subtitle': 'Safe and comfortable accommodations',
              'icon': 'hotel',
              'image': '',
              'color': '#45B7D1',
            },
            {
              'title': 'Student Services',
              'subtitle': 'Everything you need for campus life',
              'icon': 'school',
              'image': '',
              'color': '#96CEB4',
            },
          ];
          _bannersLoaded = true;
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    } else {
      return const HomeScreen();
    }
  }
} 