import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoggingOut = false;
  String _profileImageUrlFromFirestore = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProfileImageUrl();
  }

  Future<void> _loadProfileImageUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user?.email?.toLowerCase() == 'campusnest12@gmail.com';
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _profileImageUrlFromFirestore = data?['profileImageUrl'] ?? '';
      });
    }
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? Colors.black : BuddyTheme.backgroundPrimaryColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                floating: false,
                pinned: true,
                backgroundColor:
                    isDark ? Colors.black : BuddyTheme.backgroundPrimaryColor,
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: Container(
                        color:
                            isDark
                                ? Colors.black
                                : BuddyTheme.backgroundPrimaryColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            _buildProfileAvatar(isDark),
                            const SizedBox(height: 20),
                            _buildUserNameSection(isDark),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: _buildAccountSettingsSection(isDark)),
            ],
          ),
          if (_isLoggingOut)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(bool isDark) {
    return Hero(
      tag: 'profile_avatar',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors:
                isDark
                    ? [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ]
                    : [
                      BuddyTheme.primaryColor.withOpacity(0.8),
                      BuddyTheme.secondaryColor.withOpacity(0.6),
                    ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.2)
                      : BuddyTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl:
                  _profileImageUrlFromFirestore.isNotEmpty
                      ? _profileImageUrlFromFirestore
                      : (_user?.photoURL ?? 'https://via.placeholder.com/150'),
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserNameSection(bool isDark) {
    return Column(
      children: [
        Text(
          (_user?.displayName != null && _user!.displayName!.trim().isNotEmpty)
              ? _user!.displayName!
              : (_user?.email != null && _user!.email!.trim().isNotEmpty)
              ? _user!.email!.split('@')[0].toUpperCase()
              : (_user?.phoneNumber ?? 'Guest User'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
            ),
          ),
          child: Text(
            _user?.email ?? 'No Email',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration.copyWith(
        color:
            isDark
                ? Colors.grey[900]
                : const Color.fromARGB(255, 240, 238, 238),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(BuddyTheme.spacingMd),
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          _buildMenuOption(
            icon: Icons.person_outline,
            iconColor: BuddyTheme.primaryColor,
            title: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            isDark: isDark,
          ),
          // --- Add Change Price button here for admin ---
          if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() ==
              'campusnest12@gmail.com')
            _buildMenuOption(
              icon: Icons.price_change,
              iconColor: Colors.green,
              title: 'Change Price',
              onTap: () {
                _showChangePriceDialog(context);
              },
              isDark: isDark,
            ),
          // --- End Change Price button ---
          _buildMenuOption(
            icon: Icons.chat_bubble_outline,
            iconColor: BuddyTheme.secondaryColor,
            title: 'Messages',
            onTap: () {},
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            onTap: () {},
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.security_outlined,
            iconColor: BuddyTheme.successColor,
            title: 'Privacy & Security',
            onTap: () {
              Navigator.pushNamed(context, '/privacyPolicy');
            },
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.favorite_outline,
            iconColor: Colors.amber,
            title: 'My Listings',
            onTap: () {
              Navigator.pushNamed(context, '/myListings');
            },
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.settings_outlined,
            iconColor: BuddyTheme.textSecondaryColor,
            title: 'Settings',
            onTap: () {},
            isLast: true,
            isDark: isDark,
          ),
          Container(
            margin: const EdgeInsets.all(BuddyTheme.spacingMd),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: const Icon(Icons.logout, size: BuddyTheme.iconSizeMd),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BuddyTheme.primaryColor,
                side: const BorderSide(color: BuddyTheme.primaryColor),
                padding: const EdgeInsets.symmetric(
                  vertical: BuddyTheme.spacingSm,
                ),
                backgroundColor: isDark ? Colors.grey[850] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
    required bool isDark,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: Icon(icon, color: iconColor, size: BuddyTheme.iconSizeMd),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : BuddyTheme.textPrimaryColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white54 : BuddyTheme.textSecondaryColor,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BuddyTheme.spacingMd,
            vertical: BuddyTheme.spacingXs,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent:
                BuddyTheme.spacingMd +
                BuddyTheme.iconSizeMd +
                BuddyTheme.spacingXs,
            endIndent: BuddyTheme.spacingMd,
            color: isDark ? Colors.white24 : BuddyTheme.dividerColor,
          ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                setState(() {
                  _isLoggingOut = true;
                });
                await FirebaseAuth.instance.signOut();
                setState(() {
                  _isLoggingOut = false;
                });
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BuddyTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePriceDialog(BuildContext context) {
    final List<String> services = [
      'list_hostelpg',
      'list_room',
      'room_request',
      'list_service',
    ];
    final List<String> dayOptions = ['1 day', '7 days', '15 days', '1 month'];

    String? selectedService;
    String? selectedDay;
    final actualPriceController = TextEditingController();
    final discountedPriceController = TextEditingController();

    Future<void> fetchPrices() async {
      if (selectedService != null && selectedDay != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('plan_prices')
                .doc(selectedService)
                .collection('day_wise_prices')
                .doc(selectedDay)
                .get();
        if (doc.exists) {
          final data = doc.data()!;
          actualPriceController.text = data['actual_price']?.toString() ?? '';
          discountedPriceController.text =
              data['discounted_price']?.toString() ?? '';
        } else {
          actualPriceController.text = '';
          discountedPriceController.text = '';
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Change Price'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedService,
                        hint: const Text('Select Service'),
                        items:
                            services
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) async {
                          setState(() {
                            selectedService = val;
                            selectedDay = null;
                            actualPriceController.clear();
                            discountedPriceController.clear();
                          });
                          // If both are selected, fetch prices
                          if (val != null && selectedDay != null) {
                            await fetchPrices();
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedDay,
                        hint: const Text('Select Days'),
                        items:
                            dayOptions
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            selectedService == null
                                ? null
                                : (val) async {
                                  setState(() {
                                    selectedDay = val;
                                  });
                                  if (selectedService != null && val != null) {
                                    await fetchPrices();
                                    setState(() {});
                                  }
                                },
                        disabledHint: const Text('Select Service First'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: actualPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Actual Price',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: discountedPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discounted Price',
                        ),
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
                      if (selectedService == null || selectedDay == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select service and days'),
                          ),
                        );
                        return;
                      }
                      final actualPrice =
                          double.tryParse(actualPriceController.text) ?? 0;
                      final discountedPrice =
                          double.tryParse(discountedPriceController.text) ?? 0;
                      await FirebaseFirestore.instance
                          .collection('plan_prices')
                          .doc(selectedService)
                          .collection('day_wise_prices')
                          .doc(selectedDay)
                          .set({
                            'actual_price': actualPrice,
                            'discounted_price': discountedPrice,
                          }, SetOptions(merge: true));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Price updated!')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
        );
      },
    );
  }
}
