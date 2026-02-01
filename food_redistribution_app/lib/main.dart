import 'package:flutter/material.dart';

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
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Food Redistribution Platform'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to Food Redistribution Platform',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Reducing food waste, feeding communities.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            Icon(
              Icons.restaurant,
              size: 100,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}