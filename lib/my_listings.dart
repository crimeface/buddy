import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Map<dynamic, dynamic>> _listings = [];
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

    final ref = FirebaseDatabase.instance.ref().child('room_listings');
    final snapshot = await ref.get();
    final List<Map<dynamic, dynamic>> myListings = [];
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final listing = Map<String, dynamic>.from(value as Map);
        // Assuming you store user id as 'uid' in each listing
        if (listing['uid'] == user.uid) {
          listing['key'] = key;
          myListings.add(listing);
        }
      });
    }
    setState(() {
      _listings = myListings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
              ? const Center(child: Text('No listings found.'))
              : ListView.builder(
                  itemCount: _listings.length,
                  itemBuilder: (context, index) {
                    final listing = _listings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: listing['uploadedPhotos'] != null &&
                                (listing['uploadedPhotos'] as List).isNotEmpty
                            ? Image.network(
                                listing['uploadedPhotos'][0],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.home, size: 40),
                        title: Text(listing['title'] ?? 'No Title'),
                        subtitle: Text(listing['location'] ?? ''),
                        trailing: Text('₹${listing['rent'] ?? '-'}'),
                        onTap: () {
                          // Optionally, navigate to details page
                        },
                      ),
                    );
                  },
                ),
    );
  }
}