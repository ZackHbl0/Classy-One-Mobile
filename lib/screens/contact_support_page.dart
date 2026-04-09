import 'package:flutter/material.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacter l\'administration')),
      body: const Center(child: Text('Formulaire de contact / Mailer')),
    );
  }
}
