import 'package:flutter/material.dart';
import 'theme.dart'; // Assuming theme.dart is imported as BuddyTheme
import 'profile_page.dart';
import 'widgets/action_sheet.dart';

export 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text('Need Room Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Need Flatmate Page', style: TextStyle(fontSize: 24))),
    const ProfilePage(key: Key('profile')),
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
      body: _pages[_selectedIndex],
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,        child: FloatingActionButton(
          onPressed: () {
            _showActionSheet(context);
          },
          backgroundColor: BuddyTheme.primaryColor,
          shape: const CircleBorder(),
          elevation: BuddyTheme.elevationSm,
          child: const Icon(
            Icons.add,
            size: BuddyTheme.iconSizeMd,
            color: BuddyTheme.textLightColor,
          ),
        ),
      ),      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,      bottomNavigationBar: BottomAppBar(
        notchMargin: 10,
        elevation: BuddyTheme.elevationMd,
        padding: EdgeInsets.zero,
        color: Color(0xFFF5F5F5),  // Light gray background
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),          child: Row(
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.hotel_outlined, Icons.hotel, 'Need\nRoom'),
              const SizedBox(width: 65),  // Space for FAB
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
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? BuddyTheme.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? BuddyTheme.primaryColor : Colors.grey,
                fontSize: 10,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and profile picture
              Row(
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
                        'James Butler',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),
                  Container(
                    width: BuddyTheme.iconSizeXl,
                    height: BuddyTheme.iconSizeXl,
                    decoration: BoxDecoration(
                      color: BuddyTheme.successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(BuddyTheme.borderRadiusCircular),
                      child: Image.network(
                        'https://via.placeholder.com/50',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BuddyTheme.spacingLg),
              // Featured Properties section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Properties',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to all properties page
                    },
                    child: Text(
                      'See All »',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: BuddyTheme.successColor,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BuddyTheme.spacingSm),
              // Property listings - horizontal scrollable
              SizedBox(
                height: 270,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [                    _buildPropertyCard(
                      context,
                      imageUrl:
                          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
                      title: 'De Apartment',
                      price: '\$267000',
                      location: '2BW NY, New York',
                      size: '2000sqft',
                      bedCount: 4,
                      bathCount: 3,
                      kitchenCount: 1,
                    ),
                    const SizedBox(width: BuddyTheme.spacingSm),                    _buildPropertyCard(
                      context,
                      imageUrl:
                          'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=400&q=80',
                      title: 'Urban Flat',
                      price: '\$320000',
                      location: '5th Ave, NY, New York',
                      size: '1800sqft',
                      bedCount: 3,
                      bathCount: 2,
                      kitchenCount: 1,
                    ),
                    const SizedBox(width: BuddyTheme.spacingSm),                    _buildPropertyCard(
                      context,
                      imageUrl:
                          'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=400&q=80',
                      title: 'Lake House',
                      price: '\$450000',
                      location: 'Lakeview, Chicago',
                      size: '2500sqft',
                      bedCount: 5,
                      bathCount: 4,
                      kitchenCount: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BuddyTheme.spacingMd),
              // Featured Flatmates section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Flatmates',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to all flatmates page
                    },
                    child: Text(
                      'See All »',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: BuddyTheme.successColor,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BuddyTheme.spacingSm),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [                    _buildFlatmateCard(
                      context,
                      imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
                      name: 'Alex Johnson',
                      profession: 'Software Engineer',
                    ),
                    const SizedBox(width: BuddyTheme.spacingSm),
                    _buildFlatmateCard(
                      context,
                      imageUrl:
                          'https://randomuser.me/api/portraits/women/44.jpg',
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
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPropertyCard(BuildContext context, {
    required String imageUrl,
    required String title,
    required String price,
    required String location,
    required String size,
    required int bedCount,
    required int bathCount,
    required int kitchenCount,
  }) {
    return Container(
      width: 250,
      decoration: BuddyTheme.featuredCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(BuddyTheme.borderRadiusMd),
              topRight: Radius.circular(BuddyTheme.borderRadiusMd),
            ),
            child: Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BuddyTheme.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: BuddyTheme.accentColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                // Location
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
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: BuddyTheme.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BuddyTheme.spacingXs,
                        vertical: BuddyTheme.spacingXxs,
                      ),
                      decoration: BoxDecoration(
                        color: BuddyTheme.backgroundSecondaryColor,
                        borderRadius:
                            BorderRadius.circular(BuddyTheme.borderRadiusXs),
                      ),
                      child: Text(
                        size,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BuddyTheme.spacingSm),
                // Features
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [                    _buildFeatureChip(context, Icons.bed, '$bedCount Bed'),
                    _buildFeatureChip(context, Icons.bathtub, '$bathCount Bath'),
                    _buildFeatureChip(context, Icons.kitchen, '$kitchenCount Kitchen'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFeatureChip(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: BuddyTheme.warningColor,
          size: BuddyTheme.iconSizeSm,
        ),
        const SizedBox(width: BuddyTheme.spacingXxs),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  Widget _buildFlatmateCard(BuildContext context, {
    required String imageUrl,
    required String name,
    required String profession,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(BuddyTheme.spacingXs),
      decoration: BuddyTheme.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(imageUrl),
            radius: BuddyTheme.iconSizeMd / 2,
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            profession,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}