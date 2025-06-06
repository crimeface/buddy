import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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
        final ownerEmail = data['email'] as String?;
        String ownerName = 'Unknown';

        if (ownerEmail != null) {
          final userQuery =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: ownerEmail)
                  .limit(1)
                  .get();

          if (userQuery.docs.isNotEmpty) {
            ownerName = userQuery.docs.first.data()['username'] ?? 'Unknown';
          }
        } // Helper functions for data conversion
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
          'currentFlatmates': parseInt(
            data['currentFlatmates'],
            defaultValue: 1,
          ),
          'maxFlatmates': parseInt(data['maxFlatmates'], defaultValue: 2),
          'images':
              data['uploadedPhotos'] is Map
                  ? Map<String, String>.from(
                    data['uploadedPhotos'].map(
                      (key, value) =>
                          MapEntry(key.toString(), value.toString()),
                    ),
                  )
                  : {},
          'amenities': _getFacilities(data['facilities']),
          'description': data['description']?.toString() ?? '',
          'ownerName': ownerName,
          'ownerRating': 0.0,
          'phone': data['phone']?.toString() ?? '',
          'email': data['email']?.toString() ?? '',
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
        error = 'Error loading property details: ${e.toString()}';
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
    if (name.isEmpty) return 'UK';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text(error!)));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: cardColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(BuddyTheme.spacingXs),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: BuddyTheme.textPrimaryColor,
          ),
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
              color:
                  isBookmarked
                      ? BuddyTheme.primaryColor
                      : BuddyTheme.textPrimaryColor,
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
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => Scaffold(
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
                                  controller: PageController(
                                    initialPage: currentImageIndex,
                                  ),
                                  itemCount: propertyImages.length,
                                  itemBuilder: (context, index) {
                                    return InteractiveViewer(
                                      minScale: 0.5,
                                      maxScale: 3.0,
                                      child: Center(
                                        child: Image.network(
                                          propertyImages[index],
                                          fit: BoxFit.contain,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
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
                                ),
                              ),
                            ],
                          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            propertyData.title,
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: BuddyTheme.iconSizeSm,
                color: textSecondary,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              Expanded(
                child: Text(
                  propertyData.location,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
                    style: TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing Details',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: BuddyTheme.textPrimaryColor,
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
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
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
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
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
      ],
    );
  }

  Widget _buildPropertyDetails() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : theme.cardColor;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : theme.cardColor;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lifestyle Preferences',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facilities & Amenities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
                      style: theme.textTheme.bodyMedium?.copyWith(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          width: double.infinity,
          child: Text(
            propertyData.description,
            style: theme.textTheme.bodyMedium?.copyWith(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listed By',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
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
                  _getInitials(propertyData.ownerName),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyData.ownerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);

    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (propertyData.phone.isNotEmpty) {
                    final Uri callUri = Uri.parse('tel:${propertyData.phone}');
                    try {
                      if (await canLaunchUrl(callUri)) {
                        await launchUrl(callUri);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not make call'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error making call'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingSm,
                  ),
                  side: const BorderSide(color: BuddyTheme.primaryColor),
                  foregroundColor: BuddyTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (propertyData.phone.isNotEmpty) {
                    final Uri smsUri = Uri.parse('sms:${propertyData.phone}');
                    try {
                      if (await canLaunchUrl(smsUri)) {
                        await launchUrl(smsUri);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not send message'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error sending message: ${e.toString()}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.message),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingSm,
                  ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(Colors.white.withOpacity(0.06), theme.cardColor)
            : Color.alphaBlend(Colors.black.withOpacity(0.04), theme.cardColor);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: BuddyTheme.fontSizeXs,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXxs),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
