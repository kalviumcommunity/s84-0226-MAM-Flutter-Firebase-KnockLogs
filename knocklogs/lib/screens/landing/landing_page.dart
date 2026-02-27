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
                // Modern header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [mediumGreen, darkGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'KnockLogs',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: cream,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      _buildThemeToggle(theme),
                    ],
                  ),
                ),

                // Modern PageView with cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildModernCard(_pages[index], index, theme);
                    },
                  ),
                ),

                // Enhanced page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 10,
                          width: _currentPage == index ? 32 : 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? mediumGreen
                                : mediumGreen.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: mediumGreen.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Modern buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      _buildModernButton(
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
                      const SizedBox(height: 14),
                      _buildModernButton(
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.isDarkMode
                ? [const Color(0xFF2E3A59).withOpacity(0.8), const Color(0xFF1A1F2E).withOpacity(0.8)]
                : [mediumGreen.withOpacity(0.1), darkGreen.withOpacity(0.05)],
          ),
          border: Border.all(
            color: theme.isDarkMode
                ? const Color(0xFFF4E5A1).withOpacity(0.2)
                : mediumGreen.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.isDarkMode
                  ? const Color(0xFF2E3A59).withOpacity(0.2)
                  : mediumGreen.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: theme.toggleTheme,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Icon(
                theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: theme.isDarkMode ? const Color(0xFFF4E5A1) : mediumGreen,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard(
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

        return Opacity(
          opacity: value,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern glassmorphism card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.primaryColor.withOpacity(0.08),
                    data.secondaryColor.withOpacity(0.04),
                  ],
                ),
                border: Border.all(
                  color: data.primaryColor.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.primaryColor.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 8,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Enhanced illustration with animations
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          math.sin(_floatController.value * math.pi * 2) * 12,
                        ),
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                data.primaryColor.withOpacity(0.15),
                                data.secondaryColor.withOpacity(0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                          child: Center(
                            child: _buildModernIllustration(data, index, theme),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // Modern title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      data.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: theme.textColor,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Modern description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      data.description,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: theme.textColor.withOpacity(0.65),
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernIllustration(
    OnboardingData data,
    int index,
    ThemeProvider theme,
  ) {
    if (index == 0) {
      // Trusted Community - Modern design
      return Stack(
        alignment: Alignment.center,
        children: [
          // Background circles
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: data.primaryColor.withOpacity(0.15),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: orange.withOpacity(0.15),
                width: 2,
              ),
            ),
          ),
          // Main shapes
          Transform.translate(
            offset: const Offset(-45, -20),
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      data.primaryColor,
                      data.primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.primaryColor.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(-5, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(45, -20),
            child: Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      orange,
                      orange.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(35),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(5, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Central accent
          Transform.translate(
            offset: const Offset(0, 30),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cream,
                boxShadow: [
                  BoxShadow(
                    color: cream.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (index == 1) {
      // Smart Access - Modern rings
      return Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(4, (i) {
            return AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) => Transform.rotate(
                angle: _floatController.value *
                    (i % 2 == 0 ? math.pi * 2 : -math.pi * 2),
                child: Container(
                  width: 160.0 - (i * 35),
                  height: 160.0 - (i * 35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i % 2 == 0 ? orange : data.primaryColor,
                      width: 5,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Center sphere
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  orange,
                  orange.withOpacity(0.6),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: orange.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Complete Security - Modern layers
      return Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (i) {
            return Transform.translate(
              offset: Offset(0, -i * 20.0),
              child: Container(
                width: 150 - (i * 25),
                height: 150 - (i * 25),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (i == 0 ? orange : i == 1 ? data.primaryColor : darkGreen)
                          .withOpacity(0.9),
                      (i == 0
                              ? orange
                              : i == 1
                                  ? data.primaryColor
                                  : darkGreen)
                          .withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (i == 0
                              ? orange
                              : i == 1
                                  ? data.primaryColor
                                  : darkGreen)
                          .withOpacity(0.35),
                      blurRadius: 18,
                      offset: Offset(0, 8 + i * 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: i == 0
                    ? Center(
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: cream,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cream.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
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



  Widget _buildModernButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required ThemeProvider theme,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPrimary
            ? LinearGradient(
                colors: [mediumGreen, darkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isPrimary
            ? null
            : Border.all(
                color: mediumGreen.withOpacity(0.5),
                width: 2,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: mediumGreen.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: isPrimary ? Colors.white.withOpacity(0.1) : mediumGreen.withOpacity(0.1),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isPrimary ? cream : mediumGreen,
                letterSpacing: 0.3,
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
