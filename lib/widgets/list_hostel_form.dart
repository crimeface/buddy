import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import '../models/room_type.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import at the top
import 'package:cloud_firestore/cloud_firestore.dart';

class ListHostelForm extends StatefulWidget {
  ListHostelForm({Key? key}) : super(key: key) {
  }

  @override
  State<ListHostelForm> createState() => _ListHostelFormState();
}

class _ListHostelFormState extends State<ListHostelForm>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;
  bool _isNavigating = false;
  bool _isPageChanging = false;

  int _currentStep = 0;
  final int _totalSteps = 9;

  // Form controllers and data
  final _formKey = GlobalKey<FormState>();

  // Payment Plan
  String _selectedPlan = '1Day';
  final Map<String, double> _planPrices = {
    '1Day': 29.0,
    '7Day': 149.0,
    '15Day': 239.0,
    '1Month': 499.0,
  };

  // Basic Information
  final _titleController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _mapLinkController = TextEditingController();
  String _hostelType = 'Hostel';
  String _hostelFor = 'Male';

  // Room Types
  List<RoomType> _roomTypes = [
    RoomType(
      type: '1 Bed Room (Private)',
      bedsPerRoom: 1,
      availableRooms: 0,
      rentPerPerson: 0,
      deposit: 0,
    ),
  ];

  // Facilities
  Map<String, bool> _facilities = {
    'WiFi': false,
    'Laundry': false,
    'Mess': false,
    'Study Table': false,
    'Cupboard': false,
    'Geyser': false,
    'AC': false,
    'CCTV': false,
    'Lift': false,
    'Parking': false,
    'Attached Washroom': false,
    'Housekeeping': false,
  };

  // Rules & Restrictions
  bool _hasEntryTimings = false;
  TimeOfDay? _entryTime;
  String _smokingPolicy = 'No';
  String _drinkingPolicy = 'No';
  String _guestsPolicy = 'No';
  String _petsPolicy = 'No';
  String _foodType = 'Veg';

  // Availability & Booking
  DateTime? _availableFromDate;
  String _minimumStay = '1 month';
  String _bookingMode = 'Call';

  // Photos
  List<String> _uploadedPhotos = [];
  final List<String> _requiredPhotoTypes = [
    'Room',
    'Washroom',
    'Building Front',
    'Common Area',
  ];
  String _imageUrl = '';

  // Additional Information
  final _descriptionController = TextEditingController();
  final _offersController = TextEditingController();
  final _specialFeaturesController = TextEditingController();

  // Add at the top of _ListHostelFormState
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
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _mapLinkController.dispose();
    _descriptionController.dispose();
    _offersController.dispose();
    _specialFeaturesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
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
        duration: const Duration(milliseconds: 400),
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final data = {
      'uid': userId,
      'title': _titleController.text,
      'hostelType': _hostelType,
      'hostelFor': _hostelFor,
      'contactPerson': _contactPersonController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'landmark': _landmarkController.text,
      'mapLink': _mapLinkController.text,
      'roomTypes':
          _roomTypes
              .map(
                (room) => {
                  'type': room.type,
                  'bedsPerRoom': room.bedsPerRoom,
                  'availableRooms': room.availableRooms,
                  'rentPerPerson': room.rentPerPerson,
                  'deposit': room.deposit,
                },
              )
              .toList(),
      'facilities': _facilities,
      'hasEntryTimings': _hasEntryTimings,
      'entryTime': _entryTime?.format(context),
      'smokingPolicy': _smokingPolicy,
      'drinkingPolicy': _drinkingPolicy,
      'guestsPolicy': _guestsPolicy,
      'petsPolicy': _petsPolicy,
      'foodType': _foodType,
      'availableFromDate': _availableFromDate?.toIso8601String(),
      'minimumStay': _minimumStay,
      'bookingMode': _bookingMode,
      'uploadedPhotos': _uploadedPhotos,
      'description': _descriptionController.text,
      'offers': _offersController.text,
      'specialFeatures': _specialFeaturesController.text,
      'createdAt': DateTime.now().toIso8601String(),
      'imageUrl':
          'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=800&q=80',
    };

    try {
      await FirebaseFirestore.instance.collection('hostel_listings').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hostel listing submitted successfully!'),
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
    cardColor = theme.brightness == Brightness.dark
        ? const Color(0xFF23262F)
        : const Color.fromARGB(255, 226, 227, 231);
    textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    textSecondary = theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('List Your Hostel / PG'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInformationStep(),
                _buildRoomTypesStep(),
                _buildFacilitiesStep(),
                _buildRulesStep(),
                _buildAvailabilityStep(),
                _buildPhotosStep(),
                _buildAdditionalInfoStep(),
                _buildPreviewStep(),
                _buildPaymentPlanStep(), // Payment plan as final step
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

  Widget _buildBasicInformationStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              'Basic Information',
              'Enter your hostel/PG details',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _titleController,
              label: 'Listing Title',
              hint: 'e.g., Boys PG near MIT-WPU with Mess',
              icon: Icons.title,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Property Type',
              _hostelType,
              ['Hostel', 'PG'],
              (value) => setState(() => _hostelType = value),
              Icons.home_work,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'For',
              _hostelFor,
              ['Male', 'Female', 'Any'],
              (value) => setState(() => _hostelFor = value),
              Icons.people,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _contactPersonController,
              label: 'Contact Person Name',
              hint: 'Enter contact person name',
              icon: Icons.person,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter phone number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _emailController,
              label: 'Email ID',
              hint: 'Enter email address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _addressController,
              label: 'Exact Address',
              hint: 'Enter complete address',
              icon: Icons.location_on,
              maxLines: 3,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _landmarkController,
              label: 'Landmark / Nearby Institute',
              hint: 'Enter nearby landmark or institute name',
              icon: Icons.place,
            ),
            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _mapLinkController,
              label: 'Google Map Link (Optional)',
              hint: 'Paste Google Maps link',
              icon: Icons.map,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypesStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🛏️ Room Types and Bed Availability',
              'Configure your room types and availability',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            ..._roomTypes.asMap().entries.map((entry) {
              int index = entry.key;
              RoomType roomType = entry.value;
              return _buildRoomTypeCard(roomType, index);
            }).toList(),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAddRoomTypeButton(),
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

  Widget _buildRulesStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📜 Rules & Restrictions',
              'Set your hostel rules and policies',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildSwitchCard(
              'Entry Timings',
              'Do you have specific entry timings?',
              _hasEntryTimings,
              (value) => setState(() => _hasEntryTimings = value),
              Icons.access_time,
            ),

            if (_hasEntryTimings) ...[
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildTimePickerCard(),
            ],

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Smoking Allowed',
              _smokingPolicy,
              ['Yes', 'No'],
              (value) => setState(() => _smokingPolicy = value),
              Icons.smoke_free,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Drinking Allowed',
              _drinkingPolicy,
              ['Yes', 'No'],
              (value) => setState(() => _drinkingPolicy = value),
              Icons.no_drinks,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Guests Allowed',
              _guestsPolicy,
              ['Yes', 'No'],
              (value) => setState(() => _guestsPolicy = value),
              Icons.people_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Food Type Provided',
              _foodType,
              ['Veg', 'Non-Veg', 'Both'],
              (value) => setState(() => _foodType = value),
              Icons.restaurant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📅 Availability & Booking',
              'Set availability and booking preferences',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildDatePickerCard(),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Minimum Stay Duration',
              _minimumStay,
              ['1 month', '2 months', '3 months', '6 months', '1 year'],
              (value) => setState(() => _minimumStay = value),
              Icons.calendar_month,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📸 Photo Uploads',
              'Add photos of your hostel/PG',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildPhotoUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '💬 Additional Information',
              'Add extra details about your hostel/PG',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _descriptionController,
              label: 'Short Description (Optional)',
              hint: 'Describe your hostel/PG in a few lines...',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _offersController,
              label: 'Offers/Discounts (Optional)',
              hint: 'Any special offers or discounts...',
              icon: Icons.local_offer_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _specialFeaturesController,
              label: 'Special Features (Optional)',
              hint: 'e.g., High-speed WiFi, Balcony, etc.',
              icon: Icons.star_outline,
              maxLines: 2,
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
            
            ..._planPrices.entries.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: BuddyTheme.spacingMd),
              child: _buildPlanCard(
                plan.key,
                plan.value,
                isSelected: _selectedPlan == plan.key,
                onSelect: () => setState(() => _selectedPlan = plan.key),
              ),
            )).toList(),

            const SizedBox(height: BuddyTheme.spacingXl),
            _buildPlanInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String planName, double price, {
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    String duration = planName;
    String formattedPrice = '₹${price.toStringAsFixed(0)}';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: isSelected ? BuddyTheme.primaryColor.withOpacity(0.1) : cardColor,
                    borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                    border: Border.all(
                      color: isSelected ? BuddyTheme.primaryColor : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
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
                      Icon(
                        Icons.access_time,
                        color: isSelected ? BuddyTheme.primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: BuddyTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              duration,
                              style: TextStyle(
                                color: isSelected ? BuddyTheme.primaryColor : textPrimary,
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
                          color: isSelected ? BuddyTheme.primaryColor : textPrimary,
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
          );
      },
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
                Icons.info_outline,
                color: BuddyTheme.primaryColor,
              ),
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
            '• Email notifications for interested users\n'
            '• Option to extend duration later',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BuddyTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🧾 Listing Preview',
              'Review your hostel listing',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
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
      duration: const Duration(milliseconds: 400),
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
      duration: const Duration(milliseconds: 400),
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
      duration: const Duration(milliseconds: 400),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: BuddyTheme.textSecondaryColor),
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

  Widget _buildRoomTypeCard(RoomType roomType, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: BuddyTheme.spacingLg),
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
                      Text(
                        roomType.type,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_roomTypes.length > 1)
                        IconButton(
                          onPressed: () => _removeRoomType(index),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  DropdownButtonFormField<String>(
                    value: roomType.type,
                    decoration: InputDecoration(
                      labelText: 'Room Type',
                      prefixIcon: const Icon(Icons.bed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusSm,
                        ),
                      ),
                    ),
                    items:
                        [
                              '1 Bed Room (Private)',
                              '2 Bed Sharing',
                              '3 Bed Sharing',
                              '4+ Bed Sharing',
                            ]
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        roomType.type = value!;
                        roomType.bedsPerRoom = _getBedsPerRoom(value);
                      });
                    },
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Available Rooms - now on its own row
                  TextFormField(
                    initialValue: roomType.availableRooms.toString(),
                    decoration: InputDecoration(
                      labelText: 'Available Rooms',
                      prefixIcon: const Icon(Icons.door_front_door),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusSm,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      roomType.availableRooms = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Rent per Person - now on its own row
                  TextFormField(
                    initialValue: roomType.rentPerPerson.toString(),
                    decoration: InputDecoration(
                      labelText: 'Rent per Person',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusSm,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      roomType.rentPerPerson = double.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Security Deposit
                  TextFormField(
                    initialValue: roomType.deposit.toString(),
                    decoration: InputDecoration(
                      labelText: 'Security Deposit',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusSm,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      roomType.deposit = double.tryParse(value) ?? 0;
                    },
                  ),
                ],
              ),
            ),
          ),
          );
      },
    );
  }

  Widget _buildAddRoomTypeButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: _addRoomType,
              child: Container(
                padding: const EdgeInsets.all(BuddyTheme.spacingLg),
                decoration: BoxDecoration(
                  color: BuddyTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusMd,
                  ),
                  border: Border.all(
                    color: BuddyTheme.primaryColor,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: BuddyTheme.primaryColor,
                    ),
                    const SizedBox(width: BuddyTheme.spacingSm),
                    Text(
                      'Add Another Room Type',
                      style: TextStyle(
                        color: BuddyTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400),
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
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
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
          );
      },
    );
  }

  Widget _buildTimePickerCard() {
    return Container(
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
          const Icon(Icons.schedule, color: BuddyTheme.primaryColor),
          const SizedBox(width: BuddyTheme.spacingMd),
          Expanded(
            child: Text(
              'Entry Time Limit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: _entryTime ?? const TimeOfDay(hour: 22, minute: 0),
              );
              if (picked != null) {
                setState(() {
                  _entryTime = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BuddyTheme.spacingMd,
                vertical: BuddyTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: BuddyTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
              ),
              child: Text(
                _entryTime?.format(context) ?? 'Select Time',
                style: TextStyle(
                  color: BuddyTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: BuddyTheme.primaryColor,
                  ),
                  const SizedBox(width: BuddyTheme.spacingMd),
                  Expanded(
                    child: Text(
                      'Available From Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _availableFromDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _availableFromDate = picked;
                        });
                      }
                    },
                    child: Container(
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
                        _availableFromDate != null
                            ? '${_availableFromDate!.day}/${_availableFromDate!.month}/${_availableFromDate!.year}'
                            : 'Select Date',
                        style: TextStyle(
                          color: BuddyTheme.primaryColor,
                          fontWeight: FontWeight.w600,
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
                          color: hasPhoto
                              ? BuddyTheme.primaryColor.withOpacity(0.1)
                              : cardColor,
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusMd,
                          ),
                          border: Border.all(
                            color: hasPhoto
                                ? BuddyTheme.primaryColor
                                : BuddyTheme.borderColor,
                            style: hasPhoto
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
                                color: hasPhoto
                                    ? BuddyTheme.primaryColor
                                    : textSecondary,
                              ),
                            ),
                            const SizedBox(height: BuddyTheme.spacingSm),
                            Text(
                              photoType,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasPhoto
                                    ? BuddyTheme.primaryColor
                                    : textSecondary,
                                fontWeight: hasPhoto
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


  Widget _buildPreviewCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingLg),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Basic Info
                  Text(
                    _titleController.text.isNotEmpty
                        ? _titleController.text
                        : 'Hostel Title',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: BuddyTheme.spacingXs),
                  Row(
                    children: [
                      Container(
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
                          _hostelType,
                          style: TextStyle(
                            color: BuddyTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: BuddyTheme.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BuddyTheme.spacingSm,
                          vertical: BuddyTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: BuddyTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusSm,
                          ),
                        ),
                        child: Text(
                          _hostelFor,
                          style: TextStyle(
                            color: BuddyTheme.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  const Divider(),
                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Contact Info
                  _buildPreviewSection('Contact Information', [
                    _buildPreviewItem(
                      'Contact Person',
                      _contactPersonController.text,
                    ),
                    _buildPreviewItem('Phone', _phoneController.text),
                    _buildPreviewItem('Email', _emailController.text),
                    _buildPreviewItem('Address', _addressController.text),
                    _buildPreviewItem('Landmark', _landmarkController.text),
                  ]),

                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Room Types
                  _buildPreviewSection(
                    'Room Types',
                    _roomTypes
                        .map(
                          (room) => _buildPreviewItem(
                            room.type,
                            '${room.availableRooms} rooms • ₹${room.rentPerPerson}/person • ₹${room.deposit} deposit',
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Facilities
                  _buildPreviewSection('Facilities', [
                    _buildPreviewFacilities(),
                  ]),

                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Rules
                  _buildPreviewSection('Rules & Policies', [
                    _buildPreviewItem(
                      'Entry Timings',
                      _hasEntryTimings
                          ? (_entryTime?.format(context) ?? 'Not specified')
                          : 'No restrictions',
                    ),
                    _buildPreviewItem('Smoking', _smokingPolicy),
                    _buildPreviewItem('Drinking', _drinkingPolicy),
                    _buildPreviewItem('Guests', _guestsPolicy),
                    _buildPreviewItem('Pets', _petsPolicy),
                    _buildPreviewItem('Food Type', _foodType),
                  ]),

                  const SizedBox(height: BuddyTheme.spacingMd),

                  // Availability
                  _buildPreviewSection('Availability', [
                    _buildPreviewItem(
                      'Available From',
                      _availableFromDate != null
                          ? '${_availableFromDate!.day}/${_availableFromDate!.month}/${_availableFromDate!.year}'
                          : 'Not specified',
                    ),
                    _buildPreviewItem('Minimum Stay', _minimumStay),
                    _buildPreviewItem('Booking Mode', _bookingMode),
                  ]),

                  if (_descriptionController.text.isNotEmpty)
                    _buildPreviewSection('Description', [
                      const SizedBox(height: BuddyTheme.spacingMd),
                      Text(
                        _descriptionController.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ]),
                ],
              ),
            ),
          ),
          );
      },
    );
  }

  Widget _buildPreviewSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        ...children,
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BuddyTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewFacilities() {
    List<String> selectedFacilities =
        _facilities.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedFacilities.isEmpty) {
      return Text(
        'No facilities selected',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: BuddyTheme.textSecondaryColor),
      );
    }

    return Wrap(
      spacing: BuddyTheme.spacingXs,
      runSpacing: BuddyTheme.spacingXs,
      children:
          selectedFacilities
              .map(
                (facility) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BuddyTheme.spacingSm,
                    vertical: BuddyTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: BuddyTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusSm,
                    ),
                  ),
                  child: Text(
                    facility,
                    style: TextStyle(
                      color: BuddyTheme.successColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Future<void> _uploadPhoto(String photoType) async {
    // Implement your photo upload logic here
    // This is just a placeholder
    print('Uploading photo for: $photoType');
  }

  void _removePhoto(int index) {
    setState(() {
      _uploadedPhotos.removeAt(index);
    });
  }

  Widget _buildNavigationButtons() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
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
                        BuddyTheme.borderRadiusSm,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: BuddyTheme.primaryColor),
                      const SizedBox(width: BuddyTheme.spacingXs),
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
              child: ElevatedButton(
                onPressed:
                    _currentStep == _totalSteps - 1 ? _submitForm : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingMd,
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
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _addRoomType() {
    setState(() {
      _roomTypes.add(
        RoomType(
          type: '1 Bed Room (Private)',
          bedsPerRoom: 1,
          availableRooms: 0,
          rentPerPerson: 0,
          deposit: 0,
        ),
      );
    });
  }

  void _removeRoomType(int index) {
    setState(() {
      _roomTypes.removeAt(index);
    });
  }

  void _updateRoomType(
    int index, {
    String? type,
    int? bedsPerRoom,
    int? availableRooms,
    double? rentPerPerson,
    double? deposit,
  }) {
    setState(() {
      final roomType = _roomTypes[index];
      _roomTypes[index] = RoomType(
        type: type ?? roomType.type,
        bedsPerRoom: bedsPerRoom ?? roomType.bedsPerRoom,
        availableRooms: availableRooms ?? roomType.availableRooms,
        rentPerPerson: rentPerPerson ?? roomType.rentPerPerson,
        deposit: deposit ?? roomType.deposit,
      );
    });
  }

  int _getBedsPerRoom(String roomType) {
    switch (roomType) {
      case '1 Bed Room (Private)':
        return 1;
      case '2 Bed Sharing':
        return 2;
      case '3 Bed Sharing':
        return 3;
      case '4+ Bed Sharing':
        return 4;
      default:
        return 1;
    }
  }
}
