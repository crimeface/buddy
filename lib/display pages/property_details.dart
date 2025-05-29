import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class PropertyData {
  final String title;
  final String location;
  final String availableFrom;
  final String roomType;
  final String flatSize;
  final String furnishing;
  final String bathroom;
  final double monthlyRent;
  final double securityDeposit;
  final int currentFlatmates;
  final int maxFlatmates;
  final String gender;
  final String occupation;
  final List<String> images;
  final List<String> amenities;
  final String description;
  final String ownerName;
  final double ownerRating;
  final Map<String, String> preferences;
  final String phone;
  final String email;
  final String? googleMapsLink; // Added Google Maps link

  PropertyData({
    required this.title,
    required this.location,
    required this.availableFrom,
    required this.roomType,
    required this.flatSize,
    required this.furnishing,
    required this.bathroom,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.currentFlatmates,
    required this.maxFlatmates,
    required this.gender,
    required this.occupation,
    required this.images,
    required this.amenities,
    required this.description,
    required this.ownerName,
    required this.ownerRating,
    required this.preferences,
    required this.phone,
    required this.email,
    this.googleMapsLink, // Added Google Maps link
  });

  factory PropertyData.fromJson(Map<String, dynamic> json) {
    // Format the date string to DD-MM-YYYY
    String formatAvailableDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '';
      try {
        if (dateStr.contains('T')) {
          String date = dateStr.split('T')[0];
          final parts = date.split('-');
          if (parts.length == 3) {
            return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
          }
        }
        return dateStr;
      } catch (e) {
        return dateStr;
      }
    }

    return PropertyData(
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      availableFrom: formatAvailableDate(json['availableFromDate']),
      roomType: json['roomType'] ?? '',
      flatSize: json['flatSize'] ?? '',
      furnishing: json['furnishing'] ?? '',
      bathroom: json['bathroom'] ?? '',
      monthlyRent: (json['monthlyRent'] ?? 0.0).toDouble(),
      securityDeposit: (json['securityDeposit'] ?? 0.0).toDouble(),
      currentFlatmates: json['currentFlatmates'] ?? 0,
      maxFlatmates: json['maxFlatmates'] ?? 0,
      gender: json['gender'] ?? '',
      occupation: json['occupation'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      description: json['description'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerRating: (json['ownerRating'] ?? 0.0).toDouble(),
      preferences: Map<String, String>.from(json['preferences'] ?? {}),
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      googleMapsLink: json['googleMapsLink'], // Added Google Maps link
    );
  }
}

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late PropertyData propertyData;
  bool isBookmarked = false;
  int currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchPropertyDetails();
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    final parts = dateString.split('T')[0].split('-');
    if (parts.length != 3) return dateString;
    return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
  }

  Future<void> _fetchPropertyDetails() async {
    try {
      final snapshot = await _database
          .child('room_listings')
          .child(widget.propertyId)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Get owner details from users table by iterating through users to find matching email
        final ownerEmail = data['email'];
        final usersSnapshot = await _database.child('users').get();
        String ownerName = 'Unknown';
        
        if (usersSnapshot.exists) {
          final users = Map<String, dynamic>.from(usersSnapshot.value as Map);
          users.forEach((key, value) {
            if (value['email'] == ownerEmail) {
              ownerName = value['username'] ?? 'Unknown';
            }
          });
        }

        final convertedData = {
          'title': data['title'],
          'location': data['location'],
          'availableFromDate': data['availableFromDate']?.toString() ?? '',
          'roomType': data['roomType'],
          'flatSize': data['flatSize'],
          'furnishing': data['furnishing'],
          'bathroom': data['hasAttachedBathroom'] ? 'Attached' : 'Not Attached',
          'monthlyRent': double.parse(data['rent']),
          'securityDeposit': double.parse(data['deposit']),
          'currentFlatmates': data['currentFlatmates'],
          'maxFlatmates': data['maxFlatmates'],
          'gender': data['genderComposition'],
          'occupation': data['occupation'],
          'images': data['uploadedPhotos'] != null ? List<String>.from(data['uploadedPhotos']) : [data['imageUrl'] ?? ''],
          'amenities': _getFacilities(data['facilities'] as Map?),
          'description': data['notes'] ?? '',
          'ownerName': ownerName,
          'ownerRating': 0.0,  // Not available in current structure
          'phone': data['phone'] ?? '',
          'email': data['email'] ?? '',
          'googleMapsLink': data['locationUrl'] ?? data['mapLink'] ?? '', // Support both locationUrl and mapLink fields
          'preferences': {
            'lookingFor': data['lookingFor'] ?? '',
            'foodPreference': data['foodPreference'] ?? '',
            'smokingPolicy': data['smokingPolicy'] ?? '',
            'drinkingPolicy': data['drinkingPolicy'] ?? '',
            'guestPolicy': data['guestsPolicy'] ?? ''
          }
        };

        setState(() {
          propertyData = PropertyData.fromJson(convertedData);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Property not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading property details';
        isLoading = false;
      });
    }
  }

  List<String> _getFacilities(Map? facilities) {
    if (facilities == null) return [];
    return facilities.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key.toString())
        .toList();
  }

  Future<void> _openGoogleMaps() async {
    if (propertyData.googleMapsLink == null || propertyData.googleMapsLink!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No map link available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    String url = propertyData.googleMapsLink!.trim();
    
    // Handle different types of map links
    if (url.startsWith('maps.google.com') || url.startsWith('www.google.com/maps')) {
      url = 'https://' + url;
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('maps.google.com') || url.contains('goo.gl/maps')) {
        url = 'https://' + url;
      } else {
        // If it's not a maps URL, create a search query
        url = 'https://www.google.com/maps/search/?api=1&query=' + Uri.encodeComponent(url);
      }
    }

    try {
      final Uri mapsUri = Uri.parse(url);
      // Try to launch directly first
      bool launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
      
      // If direct launch fails, try with google maps app specifically
      if (!launched) {
        final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(propertyData.location)}';
        final Uri gmapsUri = Uri.parse(googleMapsUrl);
        launched = await launchUrl(
          gmapsUri,
          mode: LaunchMode.externalApplication,
        );
      }
      
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps. URL: $url'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<String> get propertyImages => !isLoading ? propertyData.images : [];
  List<String> get amenities => !isLoading ? propertyData.amenities : [];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(error!),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BuddyTheme.backgroundPrimaryColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyInfo(),
                _buildRoomAndFlatDetails(),
                _buildPricingDetails(),
                if (propertyData.currentFlatmates > 0 || propertyData.maxFlatmates > 0 || 
                    propertyData.gender.isNotEmpty || propertyData.occupation.isNotEmpty)
                  _buildFlatmateInfo(),
                if (propertyData.preferences.values.any((value) => value.isNotEmpty))
                  _buildPreferences(),
                if (amenities.isNotEmpty)
                  _buildAmenities(),
                if (propertyData.description.isNotEmpty)
                  _buildDescription(),
                if (propertyData.ownerName.isNotEmpty)
                  _buildOwnerInfo(),
                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: BuddyTheme.backgroundPrimaryColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(BuddyTheme.spacingXs),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: BuddyTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(BuddyTheme.spacingXs),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? BuddyTheme.primaryColor : BuddyTheme.textPrimaryColor,
            ),
            onPressed: () {
              setState(() {
                isBookmarked = !isBookmarked;
              });
              HapticFeedback.lightImpact();
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(BuddyTheme.spacingXs),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: BuddyTheme.textPrimaryColor),
            onPressed: () {
              // Handle share
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentImageIndex = index;
                });
              },
              itemCount: propertyImages.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(propertyImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: BuddyTheme.spacingMd,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: propertyImages.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentImageIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            propertyData.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: BuddyTheme.iconSizeSm,
                color: BuddyTheme.textSecondaryColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              Expanded(
                child: Text(
                  propertyData.location,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BuddyTheme.textSecondaryColor,
                  ),
                ),
              ),
              // Add Google Maps button if link is available
              if (propertyData.googleMapsLink != null && propertyData.googleMapsLink!.isNotEmpty)
                GestureDetector(
                  onTap: _openGoogleMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BuddyTheme.spacingSm,
                      vertical: BuddyTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: BuddyTheme.primaryColor,
                      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map,
                          size: BuddyTheme.iconSizeSm,
                          color: Colors.white,
                        ),
                        const SizedBox(width: BuddyTheme.spacingXs),
                        Text(
                          'View on Map',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BuddyTheme.spacingXs,
                  vertical: BuddyTheme.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: BuddyTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  propertyData.availableFrom.isEmpty
                      ? 'Available Now'
                      : 'Available from: ${propertyData.availableFrom}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BuddyTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomAndFlatDetails() {
    final List<Widget> detailRows = [];
    
    // First row
    final List<Widget> firstRow = [];
    if (propertyData.roomType.isNotEmpty) {
      firstRow.add(Expanded(
        child: _buildDetailItem('Room Type', propertyData.roomType, Icons.bed),
      ));
    }
    if (propertyData.flatSize.isNotEmpty) {
      firstRow.add(Expanded(
        child: _buildDetailItem('Flat Size', propertyData.flatSize, Icons.home),
      ));
    }
    if (firstRow.isNotEmpty) {
      detailRows.add(Row(children: firstRow));
    }

    // Second row
    final List<Widget> secondRow = [];
    if (propertyData.furnishing.isNotEmpty) {
      secondRow.add(Expanded(
        child: _buildDetailItem('Furnishing', propertyData.furnishing, Icons.chair),
      ));
    }
    if (propertyData.bathroom.isNotEmpty) {
      secondRow.add(Expanded(
        child: _buildDetailItem('Bathroom', propertyData.bathroom, Icons.bathtub),
      ));
    }
    if (secondRow.isNotEmpty) {
      if (detailRows.isNotEmpty) {
        detailRows.add(const SizedBox(height: BuddyTheme.spacingSm));
      }
      detailRows.add(Row(children: secondRow));
    }

    // Return empty container if no details available
    if (detailRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room & Flat Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          ...detailRows,
        ],
      ),
    );
  }

  Widget _buildPricingDetails() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Rent',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BuddyTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    '₹${propertyData.monthlyRent.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BuddyTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Security Deposit',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BuddyTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    '₹${propertyData.securityDeposit.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BuddyTheme.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlatmateInfo() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flatmate Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Current Flatmates', propertyData.currentFlatmates.toString(), Icons.people),
              ),
              Expanded(
                child: _buildDetailItem('Max Flatmates', propertyData.maxFlatmates.toString(), Icons.group),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Gender', propertyData.gender, Icons.wc),
              ),
              Expanded(
                child: _buildDetailItem('Occupation', propertyData.occupation, Icons.school),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences & Policies',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          _buildPreferenceItem('Looking For', propertyData.preferences['lookingFor'] ?? '', Icons.person_search),
          _buildPreferenceItem('Food Preference', propertyData.preferences['foodPreference'] ?? '', Icons.restaurant),
          _buildPreferenceItem('Smoking Policy', propertyData.preferences['smokingPolicy'] ?? '', Icons.smoking_rooms),
          _buildPreferenceItem('Drinking Policy', propertyData.preferences['drinkingPolicy'] ?? '', Icons.local_bar),
          _buildPreferenceItem('Guest Policy', propertyData.preferences['guestPolicy'] ?? '', Icons.people_outline),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingSm),
      margin: const EdgeInsets.only(right: BuddyTheme.spacingXs),
      decoration: BoxDecoration(
        color: BuddyTheme.backgroundSecondaryColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
        border: Border.all(color: BuddyTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: BuddyTheme.iconSizeMd,
            color: BuddyTheme.primaryColor,
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BuddyTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BuddyTheme.spacingXs),
      child: Row(
        children: [
          Icon(
            icon,
            size: BuddyTheme.iconSizeSm,
            color: BuddyTheme.primaryColor,
          ),
          const SizedBox(width: BuddyTheme.spacingSm),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: BuddyTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Facilities & Amenities',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Wrap(
            spacing: BuddyTheme.spacingXs,
            runSpacing: BuddyTheme.spacingXs,
            children: amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BuddyTheme.spacingSm,
                  vertical: BuddyTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: BuddyTheme.backgroundSecondaryColor,
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                  border: Border.all(color: BuddyTheme.borderColor),
                ),
                child: Text(
                  amenity,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BuddyTheme.textPrimaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Text(
            propertyData.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: BuddyTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'UK';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildOwnerInfo() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      margin: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Owner',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: BuddyTheme.primaryColor,
                child: Text(
                  _getInitials(propertyData.ownerName),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: BuddyTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyData.ownerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Property Owner • ${propertyData.ownerName != "Unknown" ? "Verified" : "Unverified"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (propertyData.ownerRating > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: BuddyTheme.iconSizeSm,
                      color: Colors.amber,
                    ),
                    Text(
                      propertyData.ownerRating.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: BuddyTheme.backgroundPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final Uri callUri = Uri.parse('tel:${propertyData.phone}');
                  if (await canLaunchUrl(callUri)) {
                    await launchUrl(callUri);
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: BuddyTheme.spacingSm),
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingSm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final Uri smsUri = Uri.parse('sms:${propertyData.preferences['phone'] ?? ''}');
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  }
                },
                icon: const Icon(Icons.message),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: BuddyTheme.spacingSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}