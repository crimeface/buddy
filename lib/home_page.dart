import 'package:flutter/material.dart';
import 'theme.dart';
import 'profile_page.dart';
import 'need_room_page.dart';
import 'need_flatmate_page.dart';
import 'widgets/action_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';

export 'profile_page.dart';
export 'need_room_page.dart';
export 'need_flatmate_page.dart';
import 'Hostelpg_page.dart';
import 'service_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        key: const Key('home'),
        onTabChange: _onItemTapped,
      ),
      const NeedRoomPage(key: Key('needroom')),
      const NeedFlatmatePage(key: Key('needflatmate')),
      const ProfilePage(key: Key('profile')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navBarColor = theme.brightness == Brightness.dark
            ? const Color(0xFF23262F)
            : const Color(0xFFF5F6FA);
    final navBarIconColor = theme.brightness == Brightness.dark 
            ? Colors.white 
            : BuddyTheme.textSecondaryColor;
    final navBarSelectedColor = BuddyTheme.primaryColor;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: _pages[_selectedIndex],
      ),
      floatingActionButton:
          _selectedIndex == 0
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        notchMargin: BuddyTheme.spacingSm,
        elevation: BuddyTheme.elevationMd,
        padding: EdgeInsets.zero,
        color: navBarColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        shape: const CircularNotchedRectangle(),
        clipBehavior: Clip.antiAlias,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingSm),
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

  const HomePage({super.key, this.onTabChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    String name = 'User';
    if (user != null) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        name = user.displayName!;
      } else if (user.email != null && user.email!.trim().isNotEmpty) {
        name = user.email!.split('@')[0];
      } else if (user.phoneNumber != null &&
          user.phoneNumber!.trim().isNotEmpty) {
        name = user.phoneNumber!;
      }
    }
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
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
    final theme = Theme.of(context);

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
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildCompactHeader(context),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  
                  // Section header for Hostels & PGs
                  _buildSectionHeader(context, 'Hostels & PGs'),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildHostelsBannerSection(context),
                  const SizedBox(height: BuddyTheme.spacingLg),

                  // Section header for Other Services
                  _buildSectionHeader(context, 'Other Services'),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildServicesBannerSection(context),
                  const SizedBox(height: BuddyTheme.spacingXl),
                  
                  // Section header for Rooms
                  _buildSectionHeader(context, 'Rooms'),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildRoomsBannerSection(context),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  
                  // Section header for Flatmates
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

  Widget _buildCompactHeader(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final String? avatarUrl = user?.photoURL;

    return Container(
      padding: const EdgeInsets.all(16.0),
      // Removed the gradient decoration - now uses direct background
      child: Row(
        children: [
          // Greeting and Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$_userName!',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Profile Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  BuddyTheme.primaryColor.withOpacity(0.3),
                  BuddyTheme.secondaryColor.withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: BuddyTheme.primaryColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: theme.colorScheme.surfaceVariant,
                    highlightColor: theme.colorScheme.surface,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelsBannerSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/hostelpg'),
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
                imageUrl: 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=800&q=80',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: theme.colorScheme.surfaceVariant,
                  highlightColor: theme.colorScheme.surface,
                  child: Container(height: 180, color: theme.colorScheme.surfaceVariant),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(Icons.business, color: BuddyTheme.primaryColor, size: 50),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Explore Now →',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=80',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: theme.colorScheme.surfaceVariant,
                  highlightColor: theme.colorScheme.surface,
                  child: Container(height: 180, color: theme.colorScheme.surfaceVariant),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(Icons.hotel, color: BuddyTheme.successColor, size: 50),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Find Rooms →',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: theme.colorScheme.surfaceVariant,
                  highlightColor: theme.colorScheme.surface,
                  child: Container(height: 180, color: theme.colorScheme.surfaceVariant),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(Icons.group, color: BuddyTheme.warningColor, size: 50),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Find Flatmates →',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
      onTap: () => Navigator.pushNamed(context, '/services'),
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
                imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: theme.colorScheme.surfaceVariant,
                  highlightColor: theme.colorScheme.surface,
                  child: Container(height: 220, color: theme.colorScheme.surfaceVariant),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(Icons.room_service, color: BuddyTheme.accentColor, size: 50),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.8)],
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Service highlights
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildServiceChip('📚 Library', BuddyTheme.primaryColor),
                      _buildServiceChip('🍽️ Mess', BuddyTheme.successColor),
                      _buildServiceChip('☕ Cafe', BuddyTheme.accentColor),
                      _buildServiceChip('🎯 More', BuddyTheme.secondaryColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Explore Services →',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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