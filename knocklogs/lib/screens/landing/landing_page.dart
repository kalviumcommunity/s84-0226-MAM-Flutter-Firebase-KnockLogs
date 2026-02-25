import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../providers/theme_provider.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatController;

  // Color palette
  static const Color darkGreen = Color(0xFF40513B);
  static const Color mediumGreen = Color(0xFF628141);
  static const Color cream = Color(0xFFE5D9B6);
  static const Color orange = Color(0xFFE67E22);

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Trusted Community',
      description:
          'Secure visitor management system that connects residents, guards, and administrators seamlessly',
      primaryColor: mediumGreen,
      secondaryColor: darkGreen,
    ),
    OnboardingData(
      title: 'Smart Access',
      description:
          'Real-time visitor verification with instant notifications and complete access control',
      primaryColor: orange,
      secondaryColor: darkGreen,
    ),
    OnboardingData(
      title: 'Complete Security',
      description:
          'Track visitor history, manage entries, and enhance your community safety effortlessly',
      primaryColor: mediumGreen,
      secondaryColor: darkGreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header with logo and theme toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KnockLogs',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: theme.textColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      _buildThemeToggle(theme),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Onboarding cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildOnboardingCard(_pages[index], index, theme);
                    },
                  ),
                ),

                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? theme.primaryColor
                            : theme.primaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildButton(
                        label: 'Get Started',
                        onPressed: () {
                          Navigator.push(
                            context,
                            _createRoute(const RegisterScreen()),
                          );
                        },
                        isPrimary: true,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        label: 'Sign In',
                        onPressed: () {
                          Navigator.push(
                            context,
                            _createRoute(const LoginScreen()),
                          );
                        },
                        isPrimary: false,
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle(ThemeProvider theme) {
    return GestureDetector(
      onTap: theme.toggleTheme,
      child: Container(
        width: 70,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: theme.isDarkMode
                ? [const Color(0xFF2E3A59), const Color(0xFF1A1F2E)]
                : [const Color(0xFFFFC3A0), const Color(0xFFFFEFBA)],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorations
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: theme.isDarkMode ? 5 : 40,
              top: 5,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.isDarkMode
                      ? const Color(0xFFF4E5A1)
                      : const Color(0xFFFFD700),
                  boxShadow: [
                    BoxShadow(
                      color: theme.isDarkMode
                          ? const Color(0xFFF4E5A1).withOpacity(0.5)
                          : const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: theme.isDarkMode
                    ? Stack(
                        children: [
                          Positioned(
                            right: 8,
                            top: 3,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2E3A59),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 3,
                            top: 8,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2E3A59),
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            // Stars for dark mode
            if (theme.isDarkMode) ...[
              Positioned(
                right: 15,
                top: 8,
                child: Icon(
                  Icons.star,
                  size: 8,
                  color: const Color(0xFFF4E5A1).withOpacity(0.7),
                ),
              ),
              Positioned(
                right: 25,
                top: 15,
                child: Icon(
                  Icons.star,
                  size: 6,
                  color: const Color(0xFFF4E5A1).withOpacity(0.5),
                ),
              ),
            ],
            // Clouds for light mode
            if (!theme.isDarkMode) ...[
              Positioned(
                left: 5,
                top: 10,
                child: Container(
                  width: 12,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(
    OnboardingData data,
    int index,
    ThemeProvider theme,
  ) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }

        return Center(
          child: Opacity(
            opacity: value,
            child: Transform.scale(scale: value, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: data.primaryColor.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 60),

              // 3D Illustration container
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      math.sin(_floatController.value * math.pi * 2) * 15,
                    ),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            data.primaryColor.withOpacity(0.3),
                            data.secondaryColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Center(
                        child: _buildIllustration(data, index, theme),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textColor.withOpacity(0.6),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(
    OnboardingData data,
    int index,
    ThemeProvider theme,
  ) {
    // Create different illustrations for each page
    if (index == 0) {
      // Trusted Community - Two hands exchanging
      return Stack(
        alignment: Alignment.center,
        children: [
          // Bottom circle platform
          Positioned(
            bottom: 20,
            child: Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: LinearGradient(
                  colors: [
                    data.secondaryColor.withOpacity(0.4),
                    data.primaryColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // Hands illustration
          Transform.translate(
            offset: const Offset(-30, -20),
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: data.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.primaryColor.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(30, -20),
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Center star/sparkles
          ...List.generate(3, (i) {
            return Transform.translate(
              offset: Offset((i - 1) * 15.0, -40 + (i % 2) * 10.0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: cream,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cream.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    } else if (index == 1) {
      // Smart Access - Fingerprint
      return Stack(
        alignment: Alignment.center,
        children: [
          // Platform
          Positioned(
            bottom: 20,
            child: Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: LinearGradient(
                  colors: [
                    data.secondaryColor.withOpacity(0.4),
                    orange.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          // Fingerprint circles
          ...List.generate(5, (i) {
            return Container(
              width: 180.0 - (i * 30),
              height: 180.0 - (i * 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: i % 2 == 0 ? orange : data.primaryColor,
                  width: 6,
                ),
              ),
            );
          }),
          // Center circle
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: orange.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Complete Security - Shield/Layers
      return Stack(
        alignment: Alignment.center,
        children: [
          // Platform
          Positioned(
            bottom: 20,
            child: Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: LinearGradient(
                  colors: [
                    data.secondaryColor.withOpacity(0.4),
                    data.primaryColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // Stacked circles (backup/layers concept)
          ...List.generate(3, (i) {
            return Transform.translate(
              offset: Offset(0, -i * 25.0),
              child: Container(
                width: 140 - (i * 20),
                height: 140 - (i * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 0
                      ? orange
                      : i == 1
                      ? data.primaryColor
                      : data.secondaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: (i == 0 ? orange : data.primaryColor).withOpacity(
                        0.4,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: i == 0
                    ? Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: cream,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          }),
        ],
      );
    }
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required ThemeProvider theme,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isPrimary
            ? LinearGradient(colors: [theme.primaryColor, theme.accentColor])
            : null,
        border: isPrimary
            ? null
            : Border.all(color: theme.primaryColor, width: 2),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;

  OnboardingData({
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
  });
}
