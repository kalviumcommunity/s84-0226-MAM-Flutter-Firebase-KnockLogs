import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../resident/resident_dashboard.dart';
import '../guard/guard_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'register_screen.dart';
import '../../services/google_auth_service.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool isLoading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KnockLogs Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: loginUser,
                    child: const Text("Login"),
                  ), ElevatedButton(
  onPressed: () async {
    setState(() => isLoading = true);
    try {
      print("🔵 Starting Google Sign-In...");
      final user = await _googleAuthService.signInWithGoogle();

      print("✅ User: $user");
      if (user != null) {
        print("✅ Google Login Successful! Navigating...");
        
        // Default to resident dashboard (GoogleAuthService sets role as "resident")
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResidentDashboard()),
        );
      } else {
        print("⚠️ User is null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In cancelled")),
        );
      }
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  },
  child: const Text("Sign in with Google"),
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
  child: const Text("Don't have an account? Register"),
),
          ],
        ),
      ),
    );
  }
}