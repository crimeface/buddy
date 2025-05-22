import 'package:flutter/material.dart';
import '../theme.dart';

class ActionBottomSheet extends StatefulWidget {
  const ActionBottomSheet({Key? key}) : super(key: key);

  @override
  State<ActionBottomSheet> createState() => _ActionBottomSheetState();
}

class _ActionBottomSheetState extends State<ActionBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 400 * _slideAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(BuddyTheme.spacingLg),
            decoration: const BoxDecoration(
              color: BuddyTheme.backgroundPrimaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(BuddyTheme.borderRadiusXl),
                topRight: Radius.circular(BuddyTheme.borderRadiusXl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BuddyTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingLg),
                
                // Title
                Text(
                  'What would you like to do?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  'Choose an option to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BuddyTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXl),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildActionButton(
                          context,
                          title: 'List a Room',
                          subtitle: 'Share your space',
                          icon: Icons.home_outlined,
                          gradient: const LinearGradient(
                            colors: [BuddyTheme.primaryColor, BuddyTheme.secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to list room page
                            _showSnackBar(context, 'Navigating to List a Room');
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: BuddyTheme.spacingMd),
                    Expanded(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildActionButton(
                          context,
                          title: 'Ask for Room',
                          subtitle: 'Find your place',
                          icon: Icons.search_outlined,
                          gradient: const LinearGradient(
                            colors: [BuddyTheme.accentColor, BuddyTheme.successColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to ask for room page
                            _showSnackBar(context, 'Navigating to Ask for Room');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: BuddyTheme.spacingLg),
                
                // Cancel button
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: BuddyTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(BuddyTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: BuddyTheme.iconSizeLg,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Text content
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: BuddyTheme.spacingXxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  
                  const SizedBox(height: BuddyTheme.spacingXs),
                  
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BuddyTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
        ),
      ),
    );
  }
}