import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Ensure this file exists and is generated
import 'generated/l10n/app_localizations.dart';
import 'screens/welcome_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/ngo_provider.dart';
import 'providers/accessibility_provider.dart';
import 'providers/locale_provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';
//import 'screens/donor/donor_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FoodRedistributionApp());
}

class FoodRedistributionApp extends StatelessWidget {
  const FoodRedistributionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DonationProvider()),
        ChangeNotifierProvider(create: (_) => NGOProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer3<ThemeProvider, AccessibilityProvider, LocaleProvider>(
        builder: (context, themeProvider, accessibilityProvider, localeProvider,
            child) {
          final isHighContrast = accessibilityProvider.highContrastMode;
          final ThemeData lightTheme = isHighContrast
              ? AppTheme.lightTheme.copyWith(
                  colorScheme: const ColorScheme.highContrastLight(),
                )
              : AppTheme.lightTheme;

          final ThemeData darkTheme = isHighContrast
              ? AppTheme.darkTheme.copyWith(
                  colorScheme: const ColorScheme.highContrastDark(),
                )
              : AppTheme.darkTheme;

          return MaterialApp(
            title: 'Food Redistribution Platform',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,

            // ── Localisation ──────────────────────────────────────────────
            locale: localeProvider.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Fallback: resolve the best supported locale when the device
            // locale is not in [supportedLocales].
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (deviceLocale == null) return LocaleProvider.fallbackLocale;
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale.languageCode) {
                  return supported;
                }
              }
              return LocaleProvider.fallbackLocale;
            },
            // ─────────────────────────────────────────────────────────────

            onGenerateRoute: AppRouter.generateRoute,
            home: const WelcomeScreen(), // ✅ DIRECT OPEN
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQueryData.copyWith(
                  textScaler: TextScaler.linear(
                    accessibilityProvider.textScaleFactor,
                  ),
                  accessibleNavigation: true,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
