import 'package:flutter/material.dart';

class ActivityListScreen extends StatelessWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktiviteler')),
      body: const Center(child: Text('Aktivite Takibi — Yakında')),
    );
  }
}
