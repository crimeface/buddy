import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({Key? key, required this.propertyId})
      : super(key: key);

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  Map<String, dynamic>? _propertyDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPropertyDetails();
  }

  Future<void> _fetchPropertyDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hostel_listings')
          .doc(widget.propertyId)
          .get();

      if (doc.exists) {
        setState(() {
          _propertyDetails = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property not found')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading property details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
    final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF718096);
    final Color textLight = isDark ? Colors.white38 : const Color(0xFFA0AEC0);
    final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _propertyDetails?['title'] ?? 'Property Details',
          style: TextStyle(color: textPrimary),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  BuddyTheme.primaryColor,
                ),
              ),
            )
          : _propertyDetails == null
              ? Center(
                  child: Text(
                    'Property not found',
                    style: TextStyle(color: textPrimary),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Carousel
                      if (_propertyDetails?['uploadedPhotos'] != null) ...[
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            itemCount: (_propertyDetails!['uploadedPhotos']
                                    is Map)
                                ? (_propertyDetails!['uploadedPhotos'] as Map)
                                    .values
                                    .length
                                : 1,
                            itemBuilder: (context, index) {
                              final photos = _propertyDetails!['uploadedPhotos'];
                              final imageUrl = (photos is Map)
                                  ? (photos as Map).values.elementAt(index)
                                  : photos is String
                                      ? photos
                                      : '';
                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: borderColor,
                                  highlightColor: cardColor,
                                  child: Container(color: borderColor),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: borderColor,
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: textLight,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Location
                            Text(
                              _propertyDetails?['title'] ?? '',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_propertyDetails?['address'] != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _propertyDetails!['address'],
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Room Types and Pricing
                            if (_propertyDetails?['roomTypes'] != null) ...[
                              Text(
                                'Room Types',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(_propertyDetails!['roomTypes'] as List)
                                  .map((room) => Card(
                                        color: cardColor,
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      room['type'] ?? '',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                    if (room['description'] !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        room['description'],
                                                        style: TextStyle(
                                                          color: textSecondary,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '₹${room['rentPerPerson']}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: BuddyTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ],

                            const SizedBox(height: 24),

                            // Facilities
                            if (_propertyDetails?['facilities'] != null &&
                                (_propertyDetails!['facilities'] as List)
                                    .isNotEmpty) ...[
                              Text(
                                'Facilities',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (_propertyDetails!['facilities'] as List)
                                    .map(
                                      (facility) => Chip(
                                        label: Text(
                                          facility,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        backgroundColor: cardColor,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Contact Information
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    if (_propertyDetails?['contactPerson'] !=
                                        null) ...[
                                      ListTile(
                                        leading: Icon(Icons.person_outline,
                                            color: textSecondary),
                                        title: Text(
                                          _propertyDetails!['contactPerson'],
                                          style: TextStyle(color: textPrimary),
                                        ),
                                        dense: true,
                                      ),
                                    ],
                                    if (_propertyDetails?['phone'] != null) ...[
                                      ListTile(
                                        leading: Icon(Icons.phone_outlined,
                                            color: textSecondary),
                                        title: Text(
                                          _propertyDetails!['phone'],
                                          style: TextStyle(color: textPrimary),
                                        ),
                                        dense: true,
                                      ),
                                    ],
                                    if (_propertyDetails?['email'] != null) ...[
                                      ListTile(
                                        leading: Icon(Icons.email_outlined,
                                            color: textSecondary),
                                        title: Text(
                                          _propertyDetails!['email'],
                                          style: TextStyle(color: textPrimary),
                                        ),
                                        dense: true,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
