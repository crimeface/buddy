import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
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

  // Updated sample data structure matching your fields
  final List<Map<String, dynamic>> _allServices = [
    {
      'userId': 'user1',
      'serviceType': 'Café',
      'serviceName': 'Cafe Mocha',
      'location': 'MG Road, City Center',
      'mapLink': 'https://maps.google.com/cafe-mocha',
      'description':
          'A cozy cafe with great coffee and snacks, perfect for studying and meetings.',
      'contact': '+91 98765 43210',
      'email': 'info@cafemocha.com',
      'openingTime': '7:00 AM',
      'closingTime': '11:00 PM',
      'offDay': 'None',
      'createdAt': '2024-01-15T10:30:00.000Z',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
      // Café-specific fields
      'cuisineType': 'Continental',
      'hasSeating': true,
      'priceRange': '₹100-300',
      'hasWifi': true,
      'hasPowerSockets': true,
      'rating': 4.5,
      'reviews': 120,
      'distance': '0.5 km',
    },
    {
      'userId': 'user2',
      'serviceType': 'Library',
      'serviceName': 'City Study Hub',
      'location': 'Near University Gate, College Road',
      'mapLink': 'https://maps.google.com/city-study-hub',
      'description':
          'Modern library with excellent study environment and high-speed internet.',
      'contact': '+91 98765 43211',
      'email': 'contact@citystudyhub.com',
      'openingTime': '8:00 AM',
      'closingTime': '10:00 PM',
      'offDay': 'Sunday',
      'createdAt': '2024-01-10T09:00:00.000Z',
      'imageUrl':
          'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=400&q=80',
      // Library-specific fields
      'libraryType': 'Study Center',
      'seatingCapacity': '150',
      'acStatus': 'Full AC',
      'charges': '₹200',
      'chargeType': 'Monthly',
      'hasInternet': true,
      'hasStudyCabin': true,
      'rating': 4.2,
      'reviews': 85,
      'distance': '1.2 km',
    },
    {
      'userId': 'user3',
      'serviceType': 'Mess',
      'serviceName': 'Home Food Mess',
      'location': 'Hostel Area, Student Colony',
      'mapLink': 'https://maps.google.com/home-food-mess',
      'description':
          'Homely food with variety of regional cuisines at affordable prices.',
      'contact': '+91 98765 43212',
      'email': 'orders@homefoodmess.com',
      'openingTime': '7:00 AM',
      'closingTime': '10:00 PM',
      'offDay': 'None',
      'createdAt': '2024-01-20T08:00:00.000Z',
      'imageUrl':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=400&q=80',
      // Mess-specific fields
      'foodType': 'Vegetarian',
      'monthlyPrice': '₹3500',
      'mealTimings': 'Breakfast: 8AM, Lunch: 1PM, Dinner: 8PM',
      'hasHomeDelivery': true,
      'hasTiffinService': true,
      'rating': 4.7,
      'reviews': 340,
      'distance': '0.8 km',
    },
    {
      'userId': 'user4',
      'serviceType': 'Other',
      'serviceName': 'QuickFix Repair Services',
      'location': 'Market Street, Commercial Area',
      'mapLink': 'https://maps.google.com/quickfix-repair',
      'description':
          'Professional repair services for electronics, appliances, and gadgets.',
      'contact': '+91 98765 43213',
      'email': 'service@quickfixrepair.com',
      'openingTime': '9:00 AM',
      'closingTime': '8:00 PM',
      'offDay': 'Sunday',
      'createdAt': '2024-01-25T11:00:00.000Z',
      'imageUrl':
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=400&q=80',
      // Other-specific fields
      'shortDescription': 'Fast and reliable repair services',
      'pricing': '₹150-500 per service',
      'serviceTypeOther': 'Electronics Repair',
      'usefulness': 'Essential for gadget maintenance and repairs',
      'rating': 4.3,
      'reviews': 92,
      'distance': '0.3 km',
    },
  ];

  List<Map<String, dynamic>> get _filteredServices {
    return _allServices.where((service) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          service['serviceName'].toString().toLowerCase().contains(query) ||
          service['serviceType'].toString().toLowerCase().contains(query) ||
          service['description'].toString().toLowerCase().contains(query);

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

  String _getServiceTags(Map<String, dynamic> service) {
    List<String> tags = [];

    switch (service['serviceType']) {
      case 'Library':
        if (service['hasInternet'] == true) tags.add('WiFi');
        if (service['hasStudyCabin'] == true) tags.add('Study Cabin');
        if (service['acStatus'] == 'Full AC') tags.add('AC');
        tags.add(service['libraryType'] ?? 'Library');
        break;
      case 'Café':
        if (service['hasWifi'] == true) tags.add('WiFi');
        if (service['hasPowerSockets'] == true) tags.add('Power Outlets');
        if (service['hasSeating'] == true) tags.add('Seating');
        tags.add(service['cuisineType'] ?? 'Food');
        break;
      case 'Mess':
        tags.add(service['foodType'] ?? 'Food');
        if (service['hasHomeDelivery'] == true) tags.add('Home Delivery');
        if (service['hasTiffinService'] == true) tags.add('Tiffin Service');
        break;
      case 'Other':
        tags.add(service['serviceTypeOther'] ?? 'Service');
        break;
    }

    return tags.join(' • ');
  }

  String _getServiceOffer(Map<String, dynamic> service) {
    switch (service['serviceType']) {
      case 'Library':
        return 'First day free trial';
      case 'Café':
        return '20% off on orders above ₹300';
      case 'Mess':
        return 'Free home delivery';
      case 'Other':
        return '10% off on first service';
      default:
        return '';
    }
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
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
            // Here you would typically reload data from your backend
          },
          color: BuddyTheme.primaryColor,
          child: SingleChildScrollView(
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
                  _buildCategoryFilter(cardColor, textPrimary, borderColor),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildQuickStats(
                    cardColor,
                    accentColor,
                    successColor,
                    warningColor,
                    borderColor,
                    textSecondary,
                  ),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildSectionHeader('Available Services', textPrimary),
                  const SizedBox(height: BuddyTheme.spacingMd),
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

  Widget _buildQuickStats(
    Color cardColor,
    Color accentColor,
    Color successColor,
    Color warningColor,
    Color borderColor,
    Color textSecondary,
  ) {
    final openServices = _allServices.where((s) => _isServiceOpen(s)).length;
    final servicesWithOffers =
        _allServices.length; // All services have offers in this example

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${_allServices.length}',
            'Total\nServices',
            accentColor,
            textSecondary,
          ),
          Container(width: 1, height: 40, color: borderColor),
          _buildStatItem(
            '$openServices',
            'Open\nNow',
            successColor,
            textSecondary,
          ),
          Container(width: 1, height: 40, color: borderColor),
          _buildStatItem(
            '$servicesWithOffers',
            'Special\nOffers',
            warningColor,
            textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String number,
    String label,
    Color color,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
    final isOpen = _isServiceOpen(service);
    final tags = _getServiceTags(service);
    final offer = _getServiceOffer(service);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${service['serviceName']} details')),
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
                // Status badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? successColor : warningColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpen ? 'OPEN' : 'CLOSED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
                // Rating badge (if available)
                if (service['rating'] != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            service['rating'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                      if (service['priceRange'] != null ||
                          service['charges'] != null ||
                          service['monthlyPrice'] != null ||
                          service['pricing'] != null)
                        Text(
                          service['priceRange'] ??
                              service['charges'] ??
                              service['monthlyPrice'] ??
                              service['pricing'] ??
                              '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
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
                  const SizedBox(height: 12),
                  Text(
                    service['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        tags,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  if (offer.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.1),
                            Colors.deepOrange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              offer,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle visit/enquiry - you can launch maps here
                          },
                          icon: const Icon(Icons.directions_outlined, size: 18),
                          label: const Text('Get Directions'),
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
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Handle call - you can launch phone dialer here
                          // Example: launch('tel:${service['contact']}');
                        },
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: BorderSide(color: accentColor),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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