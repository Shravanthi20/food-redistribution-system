import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Ensure this file exists and is generated
import 'screens/welcome_screen.dart';
import 'providers/auth_provider.dart';
<<<<<<< HEAD:lib/main.dart
import 'providers/user_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/app_theme.dart';
=======
import 'providers/donation_provider.dart';

>>>>>>> feature/flutter-migration-complete:food_redistribution_app/lib/main.dart
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
<<<<<<< HEAD:lib/main.dart
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Food Redistribution Platform',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
=======
        ChangeNotifierProvider(create: (_) => DonationProvider()),
      ],
      child: MaterialApp(
        title: 'Food Redistribution Platform',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          fontFamily: 'Roboto',
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
        ),
        onGenerateRoute: AppRouter.generateRoute,
        home: const WelcomeScreen(),
        debugShowCheckedModeBanner: false,
>>>>>>> feature/flutter-migration-complete:food_redistribution_app/lib/main.dart
      ),
    );
  }
}