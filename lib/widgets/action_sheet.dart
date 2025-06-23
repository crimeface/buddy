import 'package:flutter/material.dart';
import '../theme.dart';
import 'list_room_form.dart';
import 'room_request_form.dart';
import 'list_hostel_form.dart';
import 'list_service_form.dart';

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

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always use dark mode style for the sheet, regardless of app theme
    const darkSheetColor = Color(0xFF23272F); // Typical dark background
    const darkDividerColor = Color(0xFF44474F);
    const darkTextColor = Colors.white;
    const darkSecondaryTextColor = Color(0xFFB0B3B8);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 400 * _slideAnimation.value),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.95,
            ),
            child: Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingLg),
              decoration: BoxDecoration(
                color: darkSheetColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(BuddyTheme.borderRadiusXl),
                  topRight: Radius.circular(BuddyTheme.borderRadiusXl),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: darkDividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingLg),

                    // Title
                    Text(
                      'What would you like to do?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkTextColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXs),
                    Text(
                      'Choose an option to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: darkSecondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: BuddyTheme.spacingXl),

                    // Action buttons grid
                    Column(
                      children: [
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
                                    colors: [
                                      BuddyTheme.primaryColor,
                                      BuddyTheme.secondaryColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const ListRoomForm(),
                                      ),
                                    );
                                  },
                                  forceDark: true,
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
                                    colors: [
                                      BuddyTheme.accentColor,
                                      BuddyTheme.successColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const RoomRequestForm(),
                                      ),
                                    );
                                  },
                                  forceDark: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: BuddyTheme.spacingMd),
                        Row(
                          children: [
                            Expanded(
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: _buildActionButton(
                                  context,
                                  title: 'List Hostel/PG',
                                  subtitle: 'List your accommodation',
                                  icon: Icons.apartment_outlined,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF9C27B0),
                                      Color(0xFFE91E63),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () {
                                    print(
                                      'List Hostel/PG button tapped',
                                    ); // Debug print
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ListHostelForm(),
                                      ),
                                    );
                                  },
                                  forceDark: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: BuddyTheme.spacingMd),
                            Expanded(
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: _buildActionButton(
                                  context,
                                  title: 'List Services',
                                  subtitle: 'Share your expertise',
                                  icon: Icons.miscellaneous_services_outlined,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00BCD4),
                                      Color(0xFF03A9F4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ListServiceForm(),
                                      ),
                                    );
                                  },
                                  forceDark: true,
                                ),
                              ),
                            ),
                          ],
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: darkSecondaryTextColor),
                        ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
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
    bool forceDark = false, // new param
  }) {
    // Always use dark mode for action buttons if forceDark is true
    final Color iconBg = forceDark ? Colors.white.withOpacity(0.2) : Theme.of(context).cardColor;
    final Color titleColor = forceDark ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    final Color subtitleColor = forceDark ? Colors.white.withOpacity(0.8) : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8) ?? Colors.white70;
    final Color arrowColor = forceDark ? Colors.white.withOpacity(0.8) : Theme.of(context).iconTheme.color ?? Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusLg),
      child: Container(
        height: 173,
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
            // Decorative circles (unchanged)...

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
                      color: iconBg,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
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
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BuddyTheme.spacingXxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 12, // Slightly reduced font size
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  const SizedBox(height: BuddyTheme.spacingXs),
                  Icon(
                    Icons.arrow_forward,
                    color: arrowColor,
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
}
