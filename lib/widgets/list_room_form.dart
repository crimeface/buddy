import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cloudinary_service.dart';

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
  final int _totalSteps = 8; // Updated from 7 to 8

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
  final Map<String, List<String>> _uploadedPhotos = {
    'Room': [],
    'Washroom': [],
    'Kitchen': [],
    'Building': [],
  };
  final Map<String, String> _uploadedPhotoUrls = {
    'Room': '',
    'Washroom': '',
    'Kitchen': '',
    'Building': '',
  };
  final ImagePicker _picker = ImagePicker();
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

  // Payment Plan
  String _selectedPlan = '1Day';
  final Map<String, double> _planPrices = {
    '1Day': 29.0,
    '7Day': 149.0,
    '15Day': 239.0,
    '1Month': 499.0,
  };

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
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentStep) {
        setState(() {
          _currentStep = _pageController.page!.round();
        });
        _updateProgress();
        _triggerSlideAnimation();
      }
    });

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    if (_currentStep >= _totalSteps - 1) return;

    _pageController.animateToPage(
      _currentStep + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep <= 0) return;

    _pageController.animateToPage(
      _currentStep - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Calculate expiry date based on selected plan
    Duration planDuration;
    switch (_selectedPlan) {
      case '1Day':
        planDuration = const Duration(days: 1);
        break;
      case '7Day':
        planDuration = const Duration(days: 7);
        break;
      case '15Day':
        planDuration = const Duration(days: 15);
        break;
      case '1Month':
        planDuration = const Duration(days: 30);
        break;
      default:
        planDuration = const Duration(days: 1);
    }
    final now = DateTime.now();
    final expiryDate = now.add(planDuration);

    // Prepare data
    final data = {
      'userId': userId ?? 'anonymous',
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
      'uploadedPhotos': _uploadedPhotoUrls,
      'firstPhoto': _uploadedPhotoUrls.values.firstWhere(
        (url) => url.isNotEmpty,
        orElse: () => '',
      ),
      'createdAt': now.toIso8601String(),
      'selectedPlan': _selectedPlan,
      'expiryDate': expiryDate.toIso8601String(),
      'visibility': true, // Always true on creation
    };

    try {
      await FirebaseFirestore.instance.collection('room_listings').add(data);

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

  Future<void> _uploadPhoto(String photoType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image == null) return;

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Uploading image...'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: BuddyTheme.primaryColor,
        ),
      );

      // Upload to Cloudinary
      String cloudinaryUrl = await CloudinaryService.uploadImage(image.path);

      if (!mounted) return;
      setState(() {
        _uploadedPhotoUrls[photoType] = cloudinaryUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    scaffoldBg = theme.scaffoldBackgroundColor;
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
      ),
      body: Form(
        key: _formKey,
        child: Column(
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
                  _buildPaymentPlanStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
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

  Widget _buildPaymentPlanStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '💰 Payment Plan',
              'Choose how long to keep your listing active',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            ..._planPrices.entries
                .map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: BuddyTheme.spacingMd,
                    ),
                    child: _buildPlanCard(
                      plan.key,
                      plan.value,
                      isSelected: _selectedPlan == plan.key,
                      onSelect: () => setState(() => _selectedPlan = plan.key),
                    ),
                  ),
                )
                .toList(),

            const SizedBox(height: BuddyTheme.spacingXl),
            _buildPlanInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    String planName,
    double price, {
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    String duration = planName;
    String formattedPrice = '₹${price.toStringAsFixed(0)}';

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (
            BuildContext context,
            double value,
            Widget? child,
          ) => Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSelect,
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusMd,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(BuddyTheme.spacingMd),
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
                                : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color:
                              isSelected
                                  ? BuddyTheme.primaryColor
                                  : Colors.grey,
                        ),
                        const SizedBox(width: BuddyTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                duration,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? BuddyTheme.primaryColor
                                          : textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: BuddyTheme.spacingXs),
                              Text(
                                'Keep your listing active for ${duration.toLowerCase()}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formattedPrice,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? BuddyTheme.primaryColor
                                    : textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPlanInfoCard() {
    return Container(
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
        border: Border.all(color: BuddyTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                'Plan Benefits',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BuddyTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Text(
            '• Your listing will be active for the selected duration\n'
            '• Featured placement in search results\n'
            '• Email notifications for interested flatmates\n'
            '• Option to extend duration later',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BuddyTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
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
              ),
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
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
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
              ),
    );
  }

  Widget _buildSelectionCard(
    String title,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.translate(
                offset: Offset(50 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
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
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
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
              ),
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 700),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double animValue, Widget? child) =>
              Transform.scale(
                scale: 0.8 + (0.2 * animValue),
                child: Opacity(
                  opacity: animValue,
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
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
              ),
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
    List<Widget> rows = [];
    List<String> keys = _facilities.keys.toList();

    int i = 0;
    while (i < keys.length) {
      String facility = keys[i];
      bool isLongName = facility.length > 12;

      if (isLongName) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: BuddyTheme.spacingMd),
            child: _buildFacilityItem(
              facility,
              _facilities[facility]!,
              fullWidth: true,
            ),
          ),
        );
        i++;
      } else {
        final String facility1 = keys[i];
        final Widget firstItem = _buildFacilityItem(
          facility1,
          _facilities[facility1]!,
        );
        i++;
        if (i < keys.length) {
          final String facility2 = keys[i];
          final Widget secondItem = _buildFacilityItem(
            facility2,
            _facilities[facility2]!,
          );

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
              child: Row(
                children: [
                  Expanded(child: firstItem),
                  SizedBox(width: BuddyTheme.spacingSm),
                  Expanded(child: secondItem),
                ],
              ),
            ),
          );
          i++;
        } else {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
              child: Row(children: [Expanded(child: firstItem)]),
            ),
          );
        }
      }
    }

    return Column(children: rows);
  }

  Widget _buildFacilityItem(
    String facility,
    bool isSelected, {
    bool fullWidth = false,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.scale(
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
                        width: fullWidth ? double.infinity : null,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? BuddyTheme.primaryColor.withOpacity(0.1)
                                  : Colors.white,
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
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      isSelected
                                          ? BuddyTheme.primaryColor
                                          : BuddyTheme.textPrimaryColor,
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
              ),
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
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.scale(
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
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
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
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: BuddyTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
          'Required Photos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Text(
          'Please upload photos for each required section',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BuddyTheme.textSecondaryColor),
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: BuddyTheme.spacingMd,
            crossAxisSpacing: BuddyTheme.spacingMd,
            childAspectRatio: 0.85,
          ),
          itemCount: _requiredPhotoTypes.length,
          itemBuilder: (context, index) {
            final photoType = _requiredPhotoTypes[index];
            final photoUrl = _uploadedPhotoUrls[photoType];
            final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

            return _buildPhotoUploadCard(
              photoType: photoType,
              hasPhoto: hasPhoto,
              photoUrl: photoUrl,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoUploadCard({
    required String photoType,
    required bool hasPhoto,
    String? photoUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color:
              hasPhoto ? BuddyTheme.primaryColor : Colors.grey.withOpacity(0.3),
          width: hasPhoto ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _uploadPhoto(photoType),
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
          child: Padding(
            padding: const EdgeInsets.all(BuddyTheme.spacingMd),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasPhoto && photoUrl != null && photoUrl.isNotEmpty) ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 32,
                            ),
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: hasPhoto ? BuddyTheme.primaryColor : Colors.grey,
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                ],
                Text(
                  photoType,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasPhoto ? BuddyTheme.primaryColor : textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!hasPhoto) ...[
                  const SizedBox(height: BuddyTheme.spacingXs),
                  Text(
                    'Tap to upload',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: BuddyTheme.spacingXs),
                    Icon(
                      _currentStep == _totalSteps - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      color: cardColor,
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
