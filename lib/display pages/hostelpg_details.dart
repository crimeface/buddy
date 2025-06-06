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

class HostelData {
  final String title;
  final String address;
  final String availableFromDate;
  final String bookingMode;
  final String contactPerson;
  final String description;
  final String drinkingPolicy;
  final String email;
  final Map<String, bool> facilities;
  final String foodType;
  final String guestsPolicy;
  final bool hasEntryTimings;
  final String hostelFor;
  final String hostelType;
  final String landmark;
  final String mapLink;
  final String minimumStay;
  final String offers;
  final String petsPolicy;
  final String phone;
  final Map<String, bool> roomTypes;
  final String selectedPlan;
  final String smokingPolicy;
  final String specialFeatures;
  final double startingAt;
  final String entryTime;
  final Map<String, String> uploadedPhotos;
  final bool visibility;

  HostelData({
    required this.title,
    required this.address,
    required this.availableFromDate,
    required this.bookingMode,
    required this.contactPerson,
    required this.description,
    required this.drinkingPolicy,
    required this.email,
    required this.facilities,
    required this.foodType,
    required this.guestsPolicy,
    required this.hasEntryTimings,
    required this.hostelFor,
    required this.hostelType,
    required this.landmark,
    required this.mapLink,
    required this.minimumStay,
    required this.offers,
    required this.petsPolicy,
    required this.phone,
    required this.roomTypes,
    required this.selectedPlan,
    required this.smokingPolicy,
    required this.specialFeatures,
    required this.startingAt,
    required this.entryTime,
    required this.uploadedPhotos,
    required this.visibility,
  });

  factory HostelData.fromFirestore(Map<String, dynamic> data) {
    return HostelData(
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      availableFromDate: data['availableFromDate'] ?? '',
      bookingMode: data['bookingMode'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      description: data['description'] ?? '',
      drinkingPolicy: data['drinkingPolicy'] ?? '',
      email: data['email'] ?? '',
      facilities: (data['facilities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {},
      foodType: data['foodType'] ?? '',
      guestsPolicy: data['guestsPolicy'] ?? '',
      hasEntryTimings: data['hasEntryTimings'] ?? false,
      hostelFor: data['hostelFor'] ?? '',
      hostelType: data['hostelType'] ?? '',
      landmark: data['landmark'] ?? '',
      mapLink: data['mapLink'] ?? '',
      minimumStay: data['minimumStay'] ?? '',
      offers: data['offers'] ?? '',
      petsPolicy: data['petsPolicy'] ?? '',
      phone: data['phone'] ?? '',
      roomTypes: (data['roomTypes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {},
      selectedPlan: data['selectedPlan'] ?? '',
      smokingPolicy: data['smokingPolicy'] ?? '',
      specialFeatures: data['specialFeatures'] ?? '',
      startingAt: (data['startingAt'] ?? 0).toDouble(),
      entryTime: data['entryTime'] ?? '',
      uploadedPhotos: (data['uploadedPhotos'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      visibility: data['visibility'] ?? false,
    );
  }
}

class HostelDetailsScreen extends StatefulWidget {
  final String propertyId;

  const HostelDetailsScreen({Key? key, required this.propertyId}) : super(key: key);

  @override
  _HostelDetailsScreenState createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late HostelData hostelData;
  bool isBookmarked = false;
  int currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchHostelDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchHostelDetails() async {
    try {
      final hostelDoc = await _firestore
          .collection('hostel_listings')
          .doc(widget.propertyId)
          .get();

      if (hostelDoc.exists) {
        final data = hostelDoc.data() as Map<String, dynamic>;
        setState(() {
          hostelData = HostelData.fromFirestore(data);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Hostel listing not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading hostel details: [1m${e.toString()}[0m';
        isLoading = false;
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    if (hostelData.mapLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No map link available')),
      );
      return;
    }
    String url = hostelData.mapLink.trim();
    if (!url.startsWith('http')) {
      url = 'https://' + url;
    }
    try {
      final Uri mapsUri = Uri.parse(url);
      bool launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps: ${e.toString()}')),
      );
    }
  }

  List<String> get hostelImages => hostelData.uploadedPhotos.values.toList();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  _fetchHostelDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHostelHeader(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildPricingInfo(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildFacilities(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildPolicies(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildDescription(),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildContactInfo(),
                  const SizedBox(height: BuddyTheme.spacingXl),
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
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? BuddyTheme.primaryColor : Colors.white,
          ),
          onPressed: () {
            setState(() {
              isBookmarked = !isBookmarked;
            });
            HapticFeedback.lightImpact();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FullScreenImageGallery(
                  images: hostelImages,
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
            itemCount: hostelImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(hostelImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHostelHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hostelData.title,
          style: const TextStyle(
            fontSize: BuddyTheme.fontSizeXl,
            fontWeight: FontWeight.bold,
            color: BuddyTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingXs),
        Row(
          children: [
            const Icon(Icons.location_on, size: BuddyTheme.iconSizeSm, color: BuddyTheme.textSecondaryColor),
            const SizedBox(width: BuddyTheme.spacingXs),
            Expanded(
              child: Text(
                hostelData.address,
                style: const TextStyle(
                  color: BuddyTheme.textSecondaryColor,
                  fontSize: BuddyTheme.fontSizeMd,
                ),
              ),
            ),
            if (hostelData.mapLink.isNotEmpty)
              GestureDetector(
                onTap: _openGoogleMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingSm, vertical: BuddyTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: BuddyTheme.primaryColor,
                    borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.map, size: BuddyTheme.iconSizeSm, color: Colors.white),
                      SizedBox(width: BuddyTheme.spacingXs),
                      Text('View on Map', style: TextStyle(fontSize: BuddyTheme.fontSizeXs, color: Colors.white, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingSm, vertical: BuddyTheme.spacingXs),
          decoration: BoxDecoration(
            color: BuddyTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
          ),
          child: Text(
            hostelData.availableFromDate.isEmpty ? 'Available Now' : 'Available from ${hostelData.availableFromDate}',
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              color: BuddyTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                ),
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Starting At', style: TextStyle(fontSize: BuddyTheme.fontSizeSm, color: BuddyTheme.textSecondaryColor)),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text('₹${hostelData.startingAt.toStringAsFixed(0)}', style: const TextStyle(fontSize: BuddyTheme.fontSizeLg, fontWeight: FontWeight.bold, color: BuddyTheme.primaryColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: BuddyTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                ),
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Minimum Stay', style: TextStyle(fontSize: BuddyTheme.fontSizeSm, color: BuddyTheme.textSecondaryColor)),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(hostelData.minimumStay, style: const TextStyle(fontSize: BuddyTheme.fontSizeLg, fontWeight: FontWeight.bold, color: BuddyTheme.accentColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilities() {
    final facilities = hostelData.facilities.entries.where((e) => e.value).map((e) => e.key).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Facilities', style: TextStyle(fontSize: BuddyTheme.fontSizeLg, fontWeight: FontWeight.bold, color: BuddyTheme.textPrimaryColor)),
        const SizedBox(height: BuddyTheme.spacingMd),
        Wrap(
          spacing: BuddyTheme.spacingXs,
          runSpacing: BuddyTheme.spacingXs,
          children: facilities.map((facility) => Chip(label: Text(facility))).toList(),
        ),
      ],
    );
  }

  Widget _buildPolicies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Policies', style: TextStyle(fontSize: BuddyTheme.fontSizeLg, fontWeight: FontWeight.bold, color: BuddyTheme.textPrimaryColor)),
        const SizedBox(height: BuddyTheme.spacingMd),
        _buildPolicyItem('Smoking', hostelData.smokingPolicy),
        _buildPolicyItem('Drinking', hostelData.drinkingPolicy),
        _buildPolicyItem('Pets', hostelData.petsPolicy),
        _buildPolicyItem('Guests', hostelData.guestsPolicy),
        if (hostelData.hasEntryTimings) _buildPolicyItem('Entry Time', hostelData.entryTime),
      ],
    );
  }

  Widget _buildPolicyItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontSize: BuddyTheme.fontSizeLg, fontWeight: FontWeight.bold, color: BuddyTheme.textPrimaryColor)),
        const SizedBox(height: BuddyTheme.spacingMd),
        Text(hostelData.description),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact', style: TextStyle(fontSize: BuddyTheme.fontSizeLg, fontWeight: FontWeight.bold, color: BuddyTheme.textPrimaryColor)),
        const SizedBox(height: BuddyTheme.spacingMd),
        _buildContactItem(Icons.person, hostelData.contactPerson),
        _buildContactItem(Icons.phone, hostelData.phone),
        _buildContactItem(Icons.email, hostelData.email),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: BuddyTheme.iconSizeSm, color: BuddyTheme.primaryColor),
          const SizedBox(width: BuddyTheme.spacingSm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final Uri phoneUri = Uri(scheme: 'tel', path: hostelData.phone);
                  await launchUrl(phoneUri);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(foregroundColor: BuddyTheme.primaryColor),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: hostelData.email,
                    query: 'subject=Enquiry about ${hostelData.title}',
                  );
                  await launchUrl(emailUri);
                },
                icon: const Icon(Icons.email),
                label: const Text('Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
