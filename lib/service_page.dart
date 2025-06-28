import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'display pages/service_details.dart';
import 'theme.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _selectedCategory = 'All Services';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All Services',
    'Library',
    'Café',
    'Mess',
    'Other',
  ];

  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      var query = FirebaseFirestore.instance
          .collection('service_listings')
          .where('visibility', isEqualTo: true);
      final querySnapshot = await query.get();

      final List<Map<String, dynamic>> loaded = [];
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        DateTime? expiryDate;

        // Handle different expiry date formats
        if (data['expiryDate'] != null) {
          if (data['expiryDate'] is Timestamp) {
            expiryDate = (data['expiryDate'] as Timestamp).toDate();
          } else if (data['expiryDate'] is String) {
            expiryDate = DateTime.tryParse(data['expiryDate']);
          }
        }

        // If expired, update visibility to false
        if (expiryDate != null && expiryDate.isBefore(now)) {
          batch.update(doc.reference, {'visibility': false});
          continue; // Skip adding to loaded list since it's expired
        }

        // Only add to the list if not expired
        if (expiryDate != null && expiryDate.isAfter(now)) {
          data['key'] = doc.id;
          // Defensive mapping for images
          data['imageUrl'] =
              data['coverPhoto'] ??
              (data['additionalPhotos'] is List &&
                      (data['additionalPhotos'] as List).isNotEmpty
                  ? data['additionalPhotos'][0]
                  : (data['imageUrl'] ?? ''));
          loaded.add(data);
        }
      }

      // Commit all visibility updates
      await batch.commit();

      // Sort services by createdAt timestamp, newest first
      loaded.sort((a, b) {
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

        // Handle null cases and compare
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _services = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _services = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load services: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _services.where((service) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          (service['serviceName']?.toString().toLowerCase().contains(query) ??
              false) ||
          (service['serviceType']?.toString().toLowerCase().contains(query) ??
              false) ||
          (service['description']?.toString().toLowerCase().contains(query) ??
              false);
      final matchesCategory =
          _selectedCategory == 'All Services' ||
          service['serviceType'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  bool _isServiceOpen(Map<String, dynamic> service) {
    final now = TimeOfDay.now();
    final openingTime = _parseTimeString(service['openingTime']);
    final closingTime = _parseTimeString(service['closingTime']);
    final offDay = service['offDay'];

    // Check if today is off day
    final today = DateTime.now().weekday;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (offDay == dayNames[today - 1]) {
      return false;
    }

    if (openingTime != null && closingTime != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = openingTime.hour * 60 + openingTime.minute;
      final closeMinutes = closingTime.hour * 60 + closingTime.minute;

      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    }

    return true; // Default to open if times aren't parsed correctly
  }

  TimeOfDay? _parseTimeString(String? timeString) {
    if (timeString == null) return null;

    try {
      final cleanTime = timeString.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = cleanTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // Handle AM/PM
        if (timeString.toUpperCase().contains('PM') && hour != 12) {
          hour += 12;
        } else if (timeString.toUpperCase().contains('AM') && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $timeString');
    }

    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchServices,
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
                            textLight,
                            textPrimary,
                            borderColor,
                          ),
                          const SizedBox(height: BuddyTheme.spacingMd),
                          _buildCategoryFilter(
                            cardColor,
                            textPrimary,
                            borderColor,
                          ),
                          const SizedBox(height: BuddyTheme.spacingLg),
                          _buildSectionHeader(
                            'Available Services',
                            textPrimary,
                          ),
                          const SizedBox(height: BuddyTheme.spacingMd),
                          if (_filteredServices.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'No services found.',
                                  style: TextStyle(color: textSecondary),
                                ),
                              ),
                            )
                          else
                            ..._filteredServices
                                .map(
                                  (service) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: BuddyTheme.spacingMd,
                                    ),
                                    child: _buildServiceCard(
                                      service,
                                      cardColor,
                                      borderColor,
                                      textLight,
                                      textPrimary,
                                      textSecondary,
                                      accentColor,
                                      primaryColor,
                                      successColor,
                                      warningColor,
                                      Theme.of(context).scaffoldBackgroundColor,
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
    );
  }

  Widget _buildHeader(BuildContext context, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: Theme.of(
            context,
          ).textTheme.displaySmall!.copyWith(color: labelColor),
        ),
        Text(
          'Local Services',
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
    Color textLight,
    Color textPrimary,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
        decoration: InputDecoration(
          hintText: 'Search libraries, cafes, mess, services...',
          hintStyle: TextStyle(
            color: textLight,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search_outlined, color: textLight, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        style: TextStyle(color: textPrimary),
      ),
    );
  }

  Widget _buildCategoryFilter(
    Color cardColor,
    Color textPrimary,
    Color borderColor,
  ) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(
              right: index == _categories.length - 1 ? 0 : 12,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? BuddyTheme.primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? BuddyTheme.primaryColor : borderColor,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: BuddyTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    );
  }

  Widget _buildServiceCard(
    Map<String, dynamic> service,
    Color cardColor,
    Color borderColor,
    Color textLight,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    Color primaryColor,
    Color successColor,
    Color warningColor,
    Color backgroundColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ServiceDetailsScreen(serviceId: service['key']),
          ),
        );
      },
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
                    imageUrl: service['imageUrl'],
                    height: 200,
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
                // Service type badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service['serviceType'].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service['serviceName'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['serviceType'],
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          service['location'],
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (service['distance'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          service['distance'],
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service['openingTime']} - ${service['closingTime']}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const Spacer(),
                      if (service['reviews'] != null)
                        Text(
                          '(${service['reviews']} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: textLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  if (service['offDay'] != 'None') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 16,
                          color: warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Closed on ${service['offDay']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ServiceDetailsScreen(
                                      serviceId: service['key'],
                                    ),
                              ),
                            );
                          },
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
