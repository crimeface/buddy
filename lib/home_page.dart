import 'package:buddy/api/map_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'profile_page.dart';
import 'need_room_page.dart';
import 'need_flatmate_page.dart';
import 'widgets/action_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/firebase_storage_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'Hostelpg_page.dart';
import 'service_page.dart';
import 'splash_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'features_map_search_page.dart';

export 'profile_page.dart';
export 'need_room_page.dart';
export 'need_flatmate_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _bannersLoaded = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onBannersLoadedChanged(bool loaded) {
    if (_bannersLoaded != loaded) {
      setState(() {
        _bannersLoaded = loaded;
      });
    }
  }

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        key: const Key('home'),
        onTabChange: _onItemTapped,
        onBannersLoadedChanged: _onBannersLoadedChanged,
      ),
      NeedRoomPage(key: const Key('needroom')),
      NeedFlatmatePage(key: const Key('needflatmate')),
      ProfilePage(key: const Key('profile')),
    ];
  }

  void _showActionSheet(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ActionBottomSheet(),
    );

    if (result != null && mounted) {
      setState(() => _selectedIndex = result);
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false; // Prevent app from closing, just go to home
    }
    SystemNavigator.pop(); // Only close app if already on home
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Force dark theme for this page
    final darkTheme = ThemeData.dark();
    final navBarColor = const Color(0xFF23262F);
    final navBarIconColor = Colors.white;
    final navBarSelectedColor = BuddyTheme.primaryColor;

    return Theme(
      data: darkTheme,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: Colors.black, // Force black background
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child: _pages[_selectedIndex],
          ),
          floatingActionButton:
              _selectedIndex == 0 && _bannersLoaded
                  ? Container(
                    decoration: BuddyTheme.fabShadowDecoration,
                    child: FloatingActionButton(
                      onPressed: () => _showActionSheet(context),
                      backgroundColor: BuddyTheme.primaryColor,
                      shape: const CircleBorder(),
                      elevation: BuddyTheme.elevationSm,
                      child: const Icon(
                        Icons.add,
                        size: BuddyTheme.iconSizeMd,
                        color: BuddyTheme.textLightColor,
                      ),
                    ),
                  )
                  : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar:
              _bannersLoaded
                  ? BottomAppBar(
                    notchMargin: BuddyTheme.spacingSm,
                    elevation: BuddyTheme.elevationMd,
                    padding: EdgeInsets.zero,
                    color: navBarColor,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.black26,
                    shape: const CircularNotchedRectangle(),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      height: 60 + MediaQuery.of(context).padding.bottom,
                      padding: const EdgeInsets.symmetric(
                        horizontal: BuddyTheme.spacingSm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            0,
                            Icons.home_outlined,
                            Icons.home,
                            'Home',
                            navBarIconColor,
                            navBarSelectedColor,
                          ),
                          _buildNavItem(
                            1,
                            Icons.hotel_outlined,
                            Icons.hotel,
                            'Need\nRoom',
                            navBarIconColor,
                            navBarSelectedColor,
                          ),
                          if (_selectedIndex == 0) const SizedBox(width: 56),
                          _buildNavItem(
                            2,
                            Icons.group_outlined,
                            Icons.group,
                            'Need\nFlatmate',
                            navBarIconColor,
                            navBarSelectedColor,
                          ),
                          _buildNavItem(
                            3,
                            Icons.person_outline,
                            Icons.person,
                            'Profile',
                            navBarIconColor,
                            navBarSelectedColor,
                          ),
                        ],
                      ),
                    ),
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    Color iconColor,
    Color selectedColor,
  ) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? selectedColor : iconColor,
                size: BuddyTheme.iconSizeMd,
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: isSelected ? selectedColor : iconColor,
              fontSize: BuddyTheme.fontSizeXs,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function(int)? onTabChange;
  final ValueChanged<bool>? onBannersLoadedChanged;

  const HomePage({
    super.key,
    this.onTabChange,
    this.onBannersLoadedChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _userName = '';
  String? _profileImageUrl;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _banners = [];
  bool _bannersLoaded = false;
  DateTime? _splashStartTime;
  bool _splashMinTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _splashMinTimeElapsed = true;
        });
        // If banners already loaded, trigger UI update
        if (_banners.isNotEmpty && !_bannersLoaded) {
          setState(() {
            _bannersLoaded = true;
            _notifyBannersLoadedChanged();
          });
        } else {
          _notifyBannersLoadedChanged();
        }
      }
    });
    _loadUserName();
    _loadProfileImage();
    _checkAdmin();
    _loadBanners();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        _profileImageUrl = doc.data()?['profileImageUrl'] ?? user.photoURL;
      });
    }
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        _userName = doc.data()?['name'] ?? user.displayName ?? 'User';
      });
    }
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Use email to check admin, as in profile_page.dart
    const adminEmails = [
      'campusnest12@gmail.com', // Replace with your actual admin email(s)
      // Add more admin emails as needed
    ];
    setState(() {
      _isAdmin = user.email != null && adminEmails.contains(user.email);
    });
  }

  Future<void> _loadBanners() async {
    final bannersSnap =
        await FirebaseFirestore.instance.collection('promo_banners').get();
    if (bannersSnap.docs.isNotEmpty) {
      _banners = bannersSnap.docs.map((d) => d.data()).toList();
      if (_splashMinTimeElapsed) {
        setState(() {
          _bannersLoaded = true;
          _notifyBannersLoadedChanged();
        });
      } else {
        _notifyBannersLoadedChanged();
      }
      // else: splash will be hidden by timer
    } else {
      // Save current hardcoded banners to Firestore
      final defaultBanners = [
        {
          'title': 'HOSTEL & PGs',
          'subtitle': 'Find Your Perfect Accommodation',
          'icon': 'home_work',
          'image':
              'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=400&q=80',
        },
        {
          'title': 'NEEDY SERVICES',
          'subtitle': 'Get Connected with Local Services',
          'icon': 'support_agent',
          'image':
              'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?auto=format&fit=crop&w=400&q=80',
        },
        {
          'title': 'FLATMATES FINDER',
          'subtitle': 'Connect With Perfect Roommates',
          'icon': 'people',
          'image':
              'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=400&q=80',
        },
        {
          'title': 'ROOM FINDER',
          'subtitle': 'Discover Your Ideal Space',
          'icon': 'bed',
          'image':
              'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=400&q=80',
        },
      ];
      for (final banner in defaultBanners) {
        await FirebaseFirestore.instance
            .collection('promo_banners')
            .add(banner);
      }
      _banners = defaultBanners;
      if (_splashMinTimeElapsed) {
        setState(() {
          _bannersLoaded = true;
          _notifyBannersLoadedChanged();
        });
      } else {
        _notifyBannersLoadedChanged();
      }
      // else: splash will be hidden by timer
    }
  }

  void _notifyBannersLoadedChanged() {
    widget.onBannersLoadedChanged?.call(_bannersLoaded);
  }

  Future<void> _editBanner(int index) async {
    final banner = _banners[index];
    final titleController = TextEditingController(text: banner['title']);
    final subtitleController = TextEditingController(text: banner['subtitle']);
    String iconName = banner['icon'] ?? 'home_work';
    String imageUrl = banner['image'] ?? '';
    File? newImageFile;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle'),
                ),
                DropdownButton<String>(
                  value: iconName,
                  items:
                      [
                            'home_work',
                            'support_agent',
                            'people',
                            'bed',
                            'room_service',
                            'group',
                            'hotel',
                          ]
                          .map(
                            (icon) => DropdownMenuItem(
                              value: icon,
                              child: Text(icon),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => iconName = v);
                  },
                ),
                const SizedBox(height: 8),
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl, height: 80)
                    : const SizedBox.shrink(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Change Image'),
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      newImageFile = File(picked.path);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newImageUrl = imageUrl;
                if (newImageFile != null) {
                  newImageUrl = await FirebaseStorageService.uploadImage(
                    newImageFile!.path,
                  );
                }
                // Update Firestore
                final bannersSnap =
                    await FirebaseFirestore.instance
                        .collection('promo_banners')
                        .get();
                final docId = bannersSnap.docs[index].id;
                await FirebaseFirestore.instance
                    .collection('promo_banners')
                    .doc(docId)
                    .update({
                      'title': titleController.text,
                      'subtitle': subtitleController.text,
                      'icon': iconName,
                      'image': newImageUrl,
                    });
                Navigator.pop(context);
                _loadBanners();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewBanner(BuildContext context) async {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String iconName = 'home_work';
    File? newImageFile;
    String? imageUrl;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle'),
                ),
                DropdownButton<String>(
                  value: iconName,
                  items:
                      [
                            'home_work',
                            'support_agent',
                            'people',
                            'bed',
                            'room_service',
                            'group',
                            'hotel',
                          ]
                          .map(
                            (icon) => DropdownMenuItem(
                              value: icon,
                              child: Text(icon),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      iconName = v;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(height: 8),
                imageUrl != null
                    ? Image.network(imageUrl!, height: 80)
                    : const SizedBox.shrink(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Select Image'),
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      newImageFile = File(picked.path);
                      imageUrl = await FirebaseStorageService.uploadImage(
                        newImageFile!.path,
                      );
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    subtitleController.text.isEmpty ||
                    imageUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill all fields and select an image.',
                      ),
                    ),
                  );
                  return;
                }
                await FirebaseFirestore.instance
                    .collection('promo_banners')
                    .add({
                      'title': titleController.text,
                      'subtitle': subtitleController.text,
                      'icon': iconName,
                      'image': imageUrl,
                    });
                Navigator.pop(context);
                _loadBanners();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Theme.of(context);

    // Show splash screen until banners are loaded AND 5 seconds have passed
    if (!_bannersLoaded) {
      return SplashScreen();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
        },
        color: BuddyTheme.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: RangeMaintainingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(
                left: BuddyTheme.spacingMd,
                right: BuddyTheme.spacingMd,
                bottom: BuddyTheme.spacingMd,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildUpdatedHeader(context),
                  _buildSectionHeader(context, 'Hostels & PGs'),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildHostelsBannerSection(context),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildSectionHeader(context, 'Other Services'),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildServicesBannerSection(context),
                  const SizedBox(height: BuddyTheme.spacingXl),
                  _buildSectionHeader(context, 'Rooms'),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildRoomsBannerSection(context),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildSectionHeader(context, 'Flatmates'),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildFlatmatesBannerSection(context),
                  const SizedBox(height: BuddyTheme.spacingLg),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatedHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          // Top row with greeting and profile
          Row(
            children: [
              // Greeting and Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello $_userName,',
                      style: theme.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color:
                            theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        _showLocationSelector(context);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color:
                                theme.brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black54,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Select Location',
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color:
                                  theme.brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Profile Avatar with black circle border and tap functionality
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => widget.onTabChange?.call(3),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.4)
                              : Colors.black.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _profileImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _profileImageUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme.colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.person,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: theme.colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.person,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Map Pin Button
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.pin_drop, color: Colors.white),
                      tooltip: 'Search Nearby',
                      onPressed: () async {
                        double radius = 3;
                        await showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.pin_drop, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text('Set Search Radius', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Text('Radius: \\${radius.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white)),
                                      Slider(
                                        value: radius,
                                        min: 1,
                                        max: 10,
                                        divisions: 9,
                                        label: '\\${radius.toStringAsFixed(1)} km',
                                        onChanged: (v) => setState(() => radius = v),
                                        activeColor: Colors.white,
                                        inactiveColor: Colors.white24,
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.map, color: Colors.white),
                                          label: const Text('Drop Pin on Map', style: TextStyle(color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: BuddyTheme.primaryColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context, radius);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ).then((selectedRadius) async {
                          if (selectedRadius != null) {
                            // Show map for pin drop
                            final LatLng? picked = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapLocationPicker(),
                              ),
                            );
                            if (picked != null) {
                              // Navigate to the new features map search page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FeaturesMapSearchPage(
                                    center: picked,
                                    radiusKm: selectedRadius,
                                  ),
                                ),
                              );
                            }
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Promotional Banner Carousel
          _buildPromoBannerCarousel(context),
        ],
      ),
    );
  }

  Widget _buildPromoBannerCarousel(BuildContext context) {
    final theme = Theme.of(context);
    if (!_bannersLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        _BannerCarouselWidget(banners: _banners, theme: theme),
        if (_isAdmin)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              tooltip: 'Edit Banners',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return SimpleDialog(
                          title: const Text('Edit Promo Banners'),
                          children: [
                            ...List.generate(_banners.length, (i) {
                              final b = _banners[i];
                              return ListTile(
                                leading:
                                    b['image'] != null
                                        ? Image.network(
                                          b['image'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        )
                                        : null,
                                title: Text(b['title'] ?? ''),
                                subtitle: Text(b['subtitle'] ?? ''),
                                trailing: const Icon(Icons.edit),
                                onTap: () {
                                  Navigator.pop(context);
                                  _editBanner(i);
                                },
                              );
                            }),
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.add,
                                color: Colors.green,
                              ),
                              title: const Text('Add New Banner'),
                              onTap: () async {
                                Navigator.pop(context);
                                await _addNewBanner(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 360,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select City',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              ...['Select Location', 'Pune', 'Mumbai', 'Nanded', 'Latur'].map(
                (city) => ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(city),
                  onTap: () {
                    setState(() {
                      // No need to update _pages or _selectedIndex
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHostelsBannerSection(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HostelPgPage(),
            ),
          ),
      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: BuddyTheme.primaryColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=800&q=80',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        height: 180,
                        color: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: 180,
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.business,
                        color: BuddyTheme.primaryColor,
                        size: 50,
                      ),
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Main content at the bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Your Perfect\nAccommodation',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Explore Now →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

  Widget _buildRoomsBannerSection(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => widget.onTabChange?.call(1), // Navigate to Need Room tab
      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: BuddyTheme.successColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=80',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        height: 180,
                        color: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: 180,
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.hotel,
                        color: BuddyTheme.successColor,
                        size: 50,
                      ),
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Main content at the bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Looking for a\nRoom to Rent?',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Find Rooms →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

  Widget _buildFlatmatesBannerSection(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => widget.onTabChange?.call(2), // Navigate to Need Flatmate tab
      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: BuddyTheme.warningColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        height: 180,
                        color: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: 180,
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.group,
                        color: BuddyTheme.warningColor,
                        size: 50,
                      ),
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Main content at the bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Your Perfect\nFlatmate Match',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Find Flatmates →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

  Widget _buildServicesBannerSection(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServicesPage(),
            ),
          ),
      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: BuddyTheme.accentColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        height: 220,
                        color: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: 220,
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.room_service,
                        color: BuddyTheme.accentColor,
                        size: 50,
                      ),
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Main content at the bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Nearby\nAmenities & More',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Service highlights
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildServiceChip('📚 Library', BuddyTheme.primaryColor),
                      _buildServiceChip('🍽 Mess', BuddyTheme.successColor),
                      _buildServiceChip('☕ Cafe', BuddyTheme.accentColor),
                      _buildServiceChip('🎯 More', BuddyTheme.secondaryColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Explore Services →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

  Widget _buildServiceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [BuddyTheme.primaryColor, BuddyTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

class _BannerCarouselWidget extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final ThemeData theme;

  const _BannerCarouselWidget({required this.banners, required this.theme});

  @override
  State<_BannerCarouselWidget> createState() => _BannerCarouselWidgetState();
}

class _BannerCarouselWidgetState extends State<_BannerCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % widget.banners.length;
              });
            },
            itemCount: null, // Infinite loop
            itemBuilder: (context, index) {
              final banner = widget.banners[index % widget.banners.length];
              IconData? iconData;
              switch (banner['icon']) {
                case 'home_work':
                  iconData = Icons.home_work;
                  break;
                case 'support_agent':
                  iconData = Icons.support_agent;
                  break;
                case 'people':
                  iconData = Icons.people;
                  break;
                case 'bed':
                  iconData = Icons.bed;
                  break;
                case 'room_service':
                  iconData = Icons.room_service;
                  break;
                case 'group':
                  iconData = Icons.group;
                  break;
                case 'hotel':
                  iconData = Icons.hotel;
                  break;
                default:
                  iconData = Icons.home_work;
              }
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                ),
                child: Stack(
                  children: [
                    // Background image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          banner['image'] != null
                              ? CachedNetworkImage(
                                imageUrl: banner['image'],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Shimmer.fromColors(
                                      baseColor:
                                          widget
                                              .theme
                                              .colorScheme
                                              .surfaceVariant,
                                      highlightColor:
                                          widget.theme.colorScheme.surface,
                                      child: Container(
                                        height: 120,
                                        color:
                                            widget
                                                .theme
                                                .colorScheme
                                                .surfaceVariant,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      height: 120,
                                      color: widget.theme.colorScheme.surface,
                                      child: Icon(
                                        iconData,
                                        size: 40,
                                        color: widget.theme.colorScheme.primary,
                                      ),
                                    ),
                              )
                              : Container(
                                height: 120,
                                color: widget.theme.colorScheme.surface,
                                child: Icon(
                                  iconData,
                                  size: 40,
                                  color: widget.theme.colorScheme.primary,
                                ),
                              ),
                    ),
                    // Dark overlay for better text readability
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner['title'] as String,
                                  style: widget.theme.textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  banner['subtitle'] as String,
                                  style: widget.theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            iconData,
                            color: Colors.white.withOpacity(0.9),
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              width: _currentIndex == index ? 16 : 4,
              decoration: BoxDecoration(
                color:
                    _currentIndex == index
                        ? BuddyTheme.primaryColor
                        : BuddyTheme.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
