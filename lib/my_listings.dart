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
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('room_listings')
              .where('userId', isEqualTo: user.uid)
              .get();

      final myListings =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['key'] = doc.id;
            // Defensive mapping for location and images
            data['location'] = data['location'] ?? data['address'] ?? '';
            data['uploadedPhotos'] =
                (data['uploadedPhotos'] is List)
                    ? data['uploadedPhotos']
                    : (data['uploadedPhotos'] is Map
                        ? (data['uploadedPhotos'] as Map).values.toList()
                        : []);
            return data;
          }).toList();

      setState(() {
        _listings = myListings;
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
                  final images =
                      (listing['uploadedPhotos'] is List &&
                              (listing['uploadedPhotos'] as List).isNotEmpty)
                          ? listing['uploadedPhotos']
                          : [listing['imageUrl'] ?? ''];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading:
                          images.isNotEmpty &&
                                  images[0] != null &&
                                  images[0].toString().isNotEmpty
                              ? Image.network(
                                images[0],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                              )
                              : const Icon(Icons.home, size: 40),
                      title: Text(listing['title'] ?? 'No Title'),
                      subtitle: Text(listing['location'] ?? ''),
                      trailing: Text('₹${listing['rent'] ?? '-'}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PropertyDetailsScreen(
                                  propertyId: listing['key'],
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}