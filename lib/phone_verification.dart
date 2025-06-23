import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({Key? key}) : super(key: key);

  @override
  _PhoneVerificationPageState createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = '';
  bool _isLoading = false;

  late AnimationController _slideController;

  int currentPage = 0;
  String phoneNumber = '';
  String fullName = '';

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateToOTP() async {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        phoneNumber = _phoneController.text;
        _isLoading = true;
      });

      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: '+91${_phoneController.text}',
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification if Android supports it
            await _auth.signInWithCredential(credential);
            _onVerificationComplete();
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? 'Verification failed'),
                backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
              ),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
              currentPage = 1;
            });
            _slideController.forward();
            _pageController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });
          },
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
          ),
        );
      }
    }
  }

  void _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == 6) {
      setState(() {
        _isLoading = true;
      });

      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: otp,
        );

        // Sign in with credential
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // Check if user exists in Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

        setState(() {
          _isLoading = false;
        });

        if (userDoc.exists) {
          // User already exists, redirect to homepage
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        } else {
          // New user, continue to name input page
          setState(() {
            currentPage = 2;
          });
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
        ),
      );
    }
  }

  void _submitFullName() async {
    if (_fullNameController.text.trim().isNotEmpty) {
      setState(() {
        fullName = _fullNameController.text.trim();
        _isLoading = true;
      });

      try {
        // Get current user
        final User? user = _auth.currentUser;

        if (user != null) {
          // Update display name in Firebase Auth
          await user.updateDisplayName(fullName);

          // Store user data in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'username': fullName,
                'phone': '+91$phoneNumber',
                'createdAt': DateTime.now().toIso8601String(),
              });

          setState(() {
            _isLoading = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome, $fullName! Registration completed successfully.',
              ),
              backgroundColor: isDark ? const Color(0xFF28A745) : Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to homepage and remove all previous routes
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        } else {
          throw Exception('User not found');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving user data. Please try again.'),
            backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
        ),
      );
    }
  }

  void _goBack() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      if (currentPage == 0) {
        _slideController.reverse();
      }
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onVerificationComplete() {
    setState(() {
      _isLoading = false;
      currentPage = 2;
    });
    _pageController.animateToPage(
      2,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _resendOTP() async {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: '+91${_phoneController.text}',
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
            _onVerificationComplete();
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() {
              _isLoading = false;
            });
            showCustomSnackBar(
              context,
              e.message ?? 'Verification failed',
              backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
              icon: Icons.error,
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });
            showCustomSnackBar(
              context,
              'OTP Resent',
              backgroundColor: primaryColor,
              icon: Icons.sms,
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });
          },
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        showCustomSnackBar(
          context,
          'Error: ${e.toString()}',
          backgroundColor: isDark ? const Color(0xFFE74C3C) : Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  // Custom SnackBar for consistent UI
  void showCustomSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
  }) {
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? (const Color(0xFF2C3E50)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Updated theme-aware colors to match login page
  bool get isDark => true;

  Color get backgroundColor => const Color(0xFF121212);
  Color get cardColor => const Color.fromARGB(255, 38, 40, 44);
  Color get textColor => Colors.white;
  Color get subtitleColor => Colors.white.withOpacity(0.9);
  Color get hintColor => Colors.white.withOpacity(0.7);
  Color get borderColor => const Color(0xFF334155);
  Color get primaryColor => const Color(0xFF2C3E50);
  Color get primaryGradientEnd => const Color(0xFF2C3E50);
  Color get shadowColor => const Color(0xFF2C3E50).withOpacity(0.3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light, // changed from dark to light for visibility
        leading:
            currentPage > 0
                ? IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                  onPressed: _goBack,
                )
                : null,
        title: Text(
          currentPage == 0
              ? 'Verification'
              : currentPage == 1
              ? 'OTP Verification'
              : 'Complete Profile',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildPhoneInputPage(),
              _buildOTPVerificationPage(),
              _buildFullNamePage(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 60),

          // Lottie Animation for Phone Input
          Container(
            height: 200,
            child: Lottie.asset(
              'assets/animations/phonenumber.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),

          SizedBox(height: 40),

          Text(
            'Your Phone !',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          SizedBox(height: 12),

          Text(
            'We will send you an one time password\non this mobile number',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: subtitleColor, height: 1.5),
          ),

          SizedBox(height: 50),

          // Phone Number Input
          Container(
            decoration: BoxDecoration(
              color: cardColor, // changed from white to cardColor
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter Phone Number',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Container(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, color: primaryColor),
                      SizedBox(width: 8),
                      Text(
                        '+91',
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                      SizedBox(width: 8),
                      Container(height: 20, width: 1, color: borderColor),
                    ],
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                fillColor: cardColor, // ensure cardColor is used
                filled: true, // ensure background is filled
              ),
            ),
          ),

          SizedBox(height: 40),

          // Receive OTP Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _navigateToOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Receive OTP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPVerificationPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 60),

          // Lottie Animation for OTP
          Container(
            height: 200,
            child: Lottie.asset(
              'assets/animations/otp.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),

          SizedBox(height: 40),

          Text(
            'OTP verification',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          SizedBox(height: 12),

          Text(
            'Enter OTP sent to +91 $phoneNumber',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: subtitleColor, height: 1.5),
          ),

          SizedBox(height: 50),

          // OTP Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return Container(
                width: 45,
                height: 55,
                decoration: BoxDecoration(
                  color: cardColor, // changed from white to cardColor
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    fillColor: cardColor, // ensure cardColor is used
                    filled: true, // ensure background is filled
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      // Clear any extra characters and keep only the first digit
                      if (value.length > 1) {
                        _otpControllers[index].text = value[0];
                        _otpControllers[index].selection =
                            TextSelection.fromPosition(TextPosition(offset: 1));
                        return;
                      }
                      // Move to next field
                      if (index < 5) {
                        FocusScope.of(context).nextFocus();
                      } else {
                        // Last field, remove focus
                        FocusScope.of(context).unfocus();
                      }
                    } else {
                      // Handle backspace - move to previous field
                      if (index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    }
                  },
                  onTap: () {
                    // Clear the field when tapped
                    _otpControllers[index].clear();
                  },
                  onEditingComplete: () {
                    if (index < 5 && _otpControllers[index].text.isNotEmpty) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              );
            }),
          ),

          SizedBox(height: 30),

          // Resend OTP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive OTP? ",
                style: TextStyle(color: subtitleColor, fontSize: 14),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _resendOTP,
                child: Text(
                  'Resend',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Verify & Proceed Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Verify & Proceed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullNamePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 60),

          // User Profile Icon or Animation
          Container(
            height: 200,
            child: Icon(Icons.person_outline, size: 120, color: primaryColor),
          ),

          SizedBox(height: 40),

          Text(
            'What\'s your name?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          SizedBox(height: 12),

          Text(
            'Please enter your full name to complete\nyour profile setup',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: subtitleColor, height: 1.5),
          ),

          SizedBox(height: 50),

          // Full Name Input
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _fullNameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.person, color: primaryColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          SizedBox(height: 40),

          // Continue Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _submitFullName,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Complete Registration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Updated MyApp class with matching theme colors
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Verification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E293B),
      ),
      themeMode: ThemeMode.dark,
      home: PhoneVerificationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(MyApp());
}