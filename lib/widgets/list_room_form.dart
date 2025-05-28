import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:firebase_database/firebase_database.dart';

class ListRoomForm extends StatefulWidget {
  const ListRoomForm({Key? key}) : super(key: key);

  @override
  State<ListRoomForm> createState() => _ListRoomFormState();
}

class _ListRoomFormState extends State<ListRoomForm>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  int _currentStep = 0;
  final int _totalSteps = 7;

  // Form controllers and data
  final _formKey = GlobalKey<FormState>();

  // Flat Details
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationUrlController =
      TextEditingController(); // Not used in this example
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  DateTime? _availableFromDate;
  String _roomType = 'Private';
  String _flatSize = '1BHK';
  String _furnishing = 'Furnished';
  bool _hasAttachedBathroom = true;

  // Current Flatmate Details
  int _currentFlatmates = 1;
  int _maxFlatmates = 2; // Assuming max 2 flatmates for simplicity
  String _genderComposition = 'Mixed';
  String _occupation = 'Mixed';

  // Facilities
  Map<String, bool> _facilities = {
    'WiFi': false,
    'Geyser': false,
    'Washing Machine': false,
    'Refrigerator': false,
    'Parking': false,
    'Power Backup': false,
    'Balcony': false,
    'Gym': false,
  };

  // Preferences
  String _lookingFor = 'Any';
  String _foodPreference = 'Doesn\'t Matter';
  String _smokingPolicy = 'Not Allowed';
  String _drinkingPolicy = 'Not Allowed';
  String _petsPolicy = 'Not Allowed';
  String _guestsPolicy = 'Allowed';

  // Photos
  List<String> _uploadedPhotos = [];
  final List<String> _requiredPhotoTypes = [
    'Room',
    'Washroom',
    'Kitchen',
    'Building',
  ];

  // Contact Details
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  // Add these theme variables
  late ThemeData theme;
  late Color scaffoldBg;
  late Color cardColor;
  late Color textPrimary;
  late Color textSecondary;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _progressAnimationController.forward();
    _slideAnimationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _slideAnimationController.dispose();
    _fabAnimationController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
      _triggerSlideAnimation();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
      _triggerSlideAnimation();
    }
  }

  void _updateProgress() {
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  void _triggerSlideAnimation() {
    _slideAnimationController.reset();
    _slideAnimationController.forward();
  }

  void _submitForm() async {
    // Validate form if needed
    // if (!_formKey.currentState!.validate()) return;

    // Prepare data
    final data = {
      'title': _titleController.text,
      'location': _locationController.text,
      'locationUrl': _locationUrlController.text,
      'rent': _rentController.text,
      'deposit': _depositController.text,
      'availableFromDate': _availableFromDate?.toIso8601String(),
      'roomType': _roomType,
      'flatSize': _flatSize,
      'furnishing': _furnishing,
      'hasAttachedBathroom': _hasAttachedBathroom,
      'currentFlatmates': _currentFlatmates,
      'maxFlatmates': _maxFlatmates,
      'genderComposition': _genderComposition,
      'occupation': _occupation,
      'facilities': _facilities,
      'lookingFor': _lookingFor,
      'foodPreference': _foodPreference,
      'smokingPolicy': _smokingPolicy,
      'drinkingPolicy': _drinkingPolicy,
      'petsPolicy': _petsPolicy,
      'guestsPolicy': _guestsPolicy,
      'uploadedPhotos': _uploadedPhotos,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'notes': _notesController.text,
      'createdAt': DateTime.now().toIso8601String(),
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
      // Not used in this example
    };

    try {
      final dbRef = FirebaseDatabase.instance.ref().child('room_listings');
      await dbRef.push().set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Room listing submitted successfully!'),
          backgroundColor: BuddyTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    scaffoldBg = theme.scaffoldBackgroundColor;
    // Custom card color for better contrast
    cardColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFF23262F)
            : const Color.fromARGB(255, 226, 227, 231);
    textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    textSecondary =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('List Your Room'),
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: BuddyTheme.spacingMd),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BuddyTheme.spacingSm,
                  vertical: BuddyTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: BuddyTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusSm,
                  ),
                ),
                child: Text(
                  'Step ${_currentStep + 1}/$_totalSteps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: BuddyTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFlatDetailsStep(),
                _buildLocationAndDateStep(),
                _buildPricingStep(),
                _buildFlatmateDetailsStep(),
                _buildFacilitiesStep(),
                _buildPreferencesStep(),
                _buildPhotosAndContactStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingLg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BuddyTheme.textSecondaryColor,
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Text(
                    '${((_currentStep + _progressAnimation.value) / _totalSteps * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BuddyTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: (_currentStep + _progressAnimation.value) / _totalSteps,
                backgroundColor: BuddyTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  BuddyTheme.primaryColor,
                ),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({required Widget child}) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(BuddyTheme.spacingLg),
        child: child,
      ),
    );
  }

  Widget _buildFlatDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('🏠 Flat Details', 'Tell us about your property'),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _titleController,
              label: 'Listing Title',
              hint: 'e.g., 1 BHK Flat in Kothrud, Pune – One Room Available',
              icon: Icons.title,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Room Type',
              _roomType,
              ['Private', 'Shared Room'],
              (value) => setState(() => _roomType = value),
              Icons.bed_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Flat Size',
              _flatSize,
              ['1RK', '1BHK', '2BHK', '3BHK', '4+ BHK'],
              (value) => setState(() => _flatSize = value),
              Icons.home_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Furnishing',
              _furnishing,
              ['Furnished', 'Semi-furnished', 'Unfurnished'],
              (value) => setState(() => _furnishing = value),
              Icons.chair_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSwitchCard(
              'Attached Bathroom',
              'Does the room have an attached bathroom?',
              _hasAttachedBathroom,
              (value) => setState(() => _hasAttachedBathroom = value),
              Icons.bathroom_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAndDateStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📍 Location & Availability',
              'Where is your property located?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'Enter exact address or locality',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _locationUrlController,
              label: 'Location URL (Optional)',
              hint: 'Enter Location link from Google Maps',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildDatePickerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('💰 Pricing Details', 'Set your rental terms'),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _rentController,
              label: 'Monthly Rent (₹)',
              hint: 'Enter amount per person or total',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _depositController,
              label: 'Security Deposit per person (₹)',
              hint: 'Enter deposit amount',
              icon: Icons.security,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildPricingTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatmateDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '👥 Current Flatmates',
              'Tell us about your current flatmates',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildCounterCard(
              'Number of Current Flatmates',
              _currentFlatmates,
              (value) => setState(() => _currentFlatmates = value),
              Icons.people_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),

            _buildCounterCard(
              'Number of Max Flatmates',
              _maxFlatmates,
              (value) => setState(() => _maxFlatmates = value),
              Icons.people_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Gender Composition',
              _genderComposition,
              ['Male Only', 'Female Only', 'Mixed'],
              (value) => setState(() => _genderComposition = value),
              Icons.people,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Occupation',
              _occupation,
              ['Students Only', 'Working Only', 'Mixed'],
              (value) => setState(() => _occupation = value),
              Icons.work_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🏠 Facilities & Amenities',
              'What facilities are available?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildFacilitiesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '⚙️ Preferences & Rules',
              'Set your flatmate preferences',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildSelectionCard(
              'Looking For',
              _lookingFor,
              ['Male', 'Female', 'Any'],
              (value) => setState(() => _lookingFor = value),
              Icons.search,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Food Preference',
              _foodPreference,
              ['Veg', 'Non-Veg', 'Eggetarian', 'Doesn\'t Matter'],
              (value) => setState(() => _foodPreference = value),
              Icons.restaurant,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildPolicySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosAndContactStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📸 Photos & Contact',
              'Add photos and contact details',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildPhotoUploadSection(),

            const SizedBox(height: BuddyTheme.spacingXl),

            Text(
              'Contact Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: BuddyTheme.spacingMd),

            _buildAnimatedTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your contact number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _emailController,
              label: 'Email ID',
              hint: 'Enter your email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _notesController,
              label: 'Additional Notes (Optional)',
              hint: 'Any additional information about the property...',
              icon: Icons.note_outlined,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BuddyTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: Icon(icon, color: BuddyTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionCard(
    String title,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: BuddyTheme.primaryColor),
                      const SizedBox(width: BuddyTheme.spacingSm),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  Wrap(
                    spacing: BuddyTheme.spacingSm,
                    runSpacing: BuddyTheme.spacingSm,
                    children:
                        options
                            .map(
                              (option) => GestureDetector(
                                onTap: () => onChanged(option),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: BuddyTheme.spacingMd,
                                    vertical: BuddyTheme.spacingSm,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selectedValue == option
                                            ? BuddyTheme.primaryColor
                                            : scaffoldBg,
                                    borderRadius: BorderRadius.circular(
                                      BuddyTheme.borderRadiusSm,
                                    ),
                                    border: Border.all(
                                      color:
                                          selectedValue == option
                                              ? BuddyTheme.primaryColor
                                              : BuddyTheme.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color:
                                          selectedValue == option
                                              ? Colors.white
                                              : textPrimary,
                                      fontWeight:
                                          selectedValue == option
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: BuddyTheme.primaryColor),
                  const SizedBox(width: BuddyTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: BuddyTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCounterCard(
    String title,
    int value,
    Function(int) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: BuddyTheme.primaryColor),
                  const SizedBox(width: BuddyTheme.spacingMd),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: value > 0 ? () => onChanged(value - 1) : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
                            child: Icon(
                              Icons.remove_circle_outline,
                              color:
                                  value > 0
                                      ? BuddyTheme.primaryColor
                                      : textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BuddyTheme.spacingMd,
                          vertical: BuddyTheme.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: BuddyTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusSm,
                          ),
                        ),
                        child: Text(
                          value.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: BuddyTheme.primaryColor,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onChanged(value + 1),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
                            child: Icon(
                              Icons.add_circle_outline,
                              color: BuddyTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacilitiesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: BuddyTheme.spacingSm,
        mainAxisSpacing: BuddyTheme.spacingSm,
      ),
      itemCount: _facilities.length,
      itemBuilder: (context, index) {
        String facility = _facilities.keys.elementAt(index);
        bool isSelected = _facilities[facility]!;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _facilities[facility] = !isSelected;
                      });
                    },
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(BuddyTheme.spacingSm),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? BuddyTheme.primaryColor.withOpacity(0.1)
                                : cardColor,
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusMd,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? BuddyTheme.primaryColor
                                  : BuddyTheme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? BuddyTheme.primaryColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? BuddyTheme.primaryColor
                                        : BuddyTheme.borderColor,
                              ),
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: BuddyTheme.spacingSm),
                          Expanded(
                            child: Text(
                              facility,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isSelected
                                        ? BuddyTheme.primaryColor
                                        : textPrimary,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePickerCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: BuddyTheme.primaryColor,
                      ),
                      const SizedBox(width: BuddyTheme.spacingSm),
                      Text(
                        'Available From',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _availableFromDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: theme.copyWith(
                                colorScheme: theme.colorScheme.copyWith(
                                  primary: BuddyTheme.primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _availableFromDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: scaffoldBg,
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusSm,
                          ),
                          border: Border.all(color: BuddyTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: BuddyTheme.primaryColor),
                            const SizedBox(width: BuddyTheme.spacingSm),
                            Text(
                              _availableFromDate != null
                                  ? '${_availableFromDate!.day}/${_availableFromDate!.month}/${_availableFromDate!.year}'
                                  : 'Select Date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    _availableFromDate != null
                                        ? textPrimary
                                        : textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricingTipCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BuddyTheme.primaryColor.withOpacity(0.1),
                    BuddyTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                border: Border.all(
                  color: BuddyTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outlined,
                        color: BuddyTheme.primaryColor,
                      ),
                      const SizedBox(width: BuddyTheme.spacingSm),
                      Text(
                        'Pricing Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BuddyTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingSm),
                  Text(
                    '• Research similar properties in your area\n'
                    '• Consider including utilities in rent\n'
                    '• Security deposit is typically 1-3 months rent\n'
                    '• Be transparent about additional charges',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BuddyTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPolicySection() {
    return Column(
      children: [
        _buildSelectionCard(
          'Smoking Policy',
          _smokingPolicy,
          ['Not Allowed', 'Allowed', 'Only Outside'],
          (value) => setState(() => _smokingPolicy = value),
          Icons.smoke_free,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSelectionCard(
          'Drinking Policy',
          _drinkingPolicy,
          ['Not Allowed', 'Allowed', 'Occasionally'],
          (value) => setState(() => _drinkingPolicy = value),
          Icons.local_bar_outlined,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSelectionCard(
          'Guests Policy',
          _guestsPolicy,
          ['Not Allowed', 'Allowed', 'Prior Permission'],
          (value) => setState(() => _guestsPolicy = value),
          Icons.people_outline,
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Photos',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        Text(
          'Add photos of different areas (${_uploadedPhotos.length} uploaded)',
          style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),

        // Photo upload grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: BuddyTheme.spacingSm,
            mainAxisSpacing: BuddyTheme.spacingSm,
          ),
          itemCount: _requiredPhotoTypes.length,
          itemBuilder: (context, index) {
            String photoType = _requiredPhotoTypes[index];
            bool hasPhoto = _uploadedPhotos.contains(photoType);

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Simulate photo upload
                          setState(() {
                            if (hasPhoto) {
                              _uploadedPhotos.remove(photoType);
                            } else {
                              _uploadedPhotos.add(photoType);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusMd,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                hasPhoto
                                    ? BuddyTheme.primaryColor.withOpacity(0.1)
                                    : cardColor,
                            borderRadius: BorderRadius.circular(
                              BuddyTheme.borderRadiusMd,
                            ),
                            border: Border.all(
                              color:
                                  hasPhoto
                                      ? BuddyTheme.primaryColor
                                      : BuddyTheme.borderColor,
                              style:
                                  hasPhoto
                                      ? BorderStyle.solid
                                      : BorderStyle.none,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  hasPhoto
                                      ? Icons.check_circle
                                      : Icons.add_a_photo_outlined,
                                  key: ValueKey(hasPhoto),
                                  size: 32,
                                  color:
                                      hasPhoto
                                          ? BuddyTheme.primaryColor
                                          : textSecondary,
                                ),
                              ),
                              const SizedBox(height: BuddyTheme.spacingSm),
                              Text(
                                photoType,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      hasPhoto
                                          ? BuddyTheme.primaryColor
                                          : textSecondary,
                                  fontWeight:
                                      hasPhoto
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                              if (hasPhoto) ...[
                                const SizedBox(height: BuddyTheme.spacingXs),
                                Text(
                                  'Tap to remove',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingLg),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingMd,
                  ),
                  side: BorderSide(color: BuddyTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, color: BuddyTheme.primaryColor),
                    const SizedBox(width: BuddyTheme.spacingSm),
                    Text(
                      'Previous',
                      style: TextStyle(color: BuddyTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
          ],
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ScaleTransition(
              scale: _fabAnimation,
              child: ElevatedButton(
                onPressed:
                    _currentStep == _totalSteps - 1 ? _submitForm : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingMd,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == _totalSteps - 1
                          ? 'Submit Listing'
                          : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: BuddyTheme.spacingSm),
                    Icon(
                      _currentStep == _totalSteps - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
