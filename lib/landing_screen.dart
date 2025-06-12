import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const LandingScreen({Key? key, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top illustration section
            Expanded(
              flex: 5,
              child: Center(
                child: Image.asset(
                  'assets/images/Landing screen of campusnest(final).png',
                  fit: BoxFit.contain,
                  width: 340,
                  height: 340,
                ),
              ),
            ),
            // Bottom blue section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors:
                        Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF232B3A), const Color(0xFF1A2233)]
                            : [
                              const Color(0xFF4A90E2),
                              const Color(0xFF357ABD),
                            ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Find your perfect\nplace!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          shadows:
                              Theme.of(context).brightness == Brightness.dark
                                  ? [
                                    const Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Browse flats, find roommates, PGs and\nnearby essentials — all in one app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.4,
                          shadows:
                              Theme.of(context).brightness == Brightness.dark
                                  ? [
                                    const Shadow(
                                      color: Colors.black38,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            onContinue();
                            print('Next button pressed');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.92)
                                    : Colors.white,
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF232B3A)
                                    : const Color(0xFF4A90E2),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF232B3A)
                                      : const Color(0xFF4A90E2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}