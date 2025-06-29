// signup.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with TickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  late AnimationController _animationController;
  late AnimationController _formAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        // Send email verification
        try {
          await userCredential.user!.sendEmailVerification();
        } catch (e) {
          debugPrint('sendEmailVerification error: '
              + e.toString());
          if (mounted) {
            showCustomSnackBar(context, 'Failed to send verification email: '
                + e.toString(), backgroundColor: Colors.red, icon: Icons.error);
          }
        }

        // Update the user's display name in Firebase Authentication
        await userCredential.user!.updateDisplayName(
          _fullNameController.text.trim(),
        );

        // Store user data in Firestore
        final userId = userCredential.user!.uid;
        final userEmail = _emailController.text.trim();
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'username': _fullNameController.text.trim(),
          'email': userEmail,
          'phone': _phoneController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });

        // If the user is the admin, add to 'admins' collection
        if (userEmail.toLowerCase() == 'campusnest12@gmail.com') {
          await FirebaseFirestore.instance.collection('admins').doc(userId).set(
            {'email': userEmail, 'createdAt': DateTime.now().toIso8601String()},
          );
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showCustomSnackBar(context, 'A verification email has been sent. Please verify your email before logging in.', backgroundColor: Colors.green, icon: Icons.email);
          Navigator.pushReplacementNamed(context, '/login');
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });
        String errorMsg = 'Registration failed';
        if (e.code == 'email-already-in-use') {
          errorMsg = 'Email already in use';
        } else if (e.code == 'invalid-email') {
          errorMsg = 'Invalid email address';
        } else if (e.code == 'weak-password') {
          errorMsg = 'Password is too weak';
        }
        showCustomSnackBar(context, errorMsg, backgroundColor: Colors.red, icon: Icons.error);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        showCustomSnackBar(context, 'An error occurred. Please try again.', backgroundColor: Colors.red, icon: Icons.error);
      }
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isDark,
    bool obscureText = false,
    bool hasVisibilityToggle = false,
    bool? isVisible,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2))
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B),
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          suffixIcon: hasVisibilityToggle
              ? IconButton(
                  icon: Icon(
                    isVisible! ? Icons.visibility : Icons.visibility_off,
                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B),
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  void showCustomSnackBar(BuildContext context, String message, {Color? backgroundColor, IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        // Navigate to login page when back button is pressed
        Navigator.pushReplacementNamed(context, '/login');
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
        body: Container(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
          child: Stack(
            children: [
              // Clean background without floating elements
              
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Lottie Animation (standalone)
                                SizedBox(
                                  height: 120,
                                  width: 120,
                                  child: Lottie.asset(
                                    'assets/animations/register.json',
                                    fit: BoxFit.contain,
                                    repeat: true,
                                    animate: true,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Form Container
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isDark ? Border.all(
                                      color: const Color(0xFF334155),
                                      width: 1,
                                    ) : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2))
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Title
                                      Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Join us to get started',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      
                                      // Full Name Field
                                      _buildCustomTextField(
                                        controller: _fullNameController,
                                        hintText: 'Full Name',
                                        icon: Icons.person_outline,
                                        isDark: isDark,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your full name';
                                          }
                                          return null;
                                        },
                                      ),

                                      // Phone Field
                                      _buildCustomTextField(
                                        controller: _phoneController,
                                        hintText: 'Phone Number',
                                        icon: Icons.phone_android_outlined,
                                        isDark: isDark,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your full name';
                                          }
                                          return null;
                                        },
                                      ),

                                      // Email Field
                                      _buildCustomTextField(
                                        controller: _emailController,
                                        hintText: 'Email Address',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        isDark: isDark,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!value.contains('@') || !value.contains('.')) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),

                                      // Password Field
                                      _buildCustomTextField(
                                        controller: _passwordController,
                                        hintText: 'Password',
                                        icon: Icons.lock_outline,
                                        obscureText: !_isPasswordVisible,
                                        hasVisibilityToggle: true,
                                        isVisible: _isPasswordVisible,
                                        isDark: isDark,
                                        onVisibilityToggle: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),

                                      // Confirm Password Field
                                      _buildCustomTextField(
                                        controller: _confirmPasswordController,
                                        hintText: 'Confirm Password',
                                        icon: Icons.lock_outline,
                                        obscureText: !_isConfirmPasswordVisible,
                                        hasVisibilityToggle: true,
                                        isVisible: _isConfirmPasswordVisible,
                                        isDark: isDark,
                                        onVisibilityToggle: () {
                                          setState(() {
                                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your password';
                                          }
                                          if (value != _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 16),

                                      // Sign Up Button
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2))
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _handleSignUp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : const Text(
                                                  'Create Account',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // Sign In Option
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Already have an account?',
                                            style: TextStyle(
                                              color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushReplacementNamed(context, '/login');
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: isDark ? const Color(0xFF4A90E2) : const Color(0xFF1E3A8A),
                                              padding: const EdgeInsets.only(left: 8),
                                            ),
                                            child: const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}