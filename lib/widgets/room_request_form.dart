import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

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

  int _currentStep = 0;
  final int _totalSteps = 4; // Basic Info, Room Requirements, Additional Preferences, Contact Details

  // Form controllers and data
  final _formKey = GlobalKey<FormState>();
  
  // Basic Info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  String _occupation = 'Student';

  // Room Requirements
  final _locationController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  DateTime? _moveInDate;
  String _preferredRoomType = 'Private';
  int _preferredFlatmates = 1;
  String _preferredFlatmateGender = 'Any';

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

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

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
    } else {
      _submitForm();
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

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Add form submission logic here
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuddyTheme.backgroundSecondaryColor,
      appBar: AppBar(
        title: const Text('Request a Room'),
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
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
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
                  _buildBasicInfoStep(),
                  _buildRoomRequirementsStep(),
                  _buildAdditionalPreferencesStep(),
                  _buildContactDetailsStep(),
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
                valueColor: AlwaysStoppedAnimation<Color>(BuddyTheme.primaryColor),
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
            _buildStepHeader(
              '👤 Basic Information',
              'Tell us about yourself',
            ),
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
            
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedTextField(
                    controller: _minBudgetController,
                    label: 'Min Budget (₹)',
                    hint: 'Minimum',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: BuddyTheme.spacingMd),
                Expanded(
                  child: _buildAnimatedTextField(
                    controller: _maxBudgetController,
                    label: 'Max Budget (₹)',
                    hint: 'Maximum',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: BuddyTheme.spacingLg),
            
            _buildDateSelector(),
            
            const SizedBox(height: BuddyTheme.spacingLg),
            
            _buildSelectionCard(
              'Preferred Room Type',
              _preferredRoomType,
              ['Shared', 'Private', '1BHK', '2BHK'],
              (value) => setState(() => _preferredRoomType = value),
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
              ['Any', 'Male', 'Female', 'Other'],
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
              'Pets',
              _petsPreference,
              ['No', 'Yes', "Don't Mind"],
              (value) => setState(() => _petsPreference = value),
              Icons.pets_outlined,
            ),
            
            const SizedBox(height: BuddyTheme.spacingLg),
            
            _buildSwitchCard(
              'Internet Required',
              'Do you need high-speed internet?',
              _internetRequired,
              (value) => setState(() => _internetRequired = value),
              Icons.wifi,
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
            _buildStepHeader(
              '📞 Contact Details',
              'How can people reach you?',
            ),
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

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
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
        color: Colors.white,
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: BuddyTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Wrap(
            spacing: BuddyTheme.spacingSm,
            runSpacing: BuddyTheme.spacingSm,
            children: options.map((option) => GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: BuddyTheme.spacingMd,
                  vertical: BuddyTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: selectedValue == option
                      ? BuddyTheme.primaryColor
                      : BuddyTheme.backgroundSecondaryColor,
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                  border: Border.all(
                    color: selectedValue == option
                        ? BuddyTheme.primaryColor
                        : BuddyTheme.borderColor,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: selectedValue == option
                        ? Colors.white
                        : BuddyTheme.textPrimaryColor,
                    fontWeight: selectedValue == option
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BuddyTheme.textSecondaryColor,
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
    );
  }

  Widget _buildCounterCard(
    String title,
    int value,
    Function(int) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: value > 0 ? BuddyTheme.primaryColor : BuddyTheme.textSecondaryColor,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BuddyTheme.spacingMd,
                  vertical: BuddyTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: BuddyTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
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

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icon(Icons.calendar_today_outlined, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingMd),
              Text(
                'Move-in Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              if (picked != null) {
                setState(() => _moveInDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BuddyTheme.spacingMd,
                vertical: BuddyTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: BuddyTheme.borderColor),
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _moveInDate == null
                        ? 'Select Date'
                        : '${_moveInDate!.day}/${_moveInDate!.month}/${_moveInDate!.year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _moveInDate == null
                          ? BuddyTheme.textSecondaryColor
                          : BuddyTheme.textPrimaryColor,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: BuddyTheme.textSecondaryColor),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
              label: const Text('Previous'),
              style: TextButton.styleFrom(
                foregroundColor: BuddyTheme.primaryColor,
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: BuddyTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: BuddyTheme.spacingLg,
                vertical: BuddyTheme.spacingMd,
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentStep == _totalSteps - 1 ? 'Submit' : 'Next',
                  style: const TextStyle(color: Colors.white),
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