import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/locale_keys.dart';

/// Manages the active [Locale] at runtime and persists the user's preference
/// via [SharedPreferences].
///
/// Responsibilities:
/// - Runtime language switching (satisfies: "allow users to switch language at runtime")
/// - Persist language preference (satisfies: "persist user language preference")
/// - Enforce supported locales (satisfies: "prevent mixed-language UI rendering" /
///   "allow adding new languages without code restructuring")
/// - Fallback to English for unsupported locales (satisfies: "fallback language logic")
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'preferred_locale';

  /// The currently active locale. Defaults to device locale if supported,
  /// otherwise falls back to English.
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// All locales officially supported by the app.
  /// Add a new [Locale] here (and a corresponding ARB file) to support a new
  /// language — no other code changes are required.
  static const List<Locale> supportedLocales = [
    Locale('en'), // English — fallback
    Locale('hi'), // हिन्दी
    Locale('ta'), // தமிழ்
  ];

  /// The fallback locale used when a translation key is missing.
  static const Locale fallbackLocale = Locale('en');

  LocaleProvider() {
    _loadPersistedLocale();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Loads the locale persisted from a previous session, or adopts the device
  /// locale if it is supported. Falls back to English.
  Future<void> _loadPersistedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    if (saved != null && _isSupportedCode(saved)) {
      _locale = Locale(saved);
    } else {
      // Default to English; callers may call setLocaleFromDevice() to attempt
      // a device-locale match.
      _locale = fallbackLocale;
    }
    notifyListeners();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Changes the active locale to [newLocale] and persists the choice.
  ///
  /// Throws an [ArgumentError] if [newLocale] is not in [supportedLocales],
  /// preventing mixed-language UI rendering.
  Future<void> setLocale(Locale newLocale) async {
    if (!_isSupportedLocale(newLocale)) {
      throw ArgumentError(
        'Locale "${newLocale.languageCode}" is not supported. '
        'Supported locales: ${supportedLocales.map((l) => l.languageCode).join(', ')}. '
        'Add a new ARB file and register the locale in LocaleProvider.supportedLocales '
        'to add support.',
      );
    }

    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
  }

  /// Attempts to adopt the device locale. Falls back to English if not supported.
  Future<void> setLocaleFromDevice(Locale deviceLocale) async {
    final match = _bestSupportedLocale(deviceLocale);
    await setLocale(match);
  }

  /// Clears the persisted preference and resets to the fallback locale.
  Future<void> resetLocale() async {
    _locale = fallbackLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isSupportedCode(String code) =>
      supportedLocales.any((l) => l.languageCode == code);

  bool _isSupportedLocale(Locale locale) =>
      _isSupportedCode(locale.languageCode);

  /// Returns the best match from [supportedLocales] for [requested], or the
  /// fallback locale if no match is found.
  Locale _bestSupportedLocale(Locale requested) {
    // Exact match (language + country)
    for (final supported in supportedLocales) {
      if (supported.languageCode == requested.languageCode &&
          supported.countryCode == requested.countryCode) {
        return supported;
      }
    }
    // Language-only match
    for (final supported in supportedLocales) {
      if (supported.languageCode == requested.languageCode) {
        return supported;
      }
    }
    return fallbackLocale;
  }

  /// Returns the display name for a locale, sourced from [LocaleKeys] so that
  /// the label itself is always rendered in the target language.
  static String localeDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  /// Convenience: returns a display-name list sorted like [supportedLocales].
  static List<({Locale locale, String displayName})>
      get supportedLocaleOptions => supportedLocales
          .map((l) => (locale: l, displayName: localeDisplayName(l)))
          .toList();

  // ── Diagnostic (development helper) ───────────────────────────────────────

  /// Returns the locale code stored in preferences without changing state.
  /// Useful for debugging or automated tests.
  static Future<String?> readPersistedLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }
}
