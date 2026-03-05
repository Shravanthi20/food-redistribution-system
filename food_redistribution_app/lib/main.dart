import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const FoodRedistributionApp());
}

class FoodRedistributionApp extends StatelessWidget {
  const FoodRedistributionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Redistribution Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}