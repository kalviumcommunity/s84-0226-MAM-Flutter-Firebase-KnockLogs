import 'package:flutter/material.dart';

class GuardDashboard extends StatelessWidget {
  const GuardDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Guard Dashboard")),
      body: const Center(child: Text("Welcome Guard")),
    );
  }
}