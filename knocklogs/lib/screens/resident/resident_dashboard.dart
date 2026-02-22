import 'package:flutter/material.dart';

class ResidentDashboard extends StatelessWidget {
  const ResidentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resident Dashboard")),
      body: const Center(child: Text("Welcome Resident")),
    );
  }
}