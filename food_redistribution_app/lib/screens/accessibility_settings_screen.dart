import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/theme_provider.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Settings')),
      body: Consumer2<AccessibilityProvider, ThemeProvider>(
        builder: (context, accessibilityProvider, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Display Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('High Contrast Mode'),
                subtitle: const Text('Enhance text and elements visibility'),
                value: accessibilityProvider.highContrastMode,
                onChanged: (bool value) {
                  accessibilityProvider.toggleHighContrastMode(value);
                  // Theme adaptation for high contrast is handled in main.dart
                },
              ),
              const Divider(),
              Text('Text Size', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: accessibilityProvider.textScaleFactor,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label:
                    '${(accessibilityProvider.textScaleFactor * 100).round()}%',
                onChanged: (double value) {
                  accessibilityProvider.updateTextScaleFactor(value);
                },
              ),
              Text(
                'Adjust the text size for easier reading.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Simplified UI Mode'),
                subtitle: const Text(
                  'Reduce clutter and focus on essential actions',
                ),
                value: accessibilityProvider.simplifiedMode,
                onChanged: (bool value) {
                  accessibilityProvider.toggleSimplifiedMode(value);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
