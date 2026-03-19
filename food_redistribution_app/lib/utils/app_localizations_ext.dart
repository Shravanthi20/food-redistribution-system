import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';

/// Extension on [BuildContext] for ergonomic access to [AppLocalizations].
///
/// Usage (replaces the verbose `AppLocalizations.of(context)!.save`):
///   context.l10n.save
///   context.l10n.expiryWarning(hours: 2)
extension AppLocalizationsX on BuildContext {
  /// Returns the [AppLocalizations] for the current locale.
  ///
  /// Falls back transparently to the English strings when a key is missing in
  /// the active locale (handled by the Flutter gen_l10n infrastructure).
  AppLocalizations get l10n => AppLocalizations.of(this);
}
