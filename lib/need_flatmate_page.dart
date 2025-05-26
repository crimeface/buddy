import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';

class NeedFlatmatePage extends StatefulWidget {
  const NeedFlatmatePage({super.key});

  @override
  State<NeedFlatmatePage> createState() => _NeedFlatmatePageState();
}

class _NeedFlatmatePageState extends State<NeedFlatmatePage> {
  String _selectedLocation = 'All Cities';
  String _selectedAge = 'All Ages';
  String _selectedProfession = 'All Professions';
  String _selectedGender = 'All';

  final List<String> _locations = [
    'All Cities',
    'New York',
    'Los Angeles',
    'Chicago',
    'Miami',
    'San Francisco',
  ];

  final List<String> _ages = [
    'All Ages',
    '18-25',
    '26-30',
    '31-35',
    '36-40',
    '40+',
  ];

  final List<String> _professions = [
    'All Professions',
    'Student',
    'Software Engineer',
    'Designer',
    'Teacher',
    'Healthcare',
    'Finance',
    'Other',
  ];

  final List<String> _genders = ['All', 'Male', 'Female', 'Non-binary'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF4299E1);
    final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
    final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF718096);
    final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final Color successColor = isDark ? const Color(0xFF81C784) : const Color(0xFF48BB78);
    final Color warningColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFED8936);
    final Color inputFillColor = isDark ? const Color(0xFF23262F) : const Color(0xFFF1F5F9);
    final Color labelColor = textPrimary;
    final Color hintColor = isDark ? Colors.white38 : const Color(0xFFA0AEC0);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 2));
      },
      color: BuddyTheme.primaryColor,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(BuddyTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, textPrimary),
                const SizedBox(height: BuddyTheme.spacingLg),
                _buildSearchSection(context, cardColor, inputFillColor, labelColor, hintColor, borderColor),
                const SizedBox(height: BuddyTheme.spacingMd),                _buildQuickStats(context, cardColor, labelColor, accentColor, textSecondary, borderColor, successColor, warningColor),
                const SizedBox(height: BuddyTheme.spacingMd),
                _buildSectionHeader(context, 'All Flatmates', () {}, labelColor),
                const SizedBox(height: BuddyTheme.spacingSm),
                ..._buildFlatmateListings(context, cardColor, labelColor),
              ],
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
          'Find Your',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
                color: labelColor,
              ),
        ),
        Text(
          'Ideal Flatmate',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: BuddyTheme.primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(BuildContext context, Color cardColor, Color inputFillColor, Color labelColor, Color hintColor, Color borderColor) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            style: TextStyle(color: labelColor),
            decoration: InputDecoration(
              hintText: 'Search by name, interests, profession...',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(
                Icons.search,
                color: labelColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(BuddyTheme.spacingMd),
            ),
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Location', _selectedLocation, _locations, (value) {
                setState(() => _selectedLocation = value);
              }, cardColor, labelColor, borderColor),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip('Age', _selectedAge, _ages, (value) {
                setState(() => _selectedAge = value);
              }, cardColor, labelColor, borderColor),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip('Profession', _selectedProfession, _professions, (value) {
                setState(() => _selectedProfession = value);
              }, cardColor, labelColor, borderColor),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip('Gender', _selectedGender, _genders, (value) {
                setState(() => _selectedGender = value);
              }, cardColor, labelColor, borderColor),
            ],
          ),
        ),
      ],
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
      onTap: () => _showFilterBottomSheet(context, label, options, value, onChanged, cardColor, labelColor),
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

  Widget _buildQuickStats(
      BuildContext context,
      Color cardColor,
      Color labelColor,
      Color accentColor,
      Color textSecondary,
      Color borderColor,
      Color successColor,
      Color warningColor,
    ) {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, '247', 'Active\nFlatmates', accentColor, textSecondary),
          Container(width: 1, height: 40, color: borderColor),
          _buildStatItem(context, '89', 'New This\nWeek', successColor, textSecondary),
          Container(width: 1, height: 40, color: borderColor),
          _buildStatItem(context, '156', 'Verified\nProfiles', warningColor, textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String number,
    String label,
    Color color,
    Color labelColor,
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
            color: labelColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onTap,
    Color labelColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
        ),
      ],
    );
  }
  List<Widget> _buildFlatmateListings(BuildContext context, Color cardColor, Color labelColor) {
    final flatmates = [
      {
        'imageUrl': 'https://randomuser.me/api/portraits/men/12.jpg',
        'name': 'Alex Rodriguez',
        'age': 27,
        'profession': 'Graphic Designer',
        'location': 'Manhattan, NY',
        'budget': '\$800-1200',
        'moveInDate': 'Available Now',
        'interests': ['Photography', 'Fitness', 'Cooking', 'Movies'],
        'lifestyle': ['Non-smoker', 'Pet-friendly', 'Clean'],
        'bio': 'Creative professional looking for a clean, respectful flatmate. Love cooking and exploring the city!',
        'verified': true,
        'rating': '4.9',
        'compatibility': 89,
      },
      {
        'imageUrl': 'https://randomuser.me/api/portraits/women/25.jpg',
        'name': 'Jessica Kim',
        'age': 23,
        'profession': 'Graduate Student',
        'location': 'Brooklyn, NY',
        'budget': '\$600-900',
        'moveInDate': 'March 1',
        'interests': ['Reading', 'Yoga', 'Coffee', 'Study'],
        'lifestyle': ['Quiet', 'Non-smoker', 'Early riser'],
        'bio': 'PhD student seeking a quiet, studious flatmate. Prefer someone who respects study time and personal space.',
        'verified': true,
        'rating': '4.8',
        'compatibility': 76,
      },
      {
        'imageUrl': 'https://randomuser.me/api/portraits/men/33.jpg',
        'name': 'Mike Johnson',
        'age': 29,
        'profession': 'Marketing Manager',
        'location': 'Queens, NY',
        'budget': '\$700-1000',
        'moveInDate': 'Available Now',
        'interests': ['Sports', 'Gaming', 'Socializing', 'Travel'],
        'lifestyle': ['Social', 'Clean', 'Night owl'],
        'bio': 'Outgoing professional who loves hosting friends and weekend adventures. Looking for someone social and fun!',
        'verified': false,
        'rating': '4.6',
        'compatibility': 82,
      },
      {
        'imageUrl': 'https://randomuser.me/api/portraits/women/41.jpg',
        'name': 'Priya Patel',
        'age': 25,
        'profession': 'Software Engineer',
        'location': 'Manhattan, NY',
        'budget': '\$1000-1500',
        'moveInDate': 'February 15',
        'interests': ['Tech', 'Meditation', 'Hiking', 'Cooking'],
        'lifestyle': ['Organized', 'Pet-friendly', 'Health-conscious'],
        'bio': 'Tech professional with a love for outdoor activities and healthy living. Seeking a like-minded flatmate.',
        'verified': true,
        'rating': '5.0',
        'compatibility': 93,
      },
    ];

    return flatmates
        .map(
          (flatmate) => Column(
            children: [
              _buildFlatmateCard(context, flatmate, cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
            ],
          ),
        )
        .toList();
  }

  Widget _buildFlatmateCard(BuildContext context, Map<String, dynamic> flatmate, Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      child: Padding(
        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with photo and basic info
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: cardColor,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: flatmate['imageUrl'],
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: cardColor,
                            highlightColor: BuddyTheme.backgroundPrimaryColor,
                            child: Container(
                              color: cardColor,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            color: labelColor,
                            size: BuddyTheme.iconSizeLg,
                          ),
                        ),
                      ),
                    ),
                    if (flatmate['verified'])
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: BuddyTheme.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: BuddyTheme.backgroundPrimaryColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.verified,
                            color: BuddyTheme.textLightColor,
                            size: BuddyTheme.iconSizeSm,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: BuddyTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            flatmate['name'],
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: labelColor,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: BuddyTheme.spacingXs,
                              vertical: BuddyTheme.spacingXxs,
                            ),
                            decoration: BoxDecoration(
                              color: _getCompatibilityColor(flatmate['compatibility']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusXs),
                              border: Border.all(
                                color: _getCompatibilityColor(flatmate['compatibility']),
                              ),
                            ),
                            child: Text(
                              '${flatmate['compatibility']}% Match',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: _getCompatibilityColor(flatmate['compatibility']),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${flatmate['age']} • ${flatmate['profession']}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: labelColor.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: BuddyTheme.spacingXs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: labelColor.withOpacity(0.7),
                            size: BuddyTheme.iconSizeSm,
                          ),
                          const SizedBox(width: BuddyTheme.spacingXxs),
                          Text(
                            flatmate['location'],
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: labelColor.withOpacity(0.7),
                                ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: BuddyTheme.warningColor,
                                size: BuddyTheme.iconSizeSm,
                              ),
                              const SizedBox(width: BuddyTheme.spacingXxs),
                              Text(
                                flatmate['rating'],
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: labelColor.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BuddyTheme.spacingMd),

            // Budget and Move-in info
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: BuddyTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Range',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: labelColor.withOpacity(0.7),
                              ),
                        ),
                        Text(
                          flatmate['budget'],
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: BuddyTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: BuddyTheme.spacingXs),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: flatmate['moveInDate'] == 'Available Now'
                          ? BuddyTheme.successColor.withOpacity(0.1)
                          : BuddyTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Move-in Date',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: labelColor.withOpacity(0.7),
                              ),
                        ),
                        Text(
                          flatmate['moveInDate'],
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: flatmate['moveInDate'] == 'Available Now'
                                    ? BuddyTheme.successColor
                                    : BuddyTheme.warningColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: BuddyTheme.spacingMd),

            // Bio
            Text(
              flatmate['bio'],
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: labelColor,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: BuddyTheme.spacingSm),

            // Interests
            Text(
              'Interests',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
            ),
            const SizedBox(height: BuddyTheme.spacingXs),
            Wrap(
              spacing: BuddyTheme.spacingXs,
              runSpacing: BuddyTheme.spacingXs,
              children: (flatmate['interests'] as List<String>)
                  .take(4)
                  .map(
                    (interest) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BuddyTheme.spacingXs,
                        vertical: BuddyTheme.spacingXxs,
                      ),
                      decoration: BoxDecoration(
                        color: BuddyTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusXs),
                        border: Border.all(
                          color: BuddyTheme.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        interest,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: BuddyTheme.accentColor,
                              fontSize: BuddyTheme.fontSizeXs,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: BuddyTheme.spacingSm),

            // Lifestyle
            Text(
              'Lifestyle',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
            ),
            const SizedBox(height: BuddyTheme.spacingXs),
            Wrap(
              spacing: BuddyTheme.spacingXs,
              runSpacing: BuddyTheme.spacingXs,
              children: (flatmate['lifestyle'] as List<String>)
                  .map(
                    (trait) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BuddyTheme.spacingXs,
                        vertical: BuddyTheme.spacingXxs,
                      ),
                      decoration: BoxDecoration(
                        color: BuddyTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusXs),
                        border: Border.all(
                          color: BuddyTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: BuddyTheme.successColor,
                            size: BuddyTheme.iconSizeSm,
                          ),
                          const SizedBox(width: BuddyTheme.spacingXxs),
                          Text(
                            trait,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: BuddyTheme.successColor,
                                  fontSize: BuddyTheme.fontSizeXs,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: BuddyTheme.spacingMd),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle message action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BuddyTheme.primaryColor,
                      foregroundColor: BuddyTheme.textLightColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: BuddyTheme.spacingSm,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message, size: BuddyTheme.iconSizeSm),
                        const SizedBox(width: BuddyTheme.spacingXs),
                        Text(
                          'Message',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: BuddyTheme.textLightColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: BuddyTheme.spacingXs),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Handle view profile action
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: BuddyTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: BuddyTheme.spacingSm,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: BuddyTheme.iconSizeSm,
                          color: BuddyTheme.primaryColor,
                        ),
                        const SizedBox(width: BuddyTheme.spacingXs),
                        Text(
                          'View Profile',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: BuddyTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: BuddyTheme.spacingXs),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: BuddyTheme.borderColor),
                    borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                  ),
                  child: IconButton(
                    onPressed: () {
                      _toggleFavorite(flatmate['name']);
                    },
                    icon: Icon(
                      Icons.favorite_border,
                      color: labelColor.withOpacity(0.7),
                      size: BuddyTheme.iconSizeSm,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompatibilityColor(int compatibility) {
    if (compatibility >= 90) return BuddyTheme.successColor;
    if (compatibility >= 80) return BuddyTheme.primaryColor;
    if (compatibility >= 70) return BuddyTheme.warningColor;
    return Colors.redAccent; // fallback for error
  }

  void _toggleFavorite(String flatmateName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $flatmateName to favorites!'),
        backgroundColor: BuddyTheme.successColor,
        duration: const Duration(seconds: 2),
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
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BuddyTheme.borderRadiusMd),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select $title',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: labelColor.withOpacity(0.7),
                      size: BuddyTheme.iconSizeMd,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BuddyTheme.spacingMd),
              ...options
                  .map(
                    (option) => ListTile(
                      title: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: option == currentValue
                                  ? BuddyTheme.primaryColor
                                  : labelColor,
                              fontWeight: option == currentValue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                      trailing: option == currentValue
                          ? Icon(
                              Icons.check,
                              color: BuddyTheme.primaryColor,
                              size: BuddyTheme.iconSizeSm,
                            )
                          : null,
                      onTap: () {
                        onChanged(option);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
              const SizedBox(height: BuddyTheme.spacingMd),
            ],
          ),
        );
      },
    );
  }
}