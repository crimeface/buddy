import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuddyTheme.backgroundPrimaryColor,
      body: Stack(
        children: [
          _buildMainContent(),
          if (_isLoggingOut)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BuddyTheme.primaryColor,
                  BuddyTheme.secondaryColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  children: [
                    const SizedBox(height: BuddyTheme.spacingLg),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BuddyTheme.textLightColor,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://via.placeholder.com/100',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingMd),
                    Text(
                      _user?.displayName ?? 'No Name',
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeXl,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.textLightColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      _user?.email ?? 'No Email',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textLightColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingLg),
                  ],
                ),
              ),
            ),
          ),
          _buildStatsSection(),
          _buildAccountSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(BuddyTheme.spacingMd),
      padding: const EdgeInsets.symmetric(vertical: BuddyTheme.spacingLg),
      decoration: BuddyTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('3', 'Active Listings'),
          _buildStatDivider(),
          _buildStatItem('12', 'Saved'),
          _buildStatDivider(),
          _buildStatItem('5', 'Messages'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: BuddyTheme.fontSizeXl,
            fontWeight: FontWeight.bold,
            color: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingXs),
        Text(
          label,
          style: const TextStyle(
            fontSize: BuddyTheme.fontSizeXs,
            color: BuddyTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: BuddyTheme.dividerColor,
    );
  }

  Widget _buildAccountSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(BuddyTheme.spacingMd),
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: BuddyTheme.textPrimaryColor,
              ),
            ),
          ),
          _buildMenuOption(
            icon: Icons.person_outline,
            iconColor: BuddyTheme.primaryColor,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildMenuOption(
            icon: Icons.chat_bubble_outline,
            iconColor: BuddyTheme.secondaryColor,
            title: 'Messages',
            onTap: () {},
          ),
          _buildMenuOption(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildMenuOption(
            icon: Icons.security_outlined,
            iconColor: BuddyTheme.successColor,
            title: 'Privacy & Security',
            onTap: () {},
          ),
          _buildMenuOption(
            icon: Icons.favorite_outline,
            iconColor: Colors.amber,
            title: 'My Listings',
            onTap: () {},
          ),
          _buildMenuOption(
            icon: Icons.settings_outlined,
            iconColor: BuddyTheme.textSecondaryColor,
            title: 'Settings',
            onTap: () {},
            isLast: true,
          ),
          Container(
            margin: const EdgeInsets.all(BuddyTheme.spacingMd),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: const Icon(
                Icons.logout,
                size: BuddyTheme.iconSizeMd,
              ),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BuddyTheme.primaryColor,
                side: const BorderSide(color: BuddyTheme.primaryColor),
                padding: const EdgeInsets.symmetric(
                  vertical: BuddyTheme.spacingSm,
                ),
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
            child: Icon(
              icon,
              color: iconColor,
              size: BuddyTheme.iconSizeMd,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: BuddyTheme.textPrimaryColor,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: BuddyTheme.textSecondaryColor,
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
            indent: BuddyTheme.spacingMd + BuddyTheme.iconSizeMd + BuddyTheme.spacingXs,
            endIndent: BuddyTheme.spacingMd,
            color: BuddyTheme.dividerColor,
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
}
