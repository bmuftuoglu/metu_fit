import 'package:flutter/material.dart';

class DailyLogScreen extends StatelessWidget {
  const DailyLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Takip')),
      body: const Center(child: Text('Kalori Takibi — Yakında')),
    );
  }
}
