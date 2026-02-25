import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/resident/resident_dashboard.dart';
import 'screens/guard/guard_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/landing/landing_page.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _navigateToRoleScreen();
  }

  Future<void> _navigateToRoleScreen() async {
    try {
      User? user = _auth.currentUser;
      
      if (user == null) {
        // Not authenticated, go back to landing
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (Route<dynamic> route) => false,
          );
        }
        return;
      }

      // Get user role from Firestore
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists) {
        // User document doesn't exist, logout and go to landing
        await _auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (Route<dynamic> route) => false,
          );
        }
        return;
      }

      String? role = (userDoc.data() as Map<String, dynamic>)['role'];

      if (!mounted) return;

      // Navigate based on role
      if (role == 'resident') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ResidentDashboard()),
          (Route<dynamic> route) => false,
        );
      } else if (role == 'guard') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GuardDashboard()),
          (Route<dynamic> route) => false,
        );
      } else if (role == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Unknown role, go back to landing
        await _auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print("Error navigating to role screen: $e");
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Loading your dashboard..."),
          ],
        ),
      ),
    );
  }
}