import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_localizations_ext.dart';
import '../utils/app_theme.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accessibilitySettings)),
      body: Consumer3<AccessibilityProvider, ThemeProvider, LocaleProvider>(
        builder: (context, accessibilityProvider, themeProvider, localeProvider,
            child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── Language ───────────────────────────────────────────────
              Text(
                context.l10n.language,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Column(
                children: LocaleProvider.supportedLocaleOptions
                    .map(
                      (opt) => RadioListTile<Locale>(
                        title: Text(opt.displayName),
                        value: opt.locale,
                        groupValue: localeProvider.locale,
                        onChanged: (Locale? value) {
                          if (value != null) localeProvider.setLocale(value);
                        },
                        activeColor: AppTheme.accentTeal,
                      ),
                    )
                    .toList(),
              ),
              const Divider(),
              // ── Display Options ────────────────────────────────────────
              Text(
                context.l10n.displayOptions,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Replaced SwitchListTile with RadioListTiles for High Contrast Mode
              RadioListTile<bool>(
                title: Text(context.l10n.highContrastMode,
                    style: const TextStyle(color: AppTheme.textPrimary)),
                value: true,
                groupValue: accessibilityProvider.highContrastMode,
                onChanged: (bool? value) {
                  if (value != null) {
                    accessibilityProvider.toggleHighContrastMode(value);
                  }
                },
              ),
              const Divider(color: AppTheme.iosGray4),
              RadioListTile<bool>(
                title: Text(context.l10n.standardContrast,
                    style: const TextStyle(color: AppTheme.textPrimary)),
                value: false,
                groupValue: accessibilityProvider.highContrastMode,
                onChanged: (bool? value) {
                  if (value != null) {
                    accessibilityProvider.toggleHighContrastMode(value);
                  }
                },
              ),
              // Theme adaptation for high contrast is handled in main.dart
              const Divider(),
              Text(context.l10n.textSize,
                  style: Theme.of(context).textTheme.titleMedium),
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
                context.l10n.adjustTextSize,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(),
              Semantics(
                  label: context.l10n.simplifiedUiMode,
                  toggled: accessibilityProvider.simplifiedMode,
                  child: SwitchListTile(
                    title: Text(context.l10n.simplifiedUiMode),
                    subtitle: Text(
                      context.l10n.reduceClutter,
                    ),
                    value: accessibilityProvider.simplifiedMode,
                    onChanged: (bool value) {
                      accessibilityProvider.toggleSimplifiedMode(value);
                    },
                  )),
              const Divider(),
              Semantics(
                  label: context.l10n.darkMode,
                  toggled: themeProvider.isDarkMode,
                  child: SwitchListTile(
                    title: Text(context.l10n.darkMode),
                    subtitle: Text(context.l10n.enableDarkTheme),
                    value: themeProvider.isDarkMode,
                    onChanged: (bool value) {
                      themeProvider.toggleTheme();
                    },
                  )),
            ],
          );
        },
      ),
    );
  }
}
