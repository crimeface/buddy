import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'display pages/service_details.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _wishlist = [];
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fetchWishlist();
  }

  @override
  void dispose() {
    _controller.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _fetchWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final bookmarkedProperties =
        (userDoc.data()?['bookmarkedProperties'] as List?)?.cast<String>() ??
        [];
    final bookmarkedHostels =
        (userDoc.data()?['bookmarkedHostels'] as List?)?.cast<String>() ?? [];
    final bookmarkedServices =
        (userDoc.data()?['bookmarkedServices'] as List?)?.cast<String>() ?? [];

    String? extractImageUrl(dynamic data) {
      if (data == null) return null;
      if (data is String && data.isNotEmpty) return data;
      if (data is Map && data.isNotEmpty)
        return data.values
            .firstWhere(
              (v) => v != null && v.toString().isNotEmpty,
              orElse: () => null,
            )
            ?.toString();
      if (data is List && data.isNotEmpty) return data.first.toString();
      return null;
    }

    final List<Map<String, dynamic>> allItems = [];

    // Fetch properties and hostels from bookmarkedProperties
    for (final id in bookmarkedProperties) {
      var doc =
          await FirebaseFirestore.instance
              .collection('room_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Room';
        data['title'] = data['title'] ?? 'Room Listing';
        data['location'] = data['location'] ?? data['address'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
        continue;
      }

      doc =
          await FirebaseFirestore.instance
              .collection('hostel_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Hostel/PG';
        data['title'] = data['title'] ?? 'Hostel/PG Listing';
        data['location'] = data['address'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
      }
    }

    // Fetch hostels from bookmarkedHostels
    for (final id in bookmarkedHostels) {
      if (allItems.any((item) => item['key'] == id)) continue;
      final doc =
          await FirebaseFirestore.instance
              .collection('hostel_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Hostel/PG';
        data['title'] = data['title'] ?? 'Hostel/PG Listing';
        data['location'] = data['address'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
      }
    }

    // Fetch services
    for (final id in bookmarkedServices) {
      final doc =
          await FirebaseFirestore.instance
              .collection('service_listings')
              .doc(id)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['key'] = doc.id;
        data['listingType'] = 'Service';
        data['title'] = data['serviceName'] ?? 'Service Listing';
        data['location'] = data['location'] ?? '';
        data['imageUrl'] =
            extractImageUrl(data['imageUrl']) ??
            extractImageUrl(data['uploadedPhotos']) ??
            '';
        allItems.add(data);
      }
    }

    setState(() {
      _wishlist = allItems;
      _isLoading = false;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (_wishlist.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildListingCard(_wishlist[index], index),
                        ),
                      );
                    },
                  );
                }, childCount: _wishlist.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color.fromARGB(255, 95, 148, 247), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: const Text(
            'My Wishlist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: IconButton(
            icon: AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _heartController.value * 0.2,
                  child: const Icon(Icons.favorite, color: Color(0xFFFF6B6B)),
                );
              },
            ),
            onPressed: () {
              _heartController.forward().then((_) {
                _heartController.reverse();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Loading your favorites...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                  ).createShader(bounds),
              child: const Text(
                'Your Wishlist is Empty',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Start exploring and save your favorite places!',
              style: TextStyle(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Explore Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing, int index) {
    final image = listing['imageUrl'] ?? '';
    final type = listing['listingType'] ?? '';
    final color =
        type == 'Hostel/PG'
            ? const Color(0xFF9B59B6)
            : type == 'Service'
            ? const Color(0xFF2ECC71)
            : const Color(0xFF3498DB);
    final icon =
        type == 'Hostel/PG'
            ? Icons.apartment_rounded
            : type == 'Service'
            ? Icons.miscellaneous_services_rounded
            : Icons.home_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (type == 'Room') {
              Navigator.pushNamed(
                context,
                '/propertyDetails',
                arguments: {'propertyId': listing['key']},
              );
            } else if (type == 'Hostel/PG') {
              Navigator.pushNamed(
                context,
                '/hostelpg_details',
                arguments: {'hostelId': listing['key']},
              );
            } else if (type == 'Service') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ServiceDetailsScreen(serviceId: listing['key']),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child:
                          image.isNotEmpty
                              ? Image.network(
                                image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildImagePlaceholder(color, icon),
                              )
                              : _buildImagePlaceholder(color, icon),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing['location']?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                listing['location'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(icon, size: 48, color: color),
        ),
      ),
    );
  }
}