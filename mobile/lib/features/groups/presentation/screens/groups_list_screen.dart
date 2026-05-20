import 'package:flutter/material.dart';

class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gruplar')),
      body: const Center(child: Text('Gruplar — Yakında')),
    );
  }
}
