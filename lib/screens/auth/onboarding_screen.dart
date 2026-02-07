import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  final dynamic userRole;
  
  const OnboardingScreen({Key? key, this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: const Center(
        child: Text('Onboarding Screen - To be implemented'),
      ),
    );
  }
}