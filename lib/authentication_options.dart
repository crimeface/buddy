import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthOptionsPage extends StatefulWidget {
  const AuthOptionsPage({super.key});

  @override
  State<AuthOptionsPage> createState() => _AuthOptionsPageState();
}

class _AuthOptionsPageState extends State<AuthOptionsPage> {
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark 
          ? SystemUiOverlayStyle.light 
          : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(isDark),
              const SizedBox(height: 50),
              _buildAuthButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2)).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you\'d like to sign in',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButtons(bool isDark) {
    return Column(
      children: [
        _buildEmailButton(isDark),
        const SizedBox(height: 16),
        _buildPhoneButton(isDark),
      ],
    );
  }

  Widget _buildEmailButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToEmailAuth,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Continue with Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToPhoneAuth,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Continue with Phone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEmailAuth() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToPhoneAuth() {
    Navigator.pushNamed(context, '/phone-verification');
  }
}