import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../resident/resident_dashboard.dart';
import '../guard/guard_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'register_screen.dart';
import '../../services/google_auth_service.dart';
import '../../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initial entrance animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Continuous rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void loginUser() async {
    setState(() {
      isLoading = true;
    });

    String? role = await _authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (role == "resident") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResidentDashboard()),
      );
    } else if (role == "guard") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GuardDashboard()),
      );
    } else if (role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.backgroundColor,
                  theme.cardColor,
                  theme.backgroundColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with back button and theme toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.cardColor,
                                foregroundColor: theme.textColor,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                            _buildThemeToggle(theme),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Animated Illustration
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  height: 180,
                                  width: 180,
                                  margin: const EdgeInsets.only(bottom: 32),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        theme.primaryColor.withOpacity(0.2),
                                        theme.backgroundColor,
                                      ],
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer rotating circle with continuous animation
                                      AnimatedBuilder(
                                        animation: _rotationController,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle:
                                                _rotationController.value *
                                                2 *
                                                3.14159,
                                            child: Container(
                                              height: 160,
                                              width: 160,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: theme.primaryColor
                                                      .withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Stack(
                                                children: List.generate(
                                                  8,
                                                  (index) => Positioned(
                                                    top: index % 2 == 0
                                                        ? 10
                                                        : null,
                                                    bottom: index % 2 == 1
                                                        ? 10
                                                        : null,
                                                    left: (index ~/ 2) * 40.0,
                                                    child: Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: theme
                                                            .primaryColor
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Center icon
                                      Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.primaryColor
                                                  .withOpacity(0.3),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.shield_outlined,
                                          size: 50,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Title
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Sign in to continue to KnockLogs',
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.textColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Email Field
                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          theme: theme,
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          theme: theme,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: theme.textColor.withOpacity(0.5),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : loginUser,
                            style:
                                ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: theme.textColor,
                                  elevation: 0,
                                  shadowColor: theme.primaryColor.withOpacity(
                                    0.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  disabledBackgroundColor: theme.textColor
                                      .withOpacity(0.3),
                                ).copyWith(
                                  backgroundColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryColor,
                                    theme.accentColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.textColor,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textColor,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: theme.textColor.withOpacity(0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: theme.textColor.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.textColor.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Google Sign In Button
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : _signInWithGoogle,
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 28,
                                  color: theme.textColor.withOpacity(0.7),
                                );
                              },
                            ),
                            label: Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor.withOpacity(0.7),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: theme.cardColor,
                              side: BorderSide(
                                color: theme.textColor.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: theme.textColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2E3A59),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 3,
                            top: 8,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2E3A59),
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider theme,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.textColor.withOpacity(0.4)),
              prefixIcon: Icon(icon, color: theme.textColor.withOpacity(0.6)),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      print("🔵 Starting Google Sign-In...");
      final user = await _googleAuthService.signInWithGoogle();

      print("✅ User: $user");
      if (user != null && mounted) {
        print("✅ Google Login Successful! Navigating...");

        // Default to resident dashboard (GoogleAuthService sets role as "resident")
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResidentDashboard()),
        );
      } else {
        print("⚠️ User is null");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google Sign-In cancelled")),
          );
        }
      }
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
