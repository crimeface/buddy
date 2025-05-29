import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class FlatmateDetailsPage extends StatelessWidget {
  final Map<String, dynamic> flatmateData;

  const FlatmateDetailsPage({
    Key? key,
    required this.flatmateData,
  }) : super(key: key);

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Flexible';
    try {
      final parts = dateString.split('T')[0].split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuddyTheme.backgroundPrimaryColor,
      appBar: AppBar(
        backgroundColor: BuddyTheme.backgroundPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BuddyTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildBasicInformation(),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildBudgetAndMoveIn(),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildRoomPreferences(),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildFlatmatePreferences(),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildLifestylePreferences(),
            const SizedBox(height: BuddyTheme.spacingLg),
            if (flatmateData['bio']?.isNotEmpty ?? false) ...[
              _buildAboutSection(),
              const SizedBox(height: BuddyTheme.spacingXl),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BuddyTheme.cardDecoration,
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: BuddyTheme.secondaryColor,
            backgroundImage: flatmateData['imageUrl'] != null
                ? NetworkImage(flatmateData['imageUrl'])
                : null,
            child: flatmateData['imageUrl'] == null
                ? Text(
                    flatmateData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: BuddyTheme.fontSizeXl,
                      fontWeight: FontWeight.bold,
                      color: BuddyTheme.textLightColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: BuddyTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flatmateData['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: BuddyTheme.fontSizeXl,
                    fontWeight: FontWeight.bold,
                    color: BuddyTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXxs),
                Text(
                  '${flatmateData['age'] ?? 'N/A'} • ${flatmateData['occupation'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: BuddyTheme.fontSizeMd,
                    color: BuddyTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: BuddyTheme.iconSizeSm,
                      color: BuddyTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: BuddyTheme.spacingXxs),
                    Expanded(
                      child: Text(
                        flatmateData['preferredLocation'] ?? 'Location not specified',
                        style: const TextStyle(
                          fontSize: BuddyTheme.fontSizeSm,
                          color: BuddyTheme.textSecondaryColor,
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
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
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
              child: _buildInfoCard(
                icon: Icons.person,
                title: 'Gender',
                value: flatmateData['gender'] ?? 'Not specified',
                iconColor: BuddyTheme.primaryColor,
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.work,
                title: 'Occupation',
                value: flatmateData['occupation'] ?? 'Not specified',
                iconColor: BuddyTheme.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetAndMoveIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget & Timeline',
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
                    const Text(
                      'Budget Range',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      '₹${flatmateData['minBudget'] ?? '0'} - ₹${flatmateData['maxBudget'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: BuddyTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                ),
                padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Move-in Date',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeSm,
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      _formatDate(flatmateData['moveInDate']),
                      style: const TextStyle(
                        fontSize: BuddyTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: BuddyTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Preferences',
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
              child: _buildInfoCard(
                icon: Icons.bed,
                title: 'Room Type',
                value: flatmateData['preferredRoomType'] ?? 'Any',
                iconColor: BuddyTheme.primaryColor,
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.chair,
                title: 'Furnishing',
                value: flatmateData['furnishingPreference'] ?? 'Any',
                iconColor: BuddyTheme.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlatmatePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flatmate Preferences',
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
              child: _buildInfoCard(
                icon: Icons.group,
                title: 'Number of Flatmates',
                value: flatmateData['preferredFlatmates']?.toString() ?? 'Any',
                iconColor: BuddyTheme.primaryColor,
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.people,
                title: 'Flatmate Gender',
                value: flatmateData['preferredFlatmateGender'] ?? 'Any',
                iconColor: BuddyTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLifestylePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lifestyle Preferences',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: BuddyTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BuddyTheme.cardDecoration,
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Column(
            children: [
              _buildPreferenceRow(
                Icons.restaurant,
                'Food Preference',
                flatmateData['foodPreference'] ?? 'No preference',
              ),
              const Divider(height: BuddyTheme.spacingLg),
              _buildPreferenceRow(
                Icons.smoking_rooms,
                'Smoking',
                flatmateData['smokingPreference'] ?? 'No preference',
              ),
              const Divider(height: BuddyTheme.spacingLg),
              _buildPreferenceRow(
                Icons.local_bar,
                'Drinking',
                flatmateData['drinkingPreference'] ?? 'No preference',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    if (flatmateData['bio']?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: BuddyTheme.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: BuddyTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Container(
          decoration: BuddyTheme.cardDecoration,
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          width: double.infinity,
          child: Text(
            flatmateData['bio']!,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              color: BuddyTheme.textPrimaryColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      decoration: BuddyTheme.cardDecoration,
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        children: [
          Container(
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
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            title,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeXs,
              color: BuddyTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BuddyTheme.spacingXxs),
          Text(
            value,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: BuddyTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: BuddyTheme.primaryColor,
          size: BuddyTheme.iconSizeMd,
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              color: BuddyTheme.textPrimaryColor,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: BuddyTheme.fontSizeMd,
            color: BuddyTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: const BoxDecoration(
        color: BuddyTheme.backgroundPrimaryColor,
        border: Border(
          top: BorderSide(color: BuddyTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final Uri callUri = Uri.parse('tel:${flatmateData['phone']}');
                if (await canLaunchUrl(callUri)) {
                  await launchUrl(callUri);
                }
              },
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: BuddyTheme.spacingSm),
              ),
            ),
          ),
          const SizedBox(width: BuddyTheme.spacingMd),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final Uri smsUri = Uri.parse('sms:${flatmateData['phone']}');
                if (await canLaunchUrl(smsUri)) {
                  await launchUrl(smsUri);
                }
              },
              icon: const Icon(Icons.message),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: BuddyTheme.spacingSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
