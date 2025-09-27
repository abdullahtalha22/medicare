import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // next screen after onboarding

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardSlide> slides = [
    _OnboardSlide(
      animationPath: 'assets/animations/onboard1.json',
      title: 'Your Health, On Schedule',
      description:
      'Organize your medications with ease and confidence — your wellness, always on time.',
    ),
    _OnboardSlide(
      animationPath: 'assets/animations/onboard2.json',
      title: 'Smart Reminders, Zero Misses',
      description:
      'Receive intelligent alerts so you never forget a dose again.',
    ),
    _OnboardSlide(
      animationPath: 'assets/animations/onboard3.json',
      title: 'Monitor. Improve. Thrive.',
      description:
      'Stay informed with prescription logs and health insights designed just for you.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    // Save onboarding completion in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingCompleted', true);

    // Navigate to LoginScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onNext() {
    if (_currentPage < slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page → mark onboarding complete
      _completeOnboarding();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF28C76F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            slide.animationPath,
                            width: 300,
                            height: 300,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            slide.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            slide.description,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Bottom controls
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip Button
                    TextButton(
                      onPressed: _onSkip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Indicators
                    Row(
                      children: List.generate(slides.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 10,
                          width: _currentPage == index ? 24 : 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }),
                    ),
                    // Next / Get Started Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF28C76F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: _onNext,
                      child: Text(
                        _currentPage == slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide {
  final String animationPath;
  final String title;
  final String description;
  _OnboardSlide({
    required this.animationPath,
    required this.title,
    required this.description,
  });
}
