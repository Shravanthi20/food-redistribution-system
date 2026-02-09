import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Ensure this file exists and is generated
import 'screens/welcome_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/donation_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FoodRedistributionApp());
}

class FoodRedistributionApp extends StatelessWidget {
  const FoodRedistributionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DonationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Food Redistribution Platform',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            onGenerateRoute: AppRouter.generateRoute,
            home: const WelcomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
