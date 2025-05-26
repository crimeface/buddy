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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(key: Key('home')),
    NeedRoomPage(key: Key('needroom')),
    NeedFlatmatePage(key: Key('needflatmate')),
    ProfilePage(key: Key('profile')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _pages[_selectedIndex],
      ),
      floatingActionButton: _selectedIndex == 0
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
          : null, // Hide FAB on other pages
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        notchMargin: BuddyTheme.spacingSm,
        elevation: BuddyTheme.elevationMd,
        padding: EdgeInsets.zero,
        color: BuddyTheme.backgroundSecondaryColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingSm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space all nav items
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.hotel_outlined, Icons.hotel, 'Need\nRoom'),
              if (_selectedIndex == 0)
                const SizedBox(width: 56), // Reserve space for FAB (56 is default FAB diameter)
              _buildNavItem(2, Icons.group_outlined, Icons.group, 'Need\nFlatmate'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
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
                color: isSelected ? BuddyTheme.primaryColor : BuddyTheme.textSecondaryColor,
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
                  color: isSelected ? BuddyTheme.primaryColor : BuddyTheme.textSecondaryColor,
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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        _userName = user.displayName ?? 'User';
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
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2)); // Simulate refresh
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
                  _buildHeader(context),
                  const SizedBox(height: BuddyTheme.spacingLg),
                  _buildSectionHeader(context, 'Featured Properties', () {}),
                  const SizedBox(height: BuddyTheme.spacingSm),
                  SizedBox(
                    height: 270,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPropertyCard(
                          context,
                          imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
                          title: 'De Apartment',
                          price: '\$267,000',
                          location: '2BW NY, New York',
                          size: '2000 sqft',
                          bedCount: 4,
                          bathCount: 3,
                          kitchenCount: 1,
                        ),
                        const SizedBox(width: BuddyTheme.spacingSm),
                        _buildPropertyCard(
                          context,
                          imageUrl: 'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=400&q=80',
                          title: 'Urban Flat',
                          price: '\$320,000',
                          location: '5th Ave, NY, New York',
                          size: '1800 sqft',
                          bedCount: 3,
                          bathCount: 2,
                          kitchenCount: 1,
                        ),
                        const SizedBox(width: BuddyTheme.spacingSm),
                        _buildPropertyCard(
                          context,
                          imageUrl: 'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=400&q=80',
                          title: 'Lake House',
                          price: '\$450,000',
                          location: 'Lakeview, Chicago',
                          size: '2500 sqft',
                          bedCount: 5,
                          bathCount: 4,
                          kitchenCount: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  _buildSectionHeader(context, 'Featured Flatmates', () {}),
                  const SizedBox(height: BuddyTheme.spacingSm),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFlatmateCard(
                          context,
                          imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
                          name: 'Alex Johnson',
                          profession: 'Software Engineer',
                        ),
                        const SizedBox(width: BuddyTheme.spacingSm),
                        _buildFlatmateCard(
                          context,
                          imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
                          name: 'Priya Sharma',
                          profession: 'Designer',
                        ),
                        const SizedBox(width: BuddyTheme.spacingSm),
                        _buildFlatmateCard(
                          context,
                          imageUrl: 'https://randomuser.me/api/portraits/men/65.jpg',
                          name: 'Rahul Mehra',
                          profession: 'Student',
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello!',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: BuddyTheme.textSecondaryColor,
                  ),
            ),
            Text(
              _userName,
              style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: BuddyTheme.iconSizeXl,
              height: BuddyTheme.iconSizeXl,
              decoration: BoxDecoration(
                color: BuddyTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: BuddyTheme.borderColor, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusCircular),
                child: CachedNetworkImage(
                  imageUrl: 'https://via.placeholder.com/50',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: BuddyTheme.backgroundSecondaryColor,
                    highlightColor: BuddyTheme.backgroundPrimaryColor,
                    child: Container(
                      color: BuddyTheme.backgroundSecondaryColor,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    color: BuddyTheme.textSecondaryColor,
                    size: BuddyTheme.iconSizeLg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'See All »',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: BuddyTheme.successColor,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(
    BuildContext context, {
    required String imageUrl,
    required String title,
    required String price,
    required String location,
    required String size,
    required int bedCount,
    required int bathCount,
    required int kitchenCount,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: 255,
        decoration: BuddyTheme.featuredCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(BuddyTheme.borderRadiusMd),
                topRight: Radius.circular(BuddyTheme.borderRadiusMd),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: BuddyTheme.backgroundSecondaryColor,
                  highlightColor: BuddyTheme.backgroundPrimaryColor,
                  child: Container(
                    color: BuddyTheme.backgroundSecondaryColor,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.broken_image,
                  color: BuddyTheme.textSecondaryColor,
                  size: BuddyTheme.iconSizeLg,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BuddyTheme.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                color: BuddyTheme.textPrimaryColor, // <-- Set to a visible color
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: BuddyTheme.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingXs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: BuddyTheme.textSecondaryColor,
                        size: BuddyTheme.iconSizeSm,
                      ),
                      const SizedBox(width: BuddyTheme.spacingXxs),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: BuddyTheme.textSecondaryColor, // <-- Set to a visible color
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: BuddyTheme.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BuddyTheme.spacingXs,
                          vertical: BuddyTheme.spacingXxs,
                        ),
                        decoration: BuddyTheme.roomAvailableTagDecoration,
                        child: Text(
                          size,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: BuddyTheme.textLightColor, // <-- Ensure contrast
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureChip(context, Icons.bed, '$bedCount Bed'),
                      _buildFeatureChip(context, Icons.bathtub, '$bathCount Bath'),
                      _buildFeatureChip(context, Icons.kitchen, '$kitchenCount Kitchen'),
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

  Widget _buildFeatureChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BuddyTheme.spacingXs,
        vertical: BuddyTheme.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: BuddyTheme.backgroundSecondaryColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusXs),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: BuddyTheme.warningColor,
            size: BuddyTheme.iconSizeSm,
          ),
          const SizedBox(width: BuddyTheme.spacingXxs),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: BuddyTheme.textPrimaryColor, // <-- Set to a visible color
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatmateCard(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required String profession,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(BuddyTheme.spacingXs),
        decoration: BuddyTheme.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: BuddyTheme.backgroundSecondaryColor,
              radius: BuddyTheme.iconSizeMd / 2,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: BuddyTheme.iconSizeMd,
                  height: BuddyTheme.iconSizeMd,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: BuddyTheme.backgroundSecondaryColor,
                    highlightColor: BuddyTheme.backgroundPrimaryColor,
                    child: Container(
                      color: BuddyTheme.backgroundSecondaryColor,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    color: BuddyTheme.textSecondaryColor,
                    size: BuddyTheme.iconSizeSm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: BuddyTheme.spacingXs),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              profession,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: BuddyTheme.textSecondaryColor,
                  ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}