import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomRequestForm extends StatefulWidget {
  const RoomRequestForm({Key? key}) : super(key: key);

  @override
  State<RoomRequestForm> createState() => _RoomRequestFormState();
}

class _RoomRequestFormState extends State<RoomRequestForm>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  bool _isNavigating = false; // Add this flag to prevent rapid navigation
  DateTime _lastNavigationTime = DateTime.now();

  int _currentStep = 0;
  final int _totalSteps = 5; // Basic Info, Room Requirements, Additional Preferences, Contact Details, Payment Plan

  // Form controllers and data
  final _formKey = GlobalKey<FormState>();

  // Payment Plan
  String _selectedPlan = '1Day';
  final Map<String, int> _planPrices = {
    '1Day': 29,
    '7Day': 149,
    '15Day': 239,
    '1Month': 499,
  };

  // Basic Info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  String _occupation = 'Student';
  String _imageUrl = 'https://randomuser.me/api/portraits';

  // Room Requirements
  final _locationController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  DateTime? _moveInDate;
  String _preferredRoomType = 'Private';
  int _preferredFlatmates = 1;
  String _preferredFlatmateGender = 'Any';
  String _preferredRoomSize = '1RK';

  // Additional Preferences
  String _foodPreference = 'Veg';
  String _smokingPreference = 'No';
  String _drinkingPreference = 'No';
  String _petsPreference = 'No';
  bool _internetRequired = true;
  String _furnishingPreference = 'Furnished';

  // Contact Details
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  late ThemeData theme;
  late Color scaffoldBg;
  late Color cardColor;
  late Color textPrimary;
  late Color textSecondary;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Add listener to sync page changes with step counter
    _pageController.addListener(() {
      if (_pageController.page != null &&
          !_pageController.position.isScrollingNotifier.value) {
        final newStep = _pageController.page!.round();
        if (newStep != _currentStep) {
          setState(() => _currentStep = newStep);
        }
      }
    });

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
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_isNavigating || _currentStep >= _totalSteps - 1) return;

    final now = DateTime.now();
    if (now.difference(_lastNavigationTime).inMilliseconds < 300) return; // Debounce check

    _isNavigating = true;
    _lastNavigationTime = now;

    setState(() {
      _currentStep++;
    });

    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      _isNavigating = false;
    });

    _updateProgress();
    _triggerSlideAnimation();
  }

  void _previousStep() {
    if (_isNavigating || _currentStep <= 0) return;

    final now = DateTime.now();
    if (now.difference(_lastNavigationTime).inMilliseconds < 300) return; // Debounce check

    _isNavigating = true;
    _lastNavigationTime = now;

    setState(() {
      _currentStep--;
    });

    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      _isNavigating = false;
    });

    _updateProgress();
    _triggerSlideAnimation();
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
    if (_formKey.currentState?.validate() ?? false) {
      // Prepare data to store in Firestore
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final data = {
        'userId': userId ?? 'anonymous',
        'name': _nameController.text,
        'age': _ageController.text,
        'gender': _gender,
        'occupation': _occupation,
        'preferredLocation': _locationController.text,
        'minBudget': _minBudgetController.text,
        'maxBudget': _maxBudgetController.text,
        'moveInDate': _moveInDate?.toIso8601String(),
        'preferredRoomType': _preferredRoomType,
        'preferredRoomSize': _preferredRoomSize,
        'preferredFlatmates': _preferredFlatmates,
        'preferredFlatmateGender': _preferredFlatmateGender,
        'foodPreference': _foodPreference,
        'smokingPreference': _smokingPreference,
        'drinkingPreference': _drinkingPreference,
        'petsPreference': _petsPreference,
        'internetRequired': _internetRequired,
        'furnishingPreference': _furnishingPreference,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
        'createdAt': DateTime.now().toIso8601String(),
        'imageUrl': 'https://randomuser.me/api/portraits/men/33.jpg',
      };

      try {
        await FirebaseFirestore.instance.collection('room_requests').add(data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Room request submitted successfully!'),
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
        title: const Text('Request a Room'),
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
                _buildBasicInfoStep(),
                _buildRoomRequirementsStep(),
                _buildAdditionalPreferencesStep(),
                _buildContactDetailsStep(),
                _buildPaymentPlanStep(),
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

  Widget _buildBasicInfoStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('👤 Basic Information', 'Tell us about yourself'),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _ageController,
              label: 'Age',
              hint: 'Enter your age',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Gender',
              _gender,
              ['Male', 'Female', 'Other'],
              (value) => setState(() => _gender = value),
              Icons.people_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Occupation',
              _occupation,
              ['Student', 'Working Professional', 'Other'],
              (value) => setState(() => _occupation = value),
              Icons.work_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomRequirementsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🏠 Room Requirements',
              'What are you looking for?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _locationController,
              label: 'Preferred Location(s)',
              hint: 'Enter preferred localities',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _minBudgetController,
              label: 'Min Budget (₹)',
              hint: 'Minimum',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _maxBudgetController,
              label: 'Max Budget (₹)',
              hint: 'Maximum',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildDateSelector(),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Preferred Room Type',
              _preferredRoomType,
              ['Shared', 'Private'],
              (value) => setState(() => _preferredRoomType = value),
              Icons.bed_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Preferred Room Size',
              _preferredRoomSize,
              ['1RK', '1BHK', '2+ BHK'],
              (value) => setState(() => _preferredRoomSize = value),
              Icons.bed_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildCounterCard(
              'Preferred Number of Flatmates',
              _preferredFlatmates,
              (value) => setState(() => _preferredFlatmates = value),
              Icons.people_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Preferred Flatmate Gender',
              _preferredFlatmateGender,
              ['Male Only', 'Female Only', 'Mixed'],
              (value) => setState(() => _preferredFlatmateGender = value),
              Icons.people,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalPreferencesStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '⚙️ Additional Preferences',
              'Set your preferences',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildSelectionCard(
              'Food Preference',
              _foodPreference,
              ['Veg', 'Non-Veg', 'Eggetarian'],
              (value) => setState(() => _foodPreference = value),
              Icons.restaurant_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Smoking',
              _smokingPreference,
              ['No', 'Yes', "Don't Mind"],
              (value) => setState(() => _smokingPreference = value),
              Icons.smoke_free,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Drinking',
              _drinkingPreference,
              ['No', 'Yes', "Don't Mind"],
              (value) => setState(() => _drinkingPreference = value),
              Icons.local_bar_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Furnishing Preference',
              _furnishingPreference,
              ['Furnished', 'Semi-furnished', 'Unfurnished'],
              (value) => setState(() => _furnishingPreference = value),
              Icons.chair_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('📞 Contact Details', 'How can people reach you?'),
            const SizedBox(height: BuddyTheme.spacingXl),

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
              label: 'Email Address',
              hint: 'Enter your email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _bioController,
              label: 'About You (Optional)',
              hint: 'Tell potential flatmates about yourself...',
              icon: Icons.person_outline,
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
            
            ..._planPrices.entries.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: BuddyTheme.spacingMd),
              child: _buildPlanCard(
                plan.key,
                plan.value.toDouble(),
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

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: BuddyTheme.spacingXs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: BuddyTheme.textSecondaryColor,
          ),
        ),
      ],
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
    return Container(
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
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
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
                    children: options.map((option) {
                      final isSelected = selectedValue == option;
                      return InkWell(
                        onTap: () => onChanged(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BuddyTheme.spacingMd,
                            vertical: BuddyTheme.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BuddyTheme.primaryColor
                                : BuddyTheme.primaryColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(BuddyTheme.borderRadiusSm),
                          ),
                          child: Text(
                            option,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : BuddyTheme.primaryColor,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
    IconData icon, [
    ThemeData? theme,
    Color? cardColor,
    Color? textPrimary,
    Color? textSecondary,
  ]) {
    final t = theme ?? Theme.of(context);
    final c = cardColor ?? t.cardColor;
    final tp = textPrimary ?? t.textTheme.bodyLarge?.color ?? Colors.black;
    final ts =
        textSecondary ??
        t.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
        Colors.black54;

    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: c,
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
                  style: t.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tp,
                  ),
                ),
                Text(
                  subtitle,
                  style: t.textTheme.bodySmall?.copyWith(color: ts),
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
    );
  }

  Widget _buildCounterCard(
    String title,
    int value,
    Function(int) onChanged,
    IconData icon, [
    ThemeData? theme,
    Color? cardColor,
    Color? textPrimary,
  ]) {
    final t = theme ?? Theme.of(context);
    final c = cardColor ?? t.cardColor;
    final tp = textPrimary ?? t.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: c,
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
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: tp,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: value > 0 ? BuddyTheme.primaryColor : t.disabledColor,
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
                  style: TextStyle(
                    color: BuddyTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: BuddyTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector([
    ThemeData? theme,
    Color? cardColor,
    Color? textPrimary,
  ]) {
    final t = theme ?? Theme.of(context);
    final c = cardColor ?? t.cardColor;
    final tp = textPrimary ?? t.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: c,
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
              Icon(Icons.calendar_today_outlined,
                color: BuddyTheme.primaryColor,
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Text(
                'Move-in Date',
                style: t.textTheme.titleMedium?.copyWith(
                  color: tp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _moveInDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null && picked != _moveInDate) {
                setState(() {
                  _moveInDate = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              decoration: BoxDecoration(
                color: theme?.scaffoldBackgroundColor ?? Colors.grey[100],
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                border: Border.all(
                  color: BuddyTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _moveInDate == null
                        ? 'Select Date'
                        : '${_moveInDate!.day}/${_moveInDate!.month}/${_moveInDate!.year}',
                    style: t.textTheme.bodyLarge?.copyWith(
                      color: tp,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: BuddyTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
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
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: BuddyTheme.textSecondaryColor,
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: _currentStep < _totalSteps - 1 ? _nextStep : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: BuddyTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: BuddyTheme.spacingXl,
                vertical: BuddyTheme.spacingMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentStep < _totalSteps - 1 ? 'Next' : 'Submit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentStep < _totalSteps - 1) ...[
                  const SizedBox(width: BuddyTheme.spacingSm),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
