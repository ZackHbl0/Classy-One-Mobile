import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos de l\'application')),
      body: const Center(child: Text('Version 1.0.0\nOSBT Notify')),
    );
  }
}
