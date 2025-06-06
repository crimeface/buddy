import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './display pages/property_details.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyListings();
  }

  Future<void> _fetchMyListings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final uid = user.uid;
      final now = DateTime.now();
      // Room listings
      final roomSnap =
          await FirebaseFirestore.instance
              .collection('room_listings')
              .where('userId', isEqualTo: uid)
              .get();
      // Hostel listings
      final hostelSnap =
          await FirebaseFirestore.instance
              .collection('hostel_listings')
              .where('uid', isEqualTo: uid)
              .get();
      // Service listings
      final serviceSnap =
          await FirebaseFirestore.instance
              .collection('service_listings')
              .where('userId', isEqualTo: uid)
              .get();
      // Flatmate listings (roomRequests)
      final flatmateSnap =
          await FirebaseFirestore.instance
              .collection('roomRequests')
              .where('userId', isEqualTo: uid)
              .get();

      final List<Map<String, dynamic>> all = [];
      // Room
      for (var doc in roomSnap.docs) {
        final data = doc.data();
        data['key'] = doc.id;
        data['listingType'] = 'Room';
        data['title'] = data['title'] ?? 'Room Listing';
        data['location'] = data['location'] ?? data['address'] ?? '';
        data['imageUrl'] =
            (data['uploadedPhotos'] is Map &&
                    (data['uploadedPhotos'] as Map).values.any(
                      (v) => v != null && v.toString().isNotEmpty,
                    ))
                ? (data['uploadedPhotos'] as Map).values.firstWhere(
                  (v) => v != null && v.toString().isNotEmpty,
                  orElse: () => '',
                )
                : (data['imageUrl'] ?? '');
        all.add(data);
      }
      // Hostel
      for (var doc in hostelSnap.docs) {
        final data = doc.data();
        data['key'] = doc.id;
        data['listingType'] = 'Hostel/PG';
        data['title'] =
            data['hostelName'] ?? data['title'] ?? 'Hostel/PG Listing';
        data['location'] = data['address'] ?? data['location'] ?? '';
        data['imageUrl'] =
            (data['uploadedPhotos'] is Map &&
                    (data['uploadedPhotos'] as Map).isNotEmpty)
                ? (data['uploadedPhotos'] as Map).values.firstWhere(
                  (v) => v != null && v.toString().isNotEmpty,
                  orElse: () => '',
                )
                : (data['imageUrl'] ?? '');
        all.add(data);
      }
      // Service
      for (var doc in serviceSnap.docs) {
        final data = doc.data();
        data['key'] = doc.id;
        data['listingType'] = 'Service';
        data['title'] = data['serviceName'] ?? 'Service Listing';
        data['location'] = data['location'] ?? '';
        data['imageUrl'] =
            data['coverPhoto'] ??
            (data['additionalPhotos'] is List &&
                    (data['additionalPhotos'] as List).isNotEmpty
                ? data['additionalPhotos'][0]
                : (data['imageUrl'] ?? ''));
        all.add(data);
      }
      // Flatmate
      for (var doc in flatmateSnap.docs) {
        final data = doc.data();
        data['key'] = doc.id;
        data['listingType'] = 'Flatmate';
        data['title'] = data['title'] ?? data['name'] ?? 'Flatmate Listing';
        data['location'] = data['location'] ?? '';
        data['imageUrl'] = data['photoUrl'] ?? (data['image'] ?? '');
        all.add(data);
      }

      setState(() {
        _listings = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _listings = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load listings: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _listings.isEmpty
              ? const Center(child: Text('No listings found.'))
              : ListView.builder(
                itemCount: _listings.length,
                itemBuilder: (context, index) {
                  final listing = _listings[index];
                  final image = listing['imageUrl'] ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading:
                          image.isNotEmpty
                              ? Image.network(
                                image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                              )
                              : const Icon(Icons.home, size: 40),
                      title: Text(listing['title'] ?? 'No Title'),
                      subtitle: Text(
                        '${listing['listingType']}\n${listing['location'] ?? ''}',
                      ),
                      trailing:
                          listing['rent'] != null
                              ? Text('₹${listing['rent']}')
                              : null,
                      onTap: () {
                        // You can route to different detail screens based on type if needed
                      },
                    ),
                  );
                },
              ),
    );
  }
}
