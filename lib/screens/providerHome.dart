import 'package:flutter/material.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Dashboard")),
      body: const Center(
        child: Text(
          "Welcome Provider 👷‍♂️",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
