import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class FlatmateDetailsPage extends StatelessWidget {
  final Map<String, dynamic> flatmateData;

  const FlatmateDetailsPage({Key? key, required this.flatmateData})
    : super(key: key);

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Flexible';
    try {
      if (dateValue is Timestamp) {
        final dt = dateValue.toDate();
        return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      } else if (dateValue is DateTime) {
        return '${dateValue.day.toString().padLeft(2, '0')}-${dateValue.month.toString().padLeft(2, '0')}-${dateValue.year}';
      } else if (dateValue is String && dateValue.isNotEmpty) {
        final dt = DateTime.tryParse(dateValue);
        if (dt != null) {
          return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
        }
        // fallback: try to format as DD-MM-YYYY if string is already in that format
        final parts = dateValue.split('T')[0].split('-');
        if (parts.length == 3) {
          return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
        }
        return dateValue;
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Basic Information'),
            _buildBasicInformation(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Budget & Timeline'),
            _buildBudgetAndMoveIn(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Room Preferences'),
            _buildRoomPreferences(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Flatmate Preferences'),
            _buildFlatmatePreferences(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Lifestyle Preferences'),
            _buildLifestylePreferences(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            if (flatmateData['bio']?.isNotEmpty ?? false) ...[
              _buildSectionHeader(theme, 'About'),
              _buildAboutSection(theme),
              const SizedBox(height: BuddyTheme.spacingXl),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    // Use this for all cardColor assignments in your widgets
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(
              Colors.white.withOpacity(0.06),
              theme.cardColor,
            ) // lighter in dark mode
            : Color.alphaBlend(
              Colors.black.withOpacity(0.04),
              theme.cardColor,
            ); // darker in light mode
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: BuddyTheme.secondaryColor,
            backgroundImage:
                flatmateData['profilePhotoUrl'] != null
                    ? NetworkImage(flatmateData['profilePhotoUrl'])
                    : null,
            child:
                flatmateData['profilePhotoUrl'] == null
                    ? Text(
                      flatmateData['name']?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeXl,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondary,
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXxs),
                Text(
                  '${flatmateData['age'] ?? 'N/A'} • ${flatmateData['occupation'] ?? 'N/A'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: BuddyTheme.iconSizeSm,
                      color: textSecondary,
                    ),
                    const SizedBox(width: BuddyTheme.spacingXxs),
                    Expanded(
                      child: Text(
                        flatmateData['location'] ?? 'Location not specified',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildBasicInformation(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.person,
            title: 'Gender',
            value: flatmateData['gender'] ?? 'Not specified',
            iconColor: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.work,
            title: 'Occupation',
            value: flatmateData['occupation'] ?? 'Not specified',
            iconColor: BuddyTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetAndMoveIn(ThemeData theme) {
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Row(
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
                Text(
                  'Budget Range',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  '₹${flatmateData['minBudget'] ?? '0'} - ₹${flatmateData['maxBudget'] ?? '0'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: BuddyTheme.primaryColor,
                    fontWeight: FontWeight.bold,
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
                Text(
                  'Move-in Date',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  _formatDate(flatmateData['moveInDate']),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: BuddyTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomPreferences(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.bed,
            title: 'Room Type',
            value: flatmateData['preferredRoomType'] ?? 'Any',
            iconColor: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.chair,
            title: 'Furnishing',
            value: flatmateData['furnishingPreference'] ?? 'Any',
            iconColor: BuddyTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFlatmatePreferences(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.group,
            title: 'Number of Flatmates',
            value: flatmateData['preferredFlatmates']?.toString() ?? 'Any',
            iconColor: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.people,
            title: 'Flatmate Gender',
            value: flatmateData['preferredFlatmateGender'] ?? 'Any',
            iconColor: BuddyTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLifestylePreferences(ThemeData theme) {
    // Use this for all cardColor assignments in your widgets
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(
              Colors.white.withOpacity(0.06),
              theme.cardColor,
            ) // lighter in dark mode
            : Color.alphaBlend(
              Colors.black.withOpacity(0.04),
              theme.cardColor,
            ); // darker in light mode

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        children: [
          _buildPreferenceRow(
            theme,
            Icons.restaurant,
            'Food Preference',
            flatmateData['foodPreference'] ?? 'No preference',
          ),
          Divider(height: BuddyTheme.spacingLg),
          _buildPreferenceRow(
            theme,
            Icons.smoking_rooms,
            'Smoking',
            flatmateData['smokingPreference'] ?? 'No preference',
          ),
          Divider(height: BuddyTheme.spacingLg),
          _buildPreferenceRow(
            theme,
            Icons.local_bar,
            'Drinking',
            flatmateData['drinkingPreference'] ?? 'No preference',
          ),
          Divider(height: BuddyTheme.spacingLg),
          _buildPreferenceRow(
            theme,
            Icons.bedroom_parent,
            'Flat Size Preference',
            flatmateData['preferredRoomSize'] ?? 'No preference',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    final cardColor = theme.cardColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      width: double.infinity,
      child: Text(
        flatmateData['bio']!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    // Use this for all cardColor assignments in your widgets
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(
              Colors.white.withOpacity(0.06),
              theme.cardColor,
            ) // lighter in dark mode
            : Color.alphaBlend(
              Colors.black.withOpacity(0.04),
              theme.cardColor,
            ); // darker in light mode
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: Icon(icon, color: iconColor, size: BuddyTheme.iconSizeMd),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: BuddyTheme.fontSizeXs,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BuddyTheme.spacingXxs),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(
    ThemeData theme,
    IconData icon,
    String title,
    String value,
  ) {
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Row(
      children: [
        Icon(icon, color: BuddyTheme.primaryColor, size: BuddyTheme.iconSizeMd),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
        ),
      ],
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
                  final Uri phoneUri = Uri(scheme: 'tel', path: flatmateData['phone'] ?? '');
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
                    path: flatmateData['email'],
                    query: 'subject=Enquiry about ${flatmateData['email']}',
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