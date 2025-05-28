import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'dart:io';

class ListServiceForm extends StatefulWidget {
  const ListServiceForm({Key? key}) : super(key: key);

  @override
  State<ListServiceForm> createState() => _ListServiceFormState();
}

class _ListServiceFormState extends State<ListServiceForm>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form controllers and data
  final _formKey = GlobalKey<FormState>();

  // Basic Service Details
  String _serviceType = 'Library';
  final _serviceNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Timings
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  String _offDay = 'None';

  // Library-specific fields
  String _libraryType = 'Public';
  final _seatingCapacityController = TextEditingController();
  String _acStatus = 'AC';
  final _chargesController = TextEditingController();
  String _chargeType = 'Per Hour';
  bool _hasInternet = true;
  bool _hasStudyCabin = true;

  // Café-specific fields
  String _cuisineType = 'Multi-cuisine';
  bool _hasSeating = true;
  final _priceRangeController = TextEditingController();
  bool _hasWifi = true;
  bool _hasPowerSockets = true;

  // Mess-specific fields
  String _foodType = 'Both';
  final _monthlyPriceController = TextEditingController();
  Map<String, bool> _mealTimings = {
    'Breakfast': true,
    'Lunch': true,
    'Dinner': true,
  };
  bool _hasHomeDelivery = false;
  bool _hasTiffinService = false;
  // Other service fields
  final _shortDescriptionController = TextEditingController();
  final _pricingController = TextEditingController();
  final _serviceTypeOtherController = TextEditingController();
  final _usefulnessController = TextEditingController();

  // Photo fields
  final _requiredPhotoTypes = [
    'Cover Photo',
    'Inside',
    'Outside',
    'Special Features',
  ];
  final _uploadedPhotoUrls = <String>[];

  // Photos
  List<String> _uploadedPhotos = [];
  bool _hasCoverPhoto = false;

  final List<String> _serviceTypes = ['Library', 'Café', 'Mess', 'Other'];
  final List<String> _offDays = [
    'None',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

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
    _serviceNameController.dispose();
    _locationController.dispose();
    _mapLinkController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _seatingCapacityController.dispose();
    _chargesController.dispose();
    _priceRangeController.dispose();
    _monthlyPriceController.dispose();
    _shortDescriptionController.dispose();
    _pricingController.dispose();
    _serviceTypeOtherController.dispose();
    _usefulnessController.dispose();
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
    // Prepare the data map based on your form fields and service type
    final data = {
      'serviceType': _serviceType,
      'serviceName': _serviceNameController.text,
      'location': _locationController.text,
      'mapLink': _mapLinkController.text,
      'description': _descriptionController.text,
      'contact': _contactController.text,
      'email': _emailController.text,
      'openingTime':
          _openingTime != null ? _openingTime!.format(context) : null,
      'closingTime':
          _closingTime != null ? _closingTime!.format(context) : null,
      'offDay': _offDay,
      'createdAt': DateTime.now().toIso8601String(),
      // Library-specific
      if (_serviceType == 'Library') ...{
        'libraryType': _libraryType,
        'seatingCapacity': _seatingCapacityController.text,
        'acStatus': _acStatus,
        'charges': _chargesController.text,
        'chargeType': _chargeType,
        'hasInternet': _hasInternet,
        'hasStudyCabin': _hasStudyCabin,
      },
      // Café-specific
      if (_serviceType == 'Café') ...{
        'cuisineType': _cuisineType,
        'hasSeating': _hasSeating,
        'priceRange': _priceRangeController.text,
        'hasWifi': _hasWifi,
        'hasPowerSockets': _hasPowerSockets,
      },
      // Mess-specific
      if (_serviceType == 'Mess') ...{
        'foodType': _foodType,
        'monthlyPrice': _monthlyPriceController.text,
        'mealTimings': _mealTimings,
        'hasHomeDelivery': _hasHomeDelivery,
        'hasTiffinService': _hasTiffinService,
      },
      // Other
      if (_serviceType == 'Other') ...{
        'shortDescription': _shortDescriptionController.text,
        'pricing': _pricingController.text,
        'serviceTypeOther': _serviceTypeOtherController.text,
        'usefulness': _usefulnessController.text,
      },
      // Photos
      'coverPhoto': _uploadedPhotos.isNotEmpty ? _uploadedPhotos.first : null,
      'additionalPhotos':
          _uploadedPhotos.length > 1 ? _uploadedPhotos.sublist(1) : [],
    };

    try {
      final dbRef = FirebaseDatabase.instance.ref().child('service_listings');
      await dbRef.push().set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Service listing submitted successfully!'),
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
    cardColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFF23262F)
            : const Color(0xFFF7F8FA);
    textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    textSecondary =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('List Your Service'),
        backgroundColor: Colors.transparent,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                _buildServiceTypeStep(),
                _buildBasicDetailsStep(),
                _buildTimingsAndContactStep(),
                _buildSpecificDetailsStep(),
                _buildPhotosStep(),
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

  Widget _buildServiceTypeStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🏢 Service Type',
              'What type of service are you listing?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildServiceTypeCards(),

            const SizedBox(height: BuddyTheme.spacingXl),

            _buildServiceTypeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📝 Basic Details',
              'Tell us about your ${_serviceType.toLowerCase()}',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _serviceNameController,
              label: 'Service Name',
              hint: 'Enter the name of your ${_serviceType.toLowerCase()}',
              icon: Icons.business,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'Enter complete address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _mapLinkController,
              label: 'Google Maps Link (Optional)',
              hint: 'Paste Google Maps link for easy navigation',
              icon: Icons.map_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Brief overview of your service',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingsAndContactStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🕒 Timings & Contact',
              'When are you open and how to reach you?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildTimingsCard(),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Off Day',
              _offDay,
              _offDays,
              (value) => setState(() => _offDay = value),
              Icons.event_busy,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _contactController,
              label: 'Contact Number',
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
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              _getSpecificDetailsTitle(),
              'Provide ${_serviceType.toLowerCase()}-specific information',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildSpecificDetailsForm(),
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
              '📸 Photos',
              'Add photos to showcase your service',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildPhotoUploadSection(),
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

  Widget _buildServiceTypeCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: BuddyTheme.spacingSm,
        mainAxisSpacing: BuddyTheme.spacingSm,
      ),
      itemCount: _serviceTypes.length,
      itemBuilder: (context, index) {
        String serviceType = _serviceTypes[index];
        bool isSelected = _serviceType == serviceType;

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
                        _serviceType = serviceType;
                      });
                    },
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
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getServiceTypeIcon(serviceType),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: BuddyTheme.spacingSm),
                          Text(
                            serviceType,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color:
                                  isSelected
                                      ? BuddyTheme.primaryColor
                                      : BuddyTheme.textPrimaryColor,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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

  Widget _buildServiceTypeInfo() {
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
                'Selected: $_serviceType',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BuddyTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Text(
            _getServiceTypeDescription(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BuddyTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                'Operating Hours',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildTimePickerButton(
                  'Opening Time',
                  _openingTime,
                  (time) => setState(() => _openingTime = time),
                ),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Expanded(
                child: _buildTimePickerButton(
                  'Closing Time',
                  _closingTime,
                  (time) => setState(() => _closingTime = time),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerButton(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: time ?? TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(
                    context,
                  ).colorScheme.copyWith(primary: BuddyTheme.primaryColor),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onTimeSelected(picked);
          }
        },
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
        child: Container(
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          decoration: BoxDecoration(
            color: BuddyTheme.backgroundSecondaryColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            border: Border.all(color: BuddyTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BuddyTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: BuddyTheme.spacingXs),
              Text(
                time != null ? time.format(context) : 'Select Time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      time != null
                          ? BuddyTheme.textPrimaryColor
                          : BuddyTheme.textSecondaryColor,
                  fontWeight:
                      time != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificDetailsForm() {
    switch (_serviceType) {
      case 'Library':
        return _buildLibraryDetails();
      case 'Café':
        return _buildCafeDetails();
      case 'Mess':
        return _buildMessDetails();
      case 'Other':
        return _buildOtherDetails();
      default:
        return Container();
    }
  }

  Widget _buildLibraryDetails() {
    return Column(
      children: [
        _buildSelectionCard(
          'Library Type',
          _libraryType,
          ['Public', 'Private', 'Subscription-based'],
          (value) => setState(() => _libraryType = value),
          Icons.library_books,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _seatingCapacityController,
          label: 'Seating Capacity',
          hint: 'Number of seats available',
          icon: Icons.event_seat,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSelectionCard(
          'AC Status',
          _acStatus,
          ['AC', 'Non-AC', 'Both'],
          (value) => setState(() => _acStatus = value),
          Icons.ac_unit,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _chargesController,
          label: 'Monthly Charges (₹)',
          hint: 'Enter monthly amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Internet Facility',
          'WiFi available for users',
          _hasInternet,
          (value) => setState(() => _hasInternet = value),
          Icons.wifi,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Study Cabin',
          'Private study cabins available',
          _hasStudyCabin,
          (value) => setState(() => _hasStudyCabin = value),
          Icons.meeting_room,
        ),
      ],
    );
  }

  Widget _buildCafeDetails() {
    return Column(
      children: [
        _buildSelectionCard(
          'Cuisine Type',
          _cuisineType,
          ['Indian', 'Fast Food', 'Multi-cuisine'],
          (value) => setState(() => _cuisineType = value),
          Icons.restaurant,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Seating Available',
          'Dine-in seating facility',
          _hasSeating,
          (value) => setState(() => _hasSeating = value),
          Icons.chair,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _priceRangeController,
          label: 'Price Range (₹ per person)',
          hint: 'e.g., 100-300',
          icon: Icons.currency_rupee,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'WiFi Available',
          'Free WiFi for customers',
          _hasWifi,
          (value) => setState(() => _hasWifi = value),
          Icons.wifi,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Power Sockets',
          'Charging points for laptops',
          _hasPowerSockets,
          (value) => setState(() => _hasPowerSockets = value),
          Icons.power,
        ),
      ],
    );
  }

  Widget _buildMessDetails() {
    return Column(
      children: [
        _buildSelectionCard(
          'Food Type',
          _foodType,
          ['Veg', 'Non-Veg', 'Both'],
          (value) => setState(() => _foodType = value),
          Icons.restaurant_menu,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _monthlyPriceController,
          label: 'Monthly Subscription Price (₹)',
          hint: 'Enter monthly subscription cost',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildMealTimingsCard(),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Home Delivery',
          'Door-to-door meal delivery',
          _hasHomeDelivery,
          (value) => setState(() => _hasHomeDelivery = value),
          Icons.delivery_dining,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Tiffin Service',
          'Packed meal service available',
          _hasTiffinService,
          (value) => setState(() => _hasTiffinService = value),
          Icons.bakery_dining,
        ),
      ],
    );
  }

  Widget _buildOtherDetails() {
    return Column(
      children: [
        _buildAnimatedTextField(
          controller: _shortDescriptionController,
          label: 'Short Description',
          hint: 'Describe your service briefly',
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _pricingController,
          label: 'Pricing',
          hint: 'Enter service pricing details',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _serviceTypeOtherController,
          label: 'Type of Service',
          hint: 'Specify the type of service',
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _usefulnessController,
          label: 'Usefulness for Students',
          hint: 'How does this help flat seekers/students?',
          icon: Icons.school_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoverPhotoSection(),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAdditionalPhotosSection(),
      ],
    );
  }

  Widget _buildCoverPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Photo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        Text(
          'This will be the main photo displayed',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BuddyTheme.textSecondaryColor),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        InkWell(
          onTap: _selectCoverPhoto,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
              border: Border.all(color: BuddyTheme.borderColor),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: BuddyTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: BuddyTheme.spacingSm),
                  Text(
                    'Click to add cover photo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BuddyTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Photos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        Text(
          'Add more photos of your service',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BuddyTheme.textSecondaryColor),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: BuddyTheme.spacingSm,
            mainAxisSpacing: BuddyTheme.spacingSm,
          ),
          itemCount: _uploadedPhotos.length + 1,
          itemBuilder: (context, index) {
            if (index == _uploadedPhotos.length) {
              return _buildAddPhotoButton();
            }
            return _buildPhotoThumbnail(_uploadedPhotos[index]);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String photoPath) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            border: Border.all(color: BuddyTheme.borderColor),
            image: DecorationImage(
              image: FileImage(File(photoPath)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removePhoto(photoPath),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _selectAdditionalPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
          border: Border.all(color: BuddyTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: BuddyTheme.textSecondaryColor,
            ),
            const SizedBox(height: BuddyTheme.spacingXs),
            Text(
              'Add Photo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BuddyTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCoverPhoto() async {
    // Implement photo selection logic
  }

  void _selectAdditionalPhoto() async {
    // Implement photo selection logic
  }

  void _removePhoto(String photoPath) {
    setState(() {
      _uploadedPhotos.remove(photoPath);
    });
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          _submitForm();
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: BuddyTheme.spacingMd,
          horizontal: BuddyTheme.spacingLg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        ),
        backgroundColor: BuddyTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      child: Text(
        'Submit Listing',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMealTimingsCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                'Meal Timings',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Wrap(
            spacing: BuddyTheme.spacingSm,
            runSpacing: BuddyTheme.spacingSm,
            children:
                _mealTimings.entries.map((entry) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _mealTimings[entry.key] = !entry.value;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BuddyTheme.spacingSm,
                        vertical: BuddyTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            entry.value
                                ? BuddyTheme.primaryColor
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              entry.value
                                  ? BuddyTheme.primaryColor
                                  : BuddyTheme.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusSm,
                        ),
                      ),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              entry.value
                                  ? Colors.white
                                  : BuddyTheme.textPrimaryColor,
                          fontWeight:
                              entry.value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
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
                child: Text(
                  'Previous',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: BuddyTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: BuddyTheme.spacingMd),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _currentStep == _totalSteps - 1
                      ? () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _submitForm();
                        }
                      }
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: BuddyTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: BuddyTheme.spacingMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    BuddyTheme.borderRadiusSm,
                  ),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Submit' : 'Next',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cardColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
                border: Border.all(color: BuddyTheme.borderColor),
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

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: BuddyTheme.borderColor),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: BuddyTheme.primaryColor),
      ),
    );
  }

  Widget _buildSelectionCard(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: BuddyTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items:
                  options.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceTypeIcon(String type) {
    switch (type) {
      case 'Library':
        return '📚';
      case 'Café':
        return '☕';
      case 'Mess':
        return '🍱';
      case 'Other':
        return '🏢';
      default:
        return '🏢';
    }
  }

  String _getServiceTypeDescription() {
    switch (_serviceType) {
      case 'Library':
        return 'A quiet space for students to study and research with facilities like WiFi, AC, etc.';
      case 'Café':
        return 'A cozy spot for students to grab food and beverages, with seating and power outlets.';
      case 'Mess':
        return 'Regular meal service with monthly subscription options and tiffin facilities.';
      case 'Other':
        return 'List any other service that could be useful for students.';
      default:
        return '';
    }
  }

  String _getSpecificDetailsTitle() {
    switch (_serviceType) {
      case 'Library':
        return '📚 Library Details';
      case 'Café':
        return '☕ Café Details';
      case 'Mess':
        return '🍱 Mess Details';
      case 'Other':
        return '🏢 Service Details';
      default:
        return '📝 Service Details';
    }
  }
}
