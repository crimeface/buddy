import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';

class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageGallery({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenImageGalleryState createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                Navigator.pop(context);
              }
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: BuddyTheme.fontSizeMd,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ],
      ),
    );
  }
}

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
  final double brokerage;
  final int currentFlatmates;
  final int maxFlatmates;
  final String gender;
  final String occupation;
  final Map<String, String> images;
  final List<String> amenities;
  final String description;
  final String ownerName;
  final double ownerRating;
  final Map<String, String> preferences;
  final String phone;
  final String email;
  final String? googleMapsLink;

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
    required this.brokerage,
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
    this.googleMapsLink,
  });

  factory PropertyData.fromJson(Map<String, dynamic> json) {
    double parseNumericValue(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseIntValue(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PropertyData(
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      availableFrom: json['availableFromDate'] ?? '',
      roomType: json['roomType'] ?? '',
      flatSize: json['flatSize'] ?? '',
      furnishing: json['furnishing'] ?? '',
      bathroom: json['bathroom'] ?? '',
      monthlyRent: parseNumericValue(json['monthlyRent']),
      securityDeposit: parseNumericValue(json['securityDeposit']),
      brokerage: parseNumericValue(json['brokerage']),
      currentFlatmates: parseIntValue(json['currentFlatmates']),
      maxFlatmates: parseIntValue(json['maxFlatmates']),
      gender: json['gender'] ?? '',
      occupation: json['occupation'] ?? '',
      images:
          (json['images'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerRating: parseNumericValue(json['ownerRating']),
      preferences:
          (json['preferences'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          ) ??
          {},
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      googleMapsLink: json['googleMapsLink'] as String?,
    );
  }
}

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({Key? key, required this.propertyId})
    : super(key: key);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    _checkIfBookmarked();
  }

  Future<void> _fetchPropertyDetails() async {
    try {
      final propertyDoc =
          await _firestore
              .collection('room_listings')
              .doc(widget.propertyId)
              .get();

      if (propertyDoc.exists) {
        final data = propertyDoc.data() as Map<String, dynamic>;
        // Use the correct Firestore field for username: 'name'
        final ownerName = data['name']?.toString() ?? 'Unknown';

        double parseDouble(dynamic value) {
          if (value == null) return 0.0;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        }

        int parseInt(dynamic value, {int defaultValue = 0}) {
          if (value == null) return defaultValue;
          if (value is num) return value.toInt();
          if (value is String) return int.tryParse(value) ?? defaultValue;
          return defaultValue;
        }

        Map<String, String> convertPhotos(dynamic photos) {
          if (photos == null) return {};
          if (photos is Map) {
            return photos.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            );
          }
          return {};
        }

        final convertedData = {
          'title': data['title']?.toString() ?? '',
          'location': data['location']?.toString() ?? '',
          'availableFromDate':
              data['availableFromDate'] != null
                  ? _formatDate(data['availableFromDate'])
                  : '',
          'roomType': data['roomType']?.toString() ?? '',
          'flatSize': data['flatSize']?.toString() ?? '',
          'furnishing': data['furnishing']?.toString() ?? '',
          'bathroom':
              data['hasAttachedBathroom'] == true ? 'Attached' : 'Shared',
          'gender': data['genderComposition']?.toString() ?? '',
          'occupation': data['occupation']?.toString() ?? '',
          'monthlyRent': parseDouble(data['rent']),
          'securityDeposit': parseDouble(data['deposit']),
          'brokerage': parseDouble(data['brokerage']),
          'phone': data['phone']?.toString() ?? '',
          'email': data['email']?.toString() ?? '',
          'currentFlatmates': parseInt(
            data['currentFlatmates'],
            defaultValue: 1,
          ),
          'maxFlatmates': parseInt(data['maxFlatmates'], defaultValue: 2),
          'images': convertPhotos(data['uploadedPhotos']),
          'amenities': _getFacilities(data['facilities']),
          'description': data['description']?.toString() ?? '',
          'ownerName': ownerName,
          'ownerRating': 0.0,
          'googleMapsLink': data['locationUrl']?.toString() ?? '',
          'preferences': {
            'lookingFor': data['lookingFor']?.toString() ?? '',
            'foodPreference': data['foodPreference']?.toString() ?? '',
            'smokingPolicy': data['smokingPolicy']?.toString() ?? '',
            'drinkingPolicy': data['drinkingPolicy']?.toString() ?? '',
            'guestPolicy': data['guestsPolicy']?.toString() ?? '',
          },
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
        error = 'Error loading property details:  ${e.toString()}';
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        // Try to parse the string as a DateTime
        dateTime = DateTime.parse(date);
      } else {
        return '';
      }

      // Format as DD-MM-YYYY
      return '${dateTime.day.toString().padLeft(2, '0')}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  List<String> _getFacilities(dynamic facilities) {
    if (facilities == null) return [];

    if (facilities is Map<String, dynamic>) {
      // Filter only the true values and get their keys
      return facilities.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .toList();
    }

    if (facilities is List) {
      // If it's a list, convert all items to strings
      return facilities.map((item) => item.toString()).toList();
    }

    if (facilities is String) {
      // If it's a single string, return it as a single-item list
      return [facilities];
    }

    return [];
  }

  Future<void> _openGoogleMaps() async {
    if (propertyData.googleMapsLink == null ||
        propertyData.googleMapsLink!.isEmpty) {
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

    if (url.startsWith('maps.google.com') ||
        url.startsWith('www.google.com/maps')) {
      url = 'https://' + url;
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('maps.google.com') || url.contains('goo.gl/maps')) {
        url = 'https://' + url;
      } else {
        url =
            'https://www.google.com/maps/search/?api=1&query=' +
            Uri.encodeComponent(url);
      }
    }

    try {
      final Uri mapsUri = Uri.parse(url);
      bool launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final String googleMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(propertyData.location)}';
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

  List<String> get propertyImages =>
      !isLoading ? propertyData.images.values.toList() : [];
  List<String> get amenities => !isLoading ? propertyData.amenities : [];
  String _getInitials(String name) {
    // Trim the name to remove leading and trailing spaces
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'UK';
    
    // Split by one or more spaces to handle multiple spaces between words
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      // Make sure parts are not empty before accessing their characters
      final firstInitial = parts[0].isNotEmpty ? parts[0][0] : '';
      final secondInitial = parts[1].isNotEmpty ? parts[1][0] : '';
      if (firstInitial.isNotEmpty && secondInitial.isNotEmpty) {
        return '$firstInitial$secondInitial'.toUpperCase();
      }
    }
    
    // For single names or fallback
    return trimmedName.substring(0, trimmedName.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _toggleBookmark() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .get();
    final bookmarks =
        (userDoc.data()?['bookmarkedProperties'] as List?)?.cast<String>() ??
        [];
    final isBookmarkedNow = bookmarks.contains(widget.propertyId);
    if (isBookmarkedNow) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .update({
            'bookmarkedProperties': FieldValue.arrayRemove([widget.propertyId]),
          });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .set({
            'bookmarkedProperties': FieldValue.arrayUnion([widget.propertyId]),
          }, SetOptions(merge: true));
    }
    setState(() {
      isBookmarked = !isBookmarked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarkedNow ? 'Removed from wishlist!' : 'Added to wishlist!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkIfBookmarked() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .get();
    final bookmarks =
        (userDoc.data()?['bookmarkedProperties'] as List?)?.cast<String>() ??
        [];
    setState(() {
      isBookmarked = bookmarks.contains(widget.propertyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always use dark mode colors
    const darkBackground = Color(0xFF1A1A1A);
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;
    if (isLoading) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (error != null) {
      return Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: Text(error!, style: TextStyle(color: textPrimary))),
      );
    }
    return Scaffold(
      backgroundColor: darkBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyHeader(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildPricingInfo(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildPropertyDetails(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  if (propertyData.currentFlatmates > 0 ||
                      propertyData.maxFlatmates > 0 ||
                      propertyData.gender.isNotEmpty ||
                      propertyData.occupation.isNotEmpty) ...[
                    _buildFlatmateInfo(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (propertyData.preferences.values.any(
                    (value) => value.isNotEmpty,
                  )) ...[
                    _buildLifestylePreferences(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (amenities.isNotEmpty) ...[
                    _buildAmenities(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (propertyData.description.isNotEmpty) ...[
                    _buildDescription(),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                  if (propertyData.ownerName.isNotEmpty) ...[
                    _buildOwnerInfo(),
                    const SizedBox(height: BuddyTheme.spacingXl),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    // Always use dark mode colors
    const darkBackground = Color(0xFF1A1A1A);
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: darkCard,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(BuddyTheme.spacingXs),
        decoration: const BoxDecoration(
          color: Color(0xFF232323),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(BuddyTheme.spacingXs),
          decoration: const BoxDecoration(
            color: Color(0xFF232323),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? BuddyTheme.primaryColor : Colors.white,
            ),
            onPressed: () async {
              await _toggleBookmark();
              HapticFeedback.lightImpact();
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(BuddyTheme.spacingXs),
          decoration: const BoxDecoration(
            color: Color(0xFF232323),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async {
              final String propertyId = widget.propertyId;
              final String appLink =
                  'https://buddyapp.page.link/property?type=room&id=$propertyId';
              final String playStoreUrl =
                  'https://play.google.com/store/apps/details?id=com.yourcompany.buddy';
              final String shareText =
                  'Check out this property: ${propertyData.title}\nLocation: ${propertyData.location}\n\nView details: $appLink\n\nDon\'t have the app? Download here: $playStoreUrl';
              await Share.share(shareText, subject: propertyData.title);
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenImageGallery(
                          images: propertyImages,
                          initialIndex: currentImageIndex,
                        ),
                  ),
                );
              },
              child: PageView.builder(
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
            ),
            Positioned(
              bottom: BuddyTheme.spacingMd,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    propertyImages.asMap().entries.map((entry) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              currentImageIndex == entry.key
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

  Widget _buildPropertyHeader() {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;
    return Container(
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color: borderColor,
        ),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            propertyData.title,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: BuddyTheme.iconSizeSm,
                color: textSecondary,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              Expanded(
                child: Text(
                  propertyData.location,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: BuddyTheme.fontSizeMd,
                  ),
                ),
              ),
              if (propertyData.googleMapsLink != null &&
                  propertyData.googleMapsLink!.isNotEmpty)
                GestureDetector(
                  onTap: _openGoogleMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BuddyTheme.spacingSm,
                      vertical: BuddyTheme.spacingXs,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BuddyTheme.spacingSm,
                    vertical: BuddyTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: BuddyTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusSm,
                    ),
                  ),
                  child: Text(
                    propertyData.availableFrom.isEmpty
                        ? 'Available Now'
                        : 'Available from ${propertyData.availableFrom}',
                    style: const TextStyle(
                      fontSize: BuddyTheme.fontSizeSm,
                      color: BuddyTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (propertyData.googleMapsLink != null &&
                  propertyData.googleMapsLink!.isNotEmpty) ...[
                const SizedBox(width: BuddyTheme.spacingMd),
                GestureDetector(
                  onTap: _openGoogleMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BuddyTheme.spacingSm,
                      vertical: BuddyTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: BuddyTheme.primaryColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
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
                        const Text(
                          'View on Map',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeXs,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInfo() {
    // Always use dark mode colors
    const textColor = Colors.white;
    const subTextColor = Colors.white70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing Details',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: BuddyTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusMd,
                  ),
                ),
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Rent',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: subTextColor,
                      ),
                    ),
                    SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      '₹${propertyData.monthlyRent.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: BuddyTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusMd,
                  ),
                ),
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Deposit',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: subTextColor,
                      ),
                    ),
                    SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      '₹${propertyData.securityDeposit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (propertyData.brokerage > 0) ...[
          const SizedBox(height: BuddyTheme.spacingMd),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.45,
              decoration: BoxDecoration(
                color: BuddyTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
              ),
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Brokerage',
                    style: TextStyle(
                      fontSize: BuddyTheme.fontSizeSm,
                      color: subTextColor,
                    ),
                  ),
                  SizedBox(height: BuddyTheme.spacingXs),
                  Text(
                    '₹${propertyData.brokerage.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: BuddyTheme.fontSizeLg,
                      fontWeight: FontWeight.bold,
                      color: BuddyTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPropertyDetails() {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Details',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Row(
          children: [
            if (propertyData.roomType.isNotEmpty)
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.bed,
                  title: 'Room Type',
                  value: propertyData.roomType,
                  iconColor: BuddyTheme.primaryColor,
                ),
              ),
            if (propertyData.roomType.isNotEmpty &&
                propertyData.flatSize.isNotEmpty)
              const SizedBox(width: BuddyTheme.spacingMd),
            if (propertyData.flatSize.isNotEmpty)
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.home,
                  title: 'Flat Size',
                  value: propertyData.flatSize,
                  iconColor: BuddyTheme.accentColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Row(
          children: [
            if (propertyData.furnishing.isNotEmpty)
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.chair,
                  title: 'Furnishing',
                  value: propertyData.furnishing,
                  iconColor: BuddyTheme.secondaryColor,
                ),
              ),
            if (propertyData.furnishing.isNotEmpty &&
                propertyData.bathroom.isNotEmpty)
              const SizedBox(width: BuddyTheme.spacingMd),
            if (propertyData.bathroom.isNotEmpty)
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.bathtub,
                  title: 'Bathroom',
                  value: propertyData.bathroom,
                  iconColor: BuddyTheme.primaryColor,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlatmateInfo() {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flatmate Information',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.people,
                title: 'Current Flatmates',
                value: propertyData.currentFlatmates.toString(),
                iconColor: BuddyTheme.primaryColor,
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.group,
                title: 'Max Flatmates',
                value: propertyData.maxFlatmates.toString(),
                iconColor: BuddyTheme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Row(
          children: [
            if (propertyData.gender.isNotEmpty)
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.wc,
                  title: 'Gender',
                  value: propertyData.gender,
                  iconColor: BuddyTheme.secondaryColor,
                ),
              ),
            if (propertyData.gender.isNotEmpty &&
                propertyData.occupation.isNotEmpty)
              const SizedBox(width: BuddyTheme.spacingMd),
            if (propertyData.occupation.isNotEmpty)
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.work,
                  title: 'Occupation',
                  value: propertyData.occupation,
                  iconColor: BuddyTheme.primaryColor,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLifestylePreferences() {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lifestyle Preferences',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: BuddyTheme.fontSizeLg,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: borderColor,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Column(
            children: [
              if (propertyData.preferences['lookingFor']?.isNotEmpty ?? false)
                _buildPreferenceRow(
                  Icons.person_search,
                  'Looking For',
                  propertyData.preferences['lookingFor']!,
                ),
              if (propertyData.preferences['lookingFor']?.isNotEmpty ?? false)
                if (propertyData.preferences['foodPreference']?.isNotEmpty ??
                    false)
                  _buildPreferenceRow(
                    Icons.restaurant,
                    'Food Preference',
                    propertyData.preferences['foodPreference']!,
                  ),
              if (propertyData.preferences['foodPreference']?.isNotEmpty ??
                  false)
                if (propertyData.preferences['smokingPolicy']?.isNotEmpty ??
                    false)
                  _buildPreferenceRow(
                    Icons.smoking_rooms,
                    'Smoking Policy',
                    propertyData.preferences['smokingPolicy']!,
                  ),
              if (propertyData.preferences['smokingPolicy']?.isNotEmpty ??
                  false)
                if (propertyData.preferences['drinkingPolicy']?.isNotEmpty ??
                    false)
                  _buildPreferenceRow(
                    Icons.local_bar,
                    'Drinking Policy',
                    propertyData.preferences['drinkingPolicy']!,
                  ),
              if (propertyData.preferences['drinkingPolicy']?.isNotEmpty ??
                  false)
                if (propertyData.preferences['guestPolicy']?.isNotEmpty ??
                    false)
                  _buildPreferenceRow(
                    Icons.people_outline,
                    'Guest Policy',
                    propertyData.preferences['guestPolicy']!,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Facilities & Amenities',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: BuddyTheme.fontSizeLg,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: borderColor,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Wrap(
            spacing: BuddyTheme.spacingXs,
            runSpacing: BuddyTheme.spacingXs,
            children:
                amenities.map((amenity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BuddyTheme.spacingSm,
                      vertical: BuddyTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: BuddyTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                      border: Border.all(
                        color: BuddyTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      amenity,
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: BuddyTheme.fontSizeLg,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: borderColor,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          width: double.infinity,
          child: Text(
            propertyData.description,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo() {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;

    // Always use the ownerName from the database (propertyData.ownerName)
    final String ownerName =
        propertyData.ownerName.isNotEmpty ? propertyData.ownerName : 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listed By',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: BuddyTheme.fontSizeLg,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: BuddyTheme.primaryColor,
                child: Text(
                  _getInitials(ownerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: BuddyTheme.fontSizeLg,
                  ),
                ),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontSize: BuddyTheme.fontSizeMd,
                      ),
                    ),
                    if (propertyData.ownerRating > 0) ...[
                      const SizedBox(height: BuddyTheme.spacingXs),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: BuddyTheme.iconSizeSm,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: BuddyTheme.spacingXs),
                          Text(
                            propertyData.ownerRating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              fontSize: BuddyTheme.fontSizeSm,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    // Always use dark mode colors
    return Container(
      color: const Color(0xFF232323),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final Uri phoneUri = Uri(
                    scheme: 'tel',
                    path: propertyData.phone,
                  );
                  await launchUrl(phoneUri);
                },
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text('Call', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: propertyData.email,
                    query: 'subject=Enquiry about ${propertyData.email}',
                  );
                  await launchUrl(emailUri);
                },
                icon: const Icon(Icons.email, color: Colors.white),
                label: const Text('Email', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    // Always use dark mode colors
    const darkCard = Color(0xFF232323);
    const borderColor = Color(0xFF333333);
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;
    return Container(
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color: borderColor,
        ),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: Icon(icon, color: iconColor, size: BuddyTheme.iconSizeMd),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            title,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeXs,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXxs),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimary,
              fontSize: BuddyTheme.fontSizeMd,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(IconData icon, String title, String value) {
    // Always use dark mode colors
    const textPrimary = Colors.white;
    const textSecondary = Colors.white70;
    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            icon,
            color: BuddyTheme.primaryColor,
            size: BuddyTheme.iconSizeMd,
          ),
          const SizedBox(width: BuddyTheme.spacingMd),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: textPrimary,
                fontSize: BuddyTheme.fontSizeMd,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: textSecondary, fontSize: BuddyTheme.fontSizeMd),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}