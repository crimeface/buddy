import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class FlatmateProfileFormPage extends StatefulWidget {
  const FlatmateProfileFormPage({Key? key}) : super(key: key);

  @override
  State<FlatmateProfileFormPage> createState() => _FlatmateProfileFormPageState();
}

class _FlatmateProfileFormPageState extends State<FlatmateProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _bioController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _languagesController = TextEditingController();

  // Form state variables
  String _gender = 'Male';
  String _lookingFor = 'Any';
  String _occupationType = 'Student';
  String _preferredLocation = '';
  String _moveInDate = 'Immediately';
  String _stayDuration = '6 months';
  String _drinkingHabits = 'No';
  String _smokingHabits = 'No';
  String _foodPreference = 'Vegetarian';
  String _personalityType = 'Introvert';
  bool _hasPets = false;
  bool _petsAllowed = true;
  bool _partiesAllowed = false;
  bool _cookingAllowed = true;
  bool _guestsAllowed = true;
  bool _musicAllowed = true;
  bool _cleaningShared = true;
  List<String> _selectedInterests = [];
  List<String> _selectedAmenities = [];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _lookingForOptions = ['Any', 'Male Only', 'Female Only', 'Mixed'];
  final List<String> _occupationTypes = ['Student', 'Professional', 'Freelancer', 'Entrepreneur', 'Job Seeker'];
  final List<String> _moveInDates = ['Immediately', 'Within a week', 'Within a month', '1-3 months', 'Flexible'];
  final List<String> _stayDurations = ['3 months', '6 months', '1 year', '2+ years', 'Flexible'];
  final List<String> _drinkingOptions = ['No', 'Socially', 'Regularly'];
  final List<String> _smokingOptions = ['No', 'Occasionally', 'Regularly'];
  final List<String> _foodPreferences = ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Jain', 'No Preference'];
  final List<String> _personalityTypes = ['Introvert', 'Extrovert', 'Ambivert'];
  final List<String> _interests = [
    'Reading', 'Movies', 'Music', 'Sports', 'Gaming', 'Cooking', 'Travel',
    'Photography', 'Dancing', 'Gym', 'Yoga', 'Art', 'Technology', 'Fashion'
  ];
  final List<String> _amenities = [
    'WiFi', 'AC', 'Washing Machine', 'Fridge', 'TV', 'Gym', 'Swimming Pool',
    'Parking', 'Security', 'Elevator', 'Balcony', 'Garden'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _workplaceController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _bioController.dispose();
    _hobbiesController.dispose();
    _languagesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final inputFillColor = isDark ? Colors.grey[850] : Colors.grey[100];
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final iconColor = isDark ? Colors.white : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Flatmate Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImageSection(cardColor!, iconColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingLg),

              _buildSectionTitle('Personal Information', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildNameField(inputFillColor!, labelColor, hintColor, iconColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              Row(
                children: [
                  Expanded(child: _buildAgeField(inputFillColor, labelColor, hintColor)),
                  const SizedBox(width: BuddyTheme.spacingMd),
                  Expanded(child: _buildGenderDropdown(cardColor, labelColor)),
                ],
              ),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildPhoneField(inputFillColor, labelColor, hintColor, iconColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildEmailField(inputFillColor, labelColor, hintColor, iconColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Professional Information', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildOccupationTypeDropdown(cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildOccupationField(inputFillColor, labelColor, hintColor, iconColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildWorkplaceField(inputFillColor, labelColor, hintColor, iconColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Housing Preferences', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildLookingForDropdown(cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildBudgetSection(cardColor, labelColor, inputFillColor, hintColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildMoveInDateDropdown(cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildStayDurationDropdown(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Lifestyle & Habits', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildHabitsSection(cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildPersonalitySection(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('House Rules & Preferences', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildHouseRulesSection(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Interests & Hobbies', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildInterestsSection(cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildLanguagesField(inputFillColor, labelColor, hintColor, iconColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Preferred Amenities', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildAmenitiesSection(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('About You', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildBioField(inputFillColor, labelColor, hintColor),

              const SizedBox(height: BuddyTheme.spacingXl),
              _buildSubmitButton(),
              const SizedBox(height: BuddyTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color labelColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: BuddyTheme.fontSizeLg,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
    );
  }

  Widget _buildProfileImageSection(Color cardColor, Color iconColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingLg),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: BuddyTheme.primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 50,
              color: iconColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          ElevatedButton.icon(
            onPressed: _selectProfileImage,
            icon: Icon(Icons.camera_alt, color: iconColor),
            label: Text('Add Profile Photo', style: TextStyle(color: labelColor)),
            style: ElevatedButton.styleFrom(
              backgroundColor: BuddyTheme.primaryColor.withOpacity(0.1),
              foregroundColor: BuddyTheme.primaryColor,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(Color fillColor, Color labelColor, Color hintColor, Color iconColor) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter your full name',
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.person_outline, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _ageController,
      decoration: InputDecoration(
        labelText: 'Age',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Age',
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter age';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown(Color cardColor, Color labelColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
      child: DropdownButton<String>(
        value: _gender,
        isExpanded: true,
        underline: Container(),
        hint: Text('Gender', style: TextStyle(color: labelColor)),
        items: _genders.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: labelColor)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _gender = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildPhoneField(Color fillColor, Color labelColor, Color hintColor, Color iconColor) {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter your phone number',
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.phone_outlined, color: iconColor),
        prefixText: '+91 ',
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        if (value.length != 10) {
          return 'Please enter valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField(Color fillColor, Color labelColor, Color hintColor, Color iconColor) {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter your email',
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.email_outlined, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter email';
        }
        if (!value.contains('@')) {
          return 'Please enter valid email';
        }
        return null;
      },
    );
  }

  Widget _buildOccupationTypeDropdown(Color cardColor, Color labelColor) {
    return _buildDropdownContainer(
      'Occupation Type',
      _occupationType,
      _occupationTypes,
      (value) => setState(() => _occupationType = value!),
      cardColor,
      labelColor,
    );
  }

  Widget _buildOccupationField(Color fillColor, Color labelColor, Color hintColor, Color iconColor) {
    return TextFormField(
      controller: _occupationController,
      decoration: InputDecoration(
        labelText: 'Occupation/Course',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'e.g., Software Engineer, MBA Student',
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.work_outline, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your occupation';
        }
        return null;
      },
    );
  }

  Widget _buildWorkplaceField(Color fillColor, Color labelColor, Color hintColor, Color iconColor) {
    return TextFormField(
      controller: _workplaceController,
      decoration: InputDecoration(
        labelText: 'Company/College',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter your workplace or college',
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.business_outlined, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLookingForDropdown(Color cardColor, Color labelColor) {
    return _buildDropdownContainer(
      'Looking for Flatmates',
      _lookingFor,
      _lookingForOptions,
      (value) => setState(() => _lookingFor = value!),
      cardColor,
      labelColor,
    );
  }

  Widget _buildBudgetSection(Color cardColor, Color labelColor, Color fillColor, Color hintColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Range (₹/month)',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _budgetMinController,
                  decoration: InputDecoration(
                    labelText: 'Min Budget',
                    labelStyle: TextStyle(color: labelColor),
                    prefixText: '₹ ',
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter min budget';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Expanded(
                child: TextFormField(
                  controller: _budgetMaxController,
                  decoration: InputDecoration(
                    labelText: 'Max Budget',
                    labelStyle: TextStyle(color: labelColor),
                    prefixText: '₹ ',
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter max budget';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoveInDateDropdown(Color cardColor, Color labelColor) {
    return _buildDropdownContainer(
      'Move-in Date',
      _moveInDate,
      _moveInDates,
      (value) => setState(() => _moveInDate = value!),
      cardColor,
      labelColor,
    );
  }

  Widget _buildStayDurationDropdown(Color cardColor, Color labelColor) {
    return _buildDropdownContainer(
      'Stay Duration',
      _stayDuration,
      _stayDurations,
      (value) => setState(() => _stayDuration = value!),
      cardColor,
      labelColor,
    );
  }

  Widget _buildHabitsSection(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifestyle Habits',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          _buildHabitRow('Drinking', _drinkingHabits, _drinkingOptions,
              (value) => setState(() => _drinkingHabits = value!), labelColor),
          _buildHabitRow('Smoking', _smokingHabits, _smokingOptions,
              (value) => setState(() => _smokingHabits = value!), labelColor),
          _buildHabitRow('Food Preference', _foodPreference, _foodPreferences,
              (value) => setState(() => _foodPreference = value!), labelColor),
        ],
      ),
    );
  }

  Widget _buildHabitRow(String label, String value, List<String> options, Function(String?) onChanged, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingMd),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: BuddyTheme.fontSizeSm, color: labelColor)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
              ),
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                underline: Container(),
                items: options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: TextStyle(color: labelColor)),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality & Pets',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          _buildHabitRow('Personality', _personalityType, _personalityTypes,
              (value) => setState(() => _personalityType = value!), labelColor),
          CheckboxListTile(
            title: Text('I have pets', style: TextStyle(color: labelColor)),
            value: _hasPets,
            onChanged: (bool? value) {
              setState(() {
                _hasPets = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildHouseRulesSection(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House Rules Preferences',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          _buildRuleCheckbox('Pets allowed', _petsAllowed, (value) => setState(() => _petsAllowed = value!), labelColor),
          _buildRuleCheckbox('Parties allowed', _partiesAllowed, (value) => setState(() => _partiesAllowed = value!), labelColor),
          _buildRuleCheckbox('Cooking allowed', _cookingAllowed, (value) => setState(() => _cookingAllowed = value!), labelColor),
          _buildRuleCheckbox('Guests allowed', _guestsAllowed, (value) => setState(() => _guestsAllowed = value!), labelColor),
          _buildRuleCheckbox('Music allowed', _musicAllowed, (value) => setState(() => _musicAllowed = value!), labelColor),
          _buildRuleCheckbox('Cleaning shared', _cleaningShared, (value) => setState(() => _cleaningShared = value!), labelColor),
        ],
      ),
    );
  }

  Widget _buildRuleCheckbox(String title, bool value, Function(bool?) onChanged, Color labelColor) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(color: labelColor)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildInterestsSection(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Wrap(
            spacing: BuddyTheme.spacingXs,
            runSpacing: BuddyTheme.spacingXs,
            children: _interests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest, style: TextStyle(color: labelColor)),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                backgroundColor: cardColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesField(Color fillColor, Color labelColor, Color hintColor, Color iconColor) {
    return TextFormField(
      controller: _languagesController,
      decoration: InputDecoration(
        labelText: 'Languages Known',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'e.g., English, Hindi, Tamil',
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.language_outlined, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAmenitiesSection(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred Amenities',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Wrap(
            spacing: BuddyTheme.spacingXs,
            runSpacing: BuddyTheme.spacingXs,
            children: _amenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity, style: TextStyle(color: labelColor)),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                backgroundColor: cardColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _bioController,
      decoration: InputDecoration(
        labelText: 'About Yourself',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Tell potential flatmates about yourself, your routine, expectations, etc.',
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please write something about yourself';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownContainer(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
    Color cardColor,
    Color labelColor,
  ) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: Container(),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option, style: TextStyle(color: labelColor)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: BuddyTheme.postAdButtonStyle,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: BuddyTheme.spacingMd),
          child: Text(
            'Create Profile',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _selectProfileImage() {
    // Handle profile image selection
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle camera
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle gallery
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle form submission
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success!'),
          content: const Text('Your flatmate profile has been created successfully. Other users can now contact you!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}