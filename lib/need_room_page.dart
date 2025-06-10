import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';

class NeedRoomPage extends StatefulWidget {
  const NeedRoomPage({super.key});

  @override
  State<NeedRoomPage> createState() => _NeedRoomPageState();
}

class _NeedRoomPageState extends State<NeedRoomPage> with RouteAware {
  String _selectedLocation = 'All Cities';
  String _selectedPriceRange = 'All Prices';
  String _selectedRoomType = 'All Types';
  String _selectedFlatSize = 'All Sizes';
  String _selectedGenderPreference = 'All';
  String _searchQuery = '';

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    final parts = dateString.split('T')[0].split('-');
    if (parts.length != 3) return dateString;
    return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
  }

  final List<String> _locations = [
    'All Cities',
    'Manhattan, New York',
    'Brooklyn Heights, NY',
    'Long Island City, NY',
    'Upper East Side, NY',
  ];

  final List<String> _priceRanges = [
    'All Prices',
    '> \₹3000',
    '> \₹5000',
    '> \₹7000',
    '> \₹9000',
    '\₹9000+',
  ];

  final List<String> _roomTypes = [
    'All Types', // Add this for proper filtering
    'Private',
    'Shared Room',
  ];

  final List<String> _flatSizes = [
    '1RK',
    '1BHK',
    '2BHK',
    '3BHK',
    '4BHK',
    '5BHK',
  ];

  final List<String> _genderPreferences = ['Male Only', 'Female Only', 'Mixed'];

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _rooms = []; // <-- Now fetched from Firebase
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _fetchRooms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // When returning back to this page
    _initializeFilters();
  }

  void _initializeFilters() {
    if (mounted) {
      setState(() {
        _selectedLocation = 'All Cities';
        _selectedPriceRange = 'All Prices';
        _selectedRoomType = 'All Types';
        _selectedFlatSize = 'All Sizes';
        _selectedGenderPreference = 'All';
        _searchQuery = '';
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
        }
      });
    }
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final now = DateTime.now();
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('room_listings')
              .where('visibility', isEqualTo: true)
              .get();

      final List<Map<String, dynamic>> loadedRooms = [];
      for (var doc in querySnapshot.docs) {
        final room = doc.data();
        // Only show if not expired
        if (room['expiryDate'] != null &&
            DateTime.tryParse(room['expiryDate']) != null &&
            DateTime.parse(room['expiryDate']).isAfter(now)) {
          room['id'] = doc.id;
          room['key'] = doc.id;
          loadedRooms.add(room);
        }
      }
      setState(() {
        _rooms = loadedRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _rooms = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load rooms: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredRooms {
    print('Filtering ${_rooms.length} rooms');
    return _rooms.where((room) {
      final query = _searchQuery.toLowerCase();

      if (query.isNotEmpty) {
        print('Applying search filter: $query');
      }

      final matchesSearch =
          query.isEmpty ||
          (room['title']?.toString().toLowerCase().contains(query) ?? false) ||
          (room['location']?.toString().toLowerCase().contains(query) ??
              false) ||
          ((room['facilities'] is Map)
              ? (room['facilities'] as Map).keys.any(
                (a) => a.toString().toLowerCase().contains(query),
              )
              : false);

      final matchesLocation =
          _selectedLocation == 'All Cities' ||
          (room['location']?.toString().toLowerCase().contains(
                _selectedLocation.toLowerCase(),
              ) ??
              false);

      final matchesType =
          _selectedRoomType == 'All Types' ||
          (room['roomType']?.toString().toLowerCase() ==
              _selectedRoomType.toLowerCase());

      final matchesFlatSize =
          _selectedFlatSize == 'All Sizes' ||
          (room['flatSize']?.toString().toLowerCase() ==
              _selectedFlatSize.toLowerCase());

      final matchesGender =
          _selectedGenderPreference == 'All' ||
          (room['genderComposition']?.toString().toLowerCase() ==
              _selectedGenderPreference.toLowerCase());

      final matchesPrice =
          _selectedPriceRange == 'All Prices' ||
          _priceInRange(room['rent'] ?? '', _selectedPriceRange);

      return matchesSearch &&
          matchesLocation &&
          matchesType &&
          matchesFlatSize &&
          matchesGender &&
          matchesPrice;
    }).toList();
  }

  bool _priceInRange(String priceStr, String range) {
    try {
      final price =
          int.tryParse(priceStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      if (range == '> \₹3000') return price <= 3000;
      if (range == '> \₹5000') return price <= 5000;
      if (range == '> \₹7000') return price <= 7000;
      if (range == '> \₹9000') return price <= 9000;
      if (range == '\₹9000+') return price > 9000;
    } catch (_) {}
    return true;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // When navigating to a new page
    _initializeFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? const Color(0xFF90CAF9) : const Color(0xFF2D3748);
    final Color accentColor =
        isDark ? const Color(0xFF64B5F6) : const Color(0xFF4299E1);
    final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
    final Color textSecondary =
        isDark ? Colors.white70 : const Color(0xFF718096);
    final Color textLight = isDark ? Colors.white38 : const Color(0xFFA0AEC0);
    final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final Color successColor =
        isDark ? const Color(0xFF81C784) : const Color(0xFF48BB78);
    final Color warningColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFED8936);
    final Color inputFillColor =
        isDark ? const Color(0xFF23262F) : const Color(0xFFF1F5F9);
    final Color labelColor = textPrimary;
    final Color hintColor = isDark ? Colors.white38 : const Color(0xFFA0AEC0);

    return WillPopScope(
      onWillPop: () async {
        _initializeFilters();
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              print('Refreshing room listings...');
              await _fetchRooms();
              return;
            },
            color: BuddyTheme.primaryColor,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, textPrimary),
                            const SizedBox(height: BuddyTheme.spacingLg),
                            _buildSearchSection(
                              cardColor,
                              inputFillColor,
                              labelColor,
                              hintColor,
                              textLight,
                              textPrimary,
                              accentColor,
                              borderColor,
                            ),
                            const SizedBox(height: BuddyTheme.spacingLg),
                            _buildSectionHeader(
                              'Available Properties',
                              textPrimary,
                              accentColor,
                            ),
                            const SizedBox(height: BuddyTheme.spacingMd),
                            ..._filteredRooms
                                .map(
                                  (room) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: BuddyTheme.spacingMd,
                                    ),
                                    child: _buildRoomCard(
                                      room,
                                      cardColor,
                                      borderColor,
                                      textLight,
                                      textPrimary,
                                      textSecondary,
                                      accentColor,
                                      primaryColor,
                                      Theme.of(context).scaffoldBackgroundColor,
                                      successColor,
                                      warningColor,
                                    ),
                                  ),
                                )
                                .toList(),
                            const SizedBox(height: BuddyTheme.spacingMd),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Your',
          style: Theme.of(
            context,
          ).textTheme.displaySmall!.copyWith(color: labelColor),
        ),
        Text(
          'Dream Room',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: BuddyTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(
    Color cardColor,
    Color inputFillColor,
    Color hintColor,
    Color labelColor,
    Color textLight,
    Color textPrimary,
    Color accentColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(color: labelColor),
            decoration: InputDecoration(
              hintText: 'Search neighborhoods, amenities, or landmarks...',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(Icons.search, color: labelColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(BuddyTheme.spacingMd),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Location',
                _selectedLocation,
                _locations,
                (value) {
                  setState(() => _selectedLocation = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Budget',
                _selectedPriceRange,
                _priceRanges,
                (value) {
                  setState(() => _selectedPriceRange = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Room Type',
                _selectedRoomType,
                _roomTypes,
                (value) {
                  setState(() => _selectedRoomType = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Flat Size',
                _selectedFlatSize,
                ['All Sizes', ..._flatSizes],
                (value) {
                  setState(() => _selectedFlatSize = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Gender',
                _selectedGenderPreference,
                ['All', ..._genderPreferences],
                (value) {
                  setState(() => _selectedGenderPreference = value);
                },
                cardColor,
                textPrimary,
                borderColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
  // Remove unused method
  // Widget _buildRoomListings() { ... }

  Widget _buildFilterChip(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
    Color cardColor,
    Color labelColor,
    Color borderColor,
  ) {
    final isSelected = value != options.first;
    return GestureDetector(
      onTap:
          () => _showFilterBottomSheet(
            context,
            label,
            options,
            value,
            onChanged,
            cardColor,
            labelColor,
            borderColor,
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BuddyTheme.spacingSm,
          vertical: BuddyTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? BuddyTheme.primaryColor : cardColor,
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
          border: Border.all(
            color: isSelected ? BuddyTheme.primaryColor : borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == options.first ? label : value,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: isSelected ? BuddyTheme.textLightColor : labelColor,
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingXxs),
            Icon(
              Icons.keyboard_arrow_down,
              size: BuddyTheme.iconSizeSm,
              color: isSelected ? BuddyTheme.textLightColor : labelColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color textPrimary,
    Color accentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
  // Removed unused _buildRoomListings method

  Widget _buildRoomCard(
    Map<String, dynamic> room,
    Color cardColor,
    Color borderColor,
    Color textLight,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    Color primaryColor,
    Color backgroundColor,
    Color successColor,
    Color warningColor,
  ) {
    // Get the image URL from the firstPhoto field or try to find one from uploadedPhotos
    String? imageUrl = room['firstPhoto'] as String?;
    if (imageUrl == null && room['uploadedPhotos'] != null) {
      final photos = room['uploadedPhotos'];
      if (photos is Map<String, dynamic>) {
        // New format with categories
        for (final categoryPhotos in photos.values) {
          if (categoryPhotos is List && categoryPhotos.isNotEmpty) {
            imageUrl = categoryPhotos[0] as String;
            break;
          }
        }
      } else if (photos is List) {
        // Old format - direct list of photos
        if (photos.isNotEmpty) {
          imageUrl = photos[0].toString();
        }
      }
    }
    // Fallback to imageUrl field if no photos found
    if (imageUrl == null &&
        room['imageUrl'] != null &&
        room['imageUrl'].toString().isNotEmpty) {
      imageUrl = room['imageUrl'];
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with availability badge
          Stack(
            children: [
              // Property image
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 200,
                          color: borderColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 200,
                          color: borderColor,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: textLight,
                            size: 48,
                          ),
                        ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Icon(Icons.image, color: textLight, size: 48),
                ),

              // Available Now badge
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property name
                    Expanded(
                      child: Text(
                        room['title'] ?? 'Property Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '\₹${room['rent'] ?? '120'}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: '/mo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room['location'] ?? 'Location',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    // Room type tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(
                          4,
                        ), // Changed from 16 to 4 for rectangular shape
                      ),
                      child: Text(
                        room['roomType'] ?? 'Shared',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Flat size tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          4,
                        ), // Changed from 16 to 4 for rectangular shape
                        border: Border.all(
                          color: textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        room['flatSize'] ?? '2 Beds',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // View Details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/propertyDetails',
                        arguments: {'propertyId': room['id']},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    Function(String) onChanged,
    Color cardColor,
    Color labelColor,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Select $title',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: labelColor),
                      ),
                    ],
                  ),
                ),
                ...options.map(
                  (option) => ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing:
                        currentValue == option
                            ? Icon(
                              Icons.check_rounded,
                              color: BuddyTheme.primaryColor,
                            )
                            : null,
                    onTap: () {
                      onChanged(option);
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
    );
  }
}

class PropertyDetailsPage extends StatefulWidget {
  final String propertyKey;
  const PropertyDetailsPage({Key? key, required this.propertyKey})
    : super(key: key);

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  Map<String, dynamic>? _roomDetails;
  bool _isLoading = true;

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    final parts = dateString.split('T')[0].split('-');
    if (parts.length != 3) return dateString;
    return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
  }

  @override
  void initState() {
    super.initState();
    _fetchRoomDetails();
  }

  Future<void> _fetchRoomDetails() async {
    final ref = FirebaseDatabase.instance
        .ref()
        .child('room_listings')
        .child(widget.propertyKey);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      setState(() {
        _roomDetails = Map<String, dynamic>.from(snapshot.value as Map);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? const Color(0xFF90CAF9) : const Color(0xFF2D3748);
    final Color accentColor =
        isDark ? const Color(0xFF64B5F6) : const Color(0xFF4299E1);
    final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
    final Color textSecondary =
        isDark ? Colors.white70 : const Color(0xFF718096);
    final Color textLight = isDark ? Colors.white38 : const Color(0xFFA0AEC0);
    final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: BuddyTheme.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _roomDetails != null
              ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_roomDetails!['title']?.isNotEmpty ?? false)
                            Text(
                              _roomDetails!['title']!,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          if (_roomDetails!['location']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: textLight,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _roomDetails!['location']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_roomDetails!['availableFromDate']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Available from ${_formatDate(_roomDetails!['availableFromDate'].toString())}',
                              style: TextStyle(
                                fontSize: 13,
                                color: textLight,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (_roomDetails!['rent']?.isNotEmpty ?? false)
                                Text(
                                  '₹${_roomDetails!['rent']}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (_roomDetails!['roomType']?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(width: 16),
                                Text(
                                  _roomDetails!['roomType']!,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_roomDetails!['flatSize']?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(width: 16),
                                Text(
                                  _roomDetails!['flatSize']!,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_roomDetails!['facilities'] != null &&
                              (_roomDetails!['facilities'] as Map).entries
                                  .where((e) => e.value == true)
                                  .isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  (_roomDetails!['facilities'] as Map).entries
                                      .where((e) => e.value == true)
                                      .map(
                                        (e) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: BuddyTheme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: borderColor,
                                            ),
                                          ),
                                          child: Text(
                                            e.key,
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                          if (_roomDetails!['description']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _roomDetails!['description']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle booking action
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              : Center(
                child: Text(
                  'Property not found.',
                  style: TextStyle(fontSize: 18, color: textPrimary),
                ),
              ),
    );
  }
}