import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/config/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      imagePath: 'assets/images/onboarding_lost.png',
      title: 'Report Lost Items',
      description:
          'Quickly report items you\'ve lost anywhere on campus. '
          'Add photos, descriptions, and the exact location to help others find your belongings.',
      color: AppTheme.lostColor,
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding_found.png',
      title: 'Upload Found Items',
      description:
          'Found something on campus? Upload it with a photo and details. '
          'Help a fellow student or staff member recover their property.',
      color: AppTheme.foundColor,
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding_match.png',
      title: 'Match & Recover',
      description:
          'Our smart matching system helps connect lost items with found ones. '
          'Submit claims, verify ownership, and get your items back safely.',
      color: AppTheme.primaryGreen,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pages (Full screen)
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page);
            },
          ),

          // SafeArea elements (Skip, Indicators, Next Button)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

                // Bottom section (Indicators + Button)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppTheme.primaryGreen
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.asset(
          page.imagePath,
          fit: BoxFit.cover,
        ),
        // Dark Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.8),
                Colors.black,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        // Text Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page.description,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
                // Padding for bottom indicators and buttons
                const SizedBox(height: 160), 
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage {
  final String imagePath;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.color,
  });
}
