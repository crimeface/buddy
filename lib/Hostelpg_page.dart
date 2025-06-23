import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class HostelPgPage extends StatefulWidget {
  final String selectedCity;
  const HostelPgPage({Key? key, required this.selectedCity}) : super(key: key);

  @override
  State<HostelPgPage> createState() => _HostelPgPageState();
}

class _HostelPgPageState extends State<HostelPgPage> {
  String _selectedLocation = 'All Cities';
  String _selectedPriceRange = 'All Prices';
  String _selectedRoomType = 'All Types';
  String _searchQuery = '';

  final List<String> _priceRanges = [
    'All Prices',
    '<\ 6000',
    '<\ 7500',
    '<\ 9000',
    '<\ 11000',
    '\ 12000+',
  ];

  final List<String> _roomTypes = [
    'All Types',
    '1 Bed Room (Private)',
    '2 Bed Room',
    '3 Bed Room',
    '4+ Bed Room',
  ];

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _hostels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = (widget.selectedCity.isNotEmpty && widget.selectedCity != 'Select Location') ? widget.selectedCity : 'All Cities';
    _fetchHostels();
  }

  Future<void> _fetchHostels() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      var query = FirebaseFirestore.instance
          .collection('hostel_listings')
          .where('visibility', isEqualTo: true);
      if (widget.selectedCity.isNotEmpty && widget.selectedCity != 'All Cities' && widget.selectedCity != 'Select Location') {
        query = query.where('city', isEqualTo: widget.selectedCity);
      }
      final querySnapshot = await query.get();

      final List<Map<String, dynamic>> loadedHostels = [];
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in querySnapshot.docs) {
        final v = doc.data();
        bool isExpired = false;

        // Check if listing is expired
        DateTime? expiryDate;
        if (v['expiryDate'] != null) {
          if (v['expiryDate'] is Timestamp) {
            expiryDate = (v['expiryDate'] as Timestamp).toDate();
          } else if (v['expiryDate'] is String) {
            expiryDate = DateTime.tryParse(v['expiryDate']);
          }
        }

        // If expired, mark for visibility update
        if (expiryDate != null && expiryDate.isBefore(now)) {
          isExpired = true;
          if (v['visibility'] == true) {
            // Only update if currently visible
            batch.update(doc.reference, {'visibility': false});
          }
        }

        // Only add to display list if not expired and visible
        if (!isExpired && v['visibility'] == true) {
          loadedHostels.add({
            ...v,
            'key': doc.id,
            // Aliases for filtering and display
            'location': v['address'] ?? '',
            'type': v['hostelType'] ?? '',
            'amenities': v['facilities'] ?? [],
            'imageUrl':
                (v['uploadedPhotos'] is Map &&
                        (v['uploadedPhotos'] as Map).containsKey(
                          'Building Front',
                        ))
                    ? (v['uploadedPhotos'] as Map)['Building Front']
                    : (v['uploadedPhotos'] is Map &&
                        (v['uploadedPhotos'] as Map).isNotEmpty)
                    ? (v['uploadedPhotos'] as Map).values.first
                    : (v['uploadedPhotos'] is List &&
                        (v['uploadedPhotos'] as List).isNotEmpty)
                    ? v['uploadedPhotos'][0]
                    : '',
            // ... existing fields ...
            'createdAt': v['createdAt'] ?? '',
          });
        }
      }

      // Sort hostels by createdAt timestamp, newest first
      loadedHostels.sort((a, b) {
        var aTime = a['createdAt'];
        var bTime = b['createdAt'];

        // Convert to DateTime if needed
        if (aTime is Timestamp) {
          aTime = aTime.toDate();
        } else if (aTime is String) {
          aTime = DateTime.tryParse(aTime);
        }

        if (bTime is Timestamp) {
          bTime = bTime.toDate();
        } else if (bTime is String) {
          bTime = DateTime.tryParse(bTime);
        }

        // Handle null cases
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        // Sort in descending order (newest first)
        return bTime.compareTo(aTime);
      });

      // Commit all visibility updates in one batch
      try {
        await batch.commit();
      } catch (e) {
        print('Error updating expired listings: $e');
      }

      setState(() {
        _hostels = loadedHostels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hostels = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load hostels: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _priceInRange(String priceStr, String range) {
    try {
      final price =
          int.tryParse(priceStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      if (range == 'All Prices') return true;
      if (range.contains('+')) {
        // e.g., '12000+'
        final min =
            int.tryParse(RegExp(r'(\d+)').firstMatch(range)?.group(1) ?? '0') ??
            0;
        return price > min;
      } else {
        // e.g., '< 6000', '< 7500', etc.
        final max =
            int.tryParse(RegExp(r'(\d+)').firstMatch(range)?.group(1) ?? '0') ??
            0;
        return price <= max;
      }
    } catch (_) {}
    return true;
  }

  List<Map<String, dynamic>> get _filteredHostels {
    return _hostels.where((hostel) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          query.isEmpty ||
          (hostel['title']?.toString().toLowerCase().contains(query) ??
              false) ||
          (hostel['location']?.toString().toLowerCase().contains(query) ??
              false) ||
          ((hostel['amenities'] is List)
              ? (hostel['amenities'] as List).any(
                (a) => a.toString().toLowerCase().contains(query),
              )
              : false);
      final matchesLocation =
          _selectedLocation == 'All Cities' ||
          (hostel['location']?.toString().toLowerCase().trim().contains(
                _selectedLocation.toLowerCase().trim(),
              ) ??
              false);
      final matchesType =
          _selectedRoomType == 'All Types' ||
          ((hostel['roomTypes'] is Map &&
                  (hostel['roomTypes'] as Map)[_selectedRoomType] == true) ||
              (hostel['roomTypes'] is List &&
                  (hostel['roomTypes'] as List).contains(_selectedRoomType)));
      final matchesPrice =
          _selectedPriceRange == 'All Prices' ||
          _priceInRange(
            hostel['startingAt']?.toString() ?? '',
            _selectedPriceRange,
          );
      return matchesSearch && matchesLocation && matchesType && matchesPrice;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    // Force dark mode UI for all users
    final Color scaffoldBg = Colors.black;
    final Color primaryColor = const Color(0xFF4A90E2); // blue accent for highlights
    final Color accentColor = const Color(0xFF4A90E2);
    final Color cardColor = const Color(0xFF23262F);
    final Color textPrimary = Colors.white;
    final Color textSecondary = Colors.white70;
    final Color textLight = Colors.white38;
    final Color borderColor = Colors.white12;
    final Color successColor = const Color(0xFF81C784);
    final Color warningColor = const Color(0xFFFFB74D);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 2));
          },
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Your',
                        style: Theme.of(context).textTheme.displaySmall!.copyWith(
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Perfect Hostel / PG',
                        style: Theme.of(context).textTheme.displayMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BuddyTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor, // Always dark
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white70,
                      decoration: const InputDecoration(
                        hintText: 'Search hostels, amenities, or locations...',
                        hintStyle: TextStyle(color: Colors.white),
                        prefixIcon: Icon(Icons.search, color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(BuddyTheme.spacingMd),
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter chips
                  Row(
                    children: [
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
                      const SizedBox(width: 12),
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
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Section header
                  Text(
                    'Available Hostels / PG',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  else if (_filteredHostels.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No Hostel/PGs found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._filteredHostels
                        .map(
                          (hostel) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildHostelCard(
                              hostel,
                              cardColor,
                              borderColor,
                              textLight,
                              textPrimary,
                              textSecondary,
                              accentColor,
                              primaryColor,
                              scaffoldBg,
                              successColor,
                              warningColor,
                            ),
                          ),
                        )
                        .toList(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildHostelCard(
    Map<String, dynamic> hostel,
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: hostel['imageUrl'] ?? '',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: borderColor,
                        highlightColor: cardColor,
                        child: Container(color: borderColor),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: borderColor,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: textLight,
                          size: 48,
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
                  hostel['title'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hostel['address'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/hostelpg_details',
                            arguments: {'hostelId': hostel['key']},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: const TextStyle(
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
