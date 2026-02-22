import 'package:flutter/material.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int entryCount = 0;

  void incrementEntry() {
    setState(() {
      entryCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resident Entry Counter"),
      ),
      body: Center(
        child: Text(
          "Total Entries: $entryCount",
          style: const TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: incrementEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}