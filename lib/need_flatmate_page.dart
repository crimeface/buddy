import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme.dart';
import 'display pages/flatmate_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NeedFlatmatePage extends StatefulWidget {
  final String selectedCity;
  const NeedFlatmatePage({super.key, required this.selectedCity});

  @override
  State<NeedFlatmatePage> createState() => _NeedFlatmatePageState();
}

class _NeedFlatmatePageState extends State<NeedFlatmatePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLocation = 'All Cities';
  String _selectedAge = 'All Ages';
  String _selectedProfession = 'All Professions';
  String _selectedGender = 'All';

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

  List<Map<String, dynamic>> _flatmates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = (widget.selectedCity.isNotEmpty && widget.selectedCity != 'Select Location') ? widget.selectedCity : 'All Cities';
    _fetchFlatmates();
  }

  Future<void> _fetchFlatmates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final now = DateTime.now();
      var query = FirebaseFirestore.instance
          .collection('roomRequests')
          .where('visibility', isEqualTo: true);
      if (widget.selectedCity.isNotEmpty && widget.selectedCity != 'All Cities' && widget.selectedCity != 'Select Location') {
        query = query.where('city', isEqualTo: widget.selectedCity);
      }
      final querySnapshot = await query.get();

      final List<Map<String, dynamic>> loaded = [];
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in querySnapshot.docs) {
        final flatmate = doc.data();
        DateTime? expiryDate;

        // Handle different expiry date formats
        if (flatmate['expiryDate'] != null) {
          if (flatmate['expiryDate'] is Timestamp) {
            expiryDate = (flatmate['expiryDate'] as Timestamp).toDate();
          } else if (flatmate['expiryDate'] is String) {
            expiryDate = DateTime.tryParse(flatmate['expiryDate']);
          }
        }

        // If expired, update visibility to false
        if (expiryDate != null && expiryDate.isBefore(now)) {
          batch.update(doc.reference, {'visibility': false});
          continue; // Skip adding to loaded list since it's expired
        }

        // If not expired and visible, add to the list to display
        if (flatmate['visibility'] == true) {
          flatmate['key'] = doc.id;
          loaded.add(flatmate);
        }
      }

      // Commit all visibility updates in one batch
      await batch.commit();

      // Sort flatmates by createdAt timestamp, newest first
      loaded.sort((a, b) {
        var aTime = a['createdAt'];
        var bTime = b['createdAt'];

        // Convert to DateTime if needed
        if (aTime is Timestamp) {
          aTime = aTime.toDate();
        } else if (aTime is String) {
          aTime = DateTime.tryParse(aTime);
        }

        if (bTime is Timestamp) {
          bTime = bTime.toDate();
        } else if (bTime is String) {
          bTime = DateTime.tryParse(bTime);
        }

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _flatmates = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _flatmates = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load flatmates: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredFlatmates {
    return _flatmates.where((flatmate) {
      final matchesLocation =
          _selectedLocation == 'All Cities' ||
          (flatmate['preferredLocation']?.toString().toLowerCase().contains(
                _selectedLocation.toLowerCase(),
              ) ??
              false);
      final matchesAge =
          _selectedAge == 'All Ages' ||
          (() {
            final ageStr = flatmate['age']?.toString();
            if (ageStr == null || ageStr.isEmpty) return false;
            final age = int.tryParse(ageStr);
            if (age == null) return false;
            if (_selectedAge == '40+') return age >= 40;
            final parts = _selectedAge.split('-');
            if (parts.length == 2) {
              final min = int.tryParse(parts[0]);
              final max = int.tryParse(parts[1]);
              if (min != null && max != null) {
                return age >= min && age <= max;
              }
            }
            return false;
          })();
      final matchesProfession =
          _selectedProfession == 'All Professions' ||
          (flatmate['occupation']?.toString().toLowerCase() ==
              _selectedProfession.toLowerCase());
      final matchesGender =
          _selectedGender == 'All' ||
          (flatmate['gender']?.toString().toLowerCase() ==
              _selectedGender.toLowerCase());
      return matchesLocation &&
          matchesAge &&
          matchesProfession &&
          matchesGender;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF2D3748);
    final Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final Color inputFillColor =
        isDark ? const Color(0xFF23262F) : const Color(0xFFF1F5F9);
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
                _buildSearchSection(
                  context,
                  cardColor,
                  inputFillColor,
                  labelColor,
                  hintColor,
                  borderColor,
                ),
                const SizedBox(height: BuddyTheme.spacingMd),
                _buildSectionHeader(
                  context,
                  'All Flatmates',
                  () {},
                  labelColor,
                ),
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
          style: Theme.of(
            context,
          ).textTheme.displaySmall!.copyWith(color: labelColor),
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

  Widget _buildSearchSection(
    BuildContext context,
    Color cardColor,
    Color inputFillColor,
    Color labelColor,
    Color hintColor,
    Color borderColor,
  ) {
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
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(color: labelColor),
            decoration: InputDecoration(
              hintText: 'Search by name, interests, profession...',
              hintStyle: TextStyle(
                color: labelColor,
              ), // Updated to use labelColor instead of hintColor
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey,
              ), // Updated to use grey color
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(BuddyTheme.spacingMd),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Age',
                _selectedAge,
                _ages,
                (value) {
                  setState(() => _selectedAge = value);
                },
                cardColor,
                labelColor,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Profession',
                _selectedProfession,
                _professions,
                (value) {
                  setState(() => _selectedProfession = value);
                },
                cardColor,
                labelColor,
                borderColor,
              ),
              const SizedBox(width: BuddyTheme.spacingXs),
              _buildFilterChip(
                'Gender',
                _selectedGender,
                _genders,
                (value) {
                  setState(() => _selectedGender = value);
                },
                cardColor,
                labelColor,
                borderColor,
              ),
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
      onTap:
          () => _showFilterBottomSheet(
            context,
            label,
            options,
            value,
            onChanged,
            cardColor,
            labelColor,
          ),
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

  List<Widget> _buildFlatmateListings(
    BuildContext context,
    Color cardColor,
    Color labelColor,
  ) {
    if (_isLoading) {
      return [const Center(child: CircularProgressIndicator())];
    }
    if (_filteredFlatmates.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              "No flatmates found.",
              style: TextStyle(
                fontSize: 18,
                color: labelColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ];
    }
    return _filteredFlatmates
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

  Widget _buildFlatmateCard(
    BuildContext context,
    Map<String, dynamic> flatmate,
    Color cardColor,
    Color labelColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor =
        isDark ? const Color(0xFF64B5F6) : const Color(0xFF4299E1);
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
                CircleAvatar(
                  radius: 35,
                  backgroundColor: cardColor,
                  backgroundImage:
                      flatmate['profilePhotoUrl'] != null
                          ? NetworkImage(flatmate['profilePhotoUrl'])
                          : null,
                  child:
                      flatmate['profilePhotoUrl'] == null
                          ? Icon(
                            Icons.person,
                            color: labelColor,
                            size: BuddyTheme.iconSizeLg,
                          )
                          : null,
                ),
                const SizedBox(width: BuddyTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flatmate['name'] ?? 'No Name',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        ),
                      ),
                      Text(
                        '${flatmate['age'] ?? ''} • ${flatmate['occupation'] ?? ''}',
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
                            flatmate['location'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(color: labelColor.withOpacity(0.7)),
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
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Range',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: labelColor.withOpacity(0.7)),
                        ),
                        Text(
                          '₹${flatmate['minBudget'] ?? ''} - ₹${flatmate['maxBudget'] ?? ''}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
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
                      color: BuddyTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Move-in Date',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: labelColor.withOpacity(0.7)),
                        ),
                        Text(
                          flatmate['moveInDate'] != null
                              ? (flatmate['moveInDate'] is Timestamp
                                  ? _formatDate(
                                    (flatmate['moveInDate'] as Timestamp)
                                        .toDate(),
                                  )
                                  : (DateTime.tryParse(
                                            flatmate['moveInDate'].toString(),
                                          ) !=
                                          null
                                      ? _formatDate(
                                        DateTime.parse(
                                          flatmate['moveInDate'].toString(),
                                        ),
                                      )
                                      : ''))
                              : '',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            color: BuddyTheme.successColor,
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
            // Bio only if available
            if (flatmate['bio']?.isNotEmpty ?? false) ...[
              Text(
                flatmate['bio']!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: labelColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: BuddyTheme.spacingSm),
            ],
            // Interests (if you store them as a list)
            if (flatmate['interests'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    children:
                        (flatmate['interests'] as List)
                            .map<Widget>(
                              (interest) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BuddyTheme.spacingXs,
                                  vertical: BuddyTheme.spacingXxs,
                                ),
                                decoration: BoxDecoration(
                                  color: BuddyTheme.accentColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    BuddyTheme.borderRadiusXs,
                                  ),
                                  border: Border.all(
                                    color: BuddyTheme.accentColor.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.copyWith(
                                    color: BuddyTheme.accentColor,
                                    fontSize: BuddyTheme.fontSizeXs,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                ],
              ),
            // View Detail Button
            const SizedBox(height: BuddyTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _viewFlatmateDetails(flatmate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusSm,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: BuddyTheme.iconSizeSm,
                      color: Colors.white,
                    ),
                    const SizedBox(width: BuddyTheme.spacingXs),
                    Text(
                      'View Details',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFlatmateDetails(Map<String, dynamic> flatmate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlatmateDetailsPage(flatmateData: flatmate),
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
      isScrollControlled: true, // <-- Add this line
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BuddyTheme.borderRadiusMd),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          // <-- Wrap in SafeArea
          child: SingleChildScrollView(
            // <-- Wrap in SingleChildScrollView
            child: Container(
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.copyWith(
                              color:
                                  option == currentValue
                                      ? BuddyTheme.primaryColor
                                      : labelColor,
                              fontWeight:
                                  option == currentValue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          trailing:
                              option == currentValue
                                  ? Icon(
                                    Icons.check,
                                    color: BuddyTheme.primaryColor,
                                  )
                                  : null,
                          onTap: () {
                            onChanged(option);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
