// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, prefer_const_constructors
import 'dart:convert';
import 'dart:io';

import 'locale_keys.dart';

/// Validates translation completeness across all ARB files.
///
/// Satisfies requirements:
/// - "Detect missing translation keys"
/// - "Validate translation completeness before deployment"
/// - "Implement fallback language logic if translation is missing"
/// - "Maintain consistent translations for safety-critical terminology"
///
/// Run from the project root:
///   dart run lib/utils/translation_validator.dart
void main() async {
  final validator = TranslationValidator(
    arbDir: 'lib/l10n',
    templateLocale: LocaleKeys.fallbackLocaleCode,
    supportedLocales: LocaleKeys.supportedLocaleCodes,
  );

  final report = await validator.validate();
  report.printReport();

  if (!report.isValid) {
    exit(1); // Non-zero exit code for CI enforcement
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Checks all ARB files against the template and reports issues.
class TranslationValidator {
  final String arbDir;
  final String templateLocale;
  final List<String> supportedLocales;

  const TranslationValidator({
    required this.arbDir,
    required this.templateLocale,
    required this.supportedLocales,
  });

  Future<ValidationReport> validate() async {
    final templateFile = File('$arbDir/app_$templateLocale.arb');
    if (!templateFile.existsSync()) {
      return ValidationReport.fatal(
          'Template ARB file not found: ${templateFile.path}');
    }

    final Map<String, dynamic> template =
        jsonDecode(templateFile.readAsStringSync()) as Map<String, dynamic>;

    // Collect translatable keys (skip metadata keys that start with @)
    final templateKeys = template.keys
        .where((k) => !k.startsWith('@') && k != '@@locale')
        .toSet();

    final issues = <ValidationIssue>[];
    final perLocale = <String, LocaleResult>{};

    // Safety-critical keys that must be present and non-empty in every locale
    const safetyCriticalKeys = {
      LocaleKeys.foodSafetyLevel,
      LocaleKeys.safetyHigh,
      LocaleKeys.safetyMedium,
      LocaleKeys.safetyLow,
      LocaleKeys.safetyCritical,
      LocaleKeys.expiryWarning,
      LocaleKeys.foodExpired,
      LocaleKeys.allergenWarning,
      LocaleKeys.refrigerationRequired,
      LocaleKeys.foodSafetyWarning,
      LocaleKeys.doNotConsume,
      LocaleKeys.checkBeforeEating,
      LocaleKeys.temperatureBreached,
      LocaleKeys.crossContaminationRisk,
    };

    for (final locale in supportedLocales) {
      if (locale == templateLocale) continue;

      final arbFile = File('$arbDir/app_$locale.arb');
      if (!arbFile.existsSync()) {
        issues.add(ValidationIssue(
          locale: locale,
          key: '',
          type: IssueType.missingFile,
          message: 'ARB file not found: ${arbFile.path}',
        ));
        perLocale[locale] = const LocaleResult(
            missingKeys: [], extraKeys: [], safetyCriticalIssues: []);
        continue;
      }

      final Map<String, dynamic> translations =
          jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>;

      final localeKeys = translations.keys
          .where((k) => !k.startsWith('@') && k != '@@locale')
          .toSet();

      // Missing keys — will fall back to template locale at runtime
      final missing = templateKeys.difference(localeKeys).toList()..sort();

      // Extra keys — present in locale but not in template (may be orphaned)
      final extra = localeKeys.difference(templateKeys).toList()..sort();

      // Safety-critical completeness check
      final criticalIssues = <String>[];
      for (final criticalKey in safetyCriticalKeys) {
        final value = translations[criticalKey];
        if (value == null || (value is String && value.trim().isEmpty)) {
          criticalIssues.add(criticalKey);
          issues.add(ValidationIssue(
            locale: locale,
            key: criticalKey,
            type: IssueType.missingSafetyCritical,
            message:
                'SAFETY-CRITICAL key "$criticalKey" is missing or empty in locale "$locale".',
          ));
        }
      }

      for (final key in missing) {
        issues.add(ValidationIssue(
          locale: locale,
          key: key,
          type: IssueType.missingKey,
          message:
              'Key "$key" is missing in "$locale". Fallback: "$templateLocale" will be used.',
        ));
      }

      for (final key in extra) {
        issues.add(ValidationIssue(
          locale: locale,
          key: key,
          type: IssueType.extraKey,
          message:
              'Key "$key" exists in "$locale" but not in template "$templateLocale". Consider removing.',
        ));
      }

      perLocale[locale] = LocaleResult(
        missingKeys: missing,
        extraKeys: extra,
        safetyCriticalIssues: criticalIssues,
      );
    }

    return ValidationReport(
      templateLocale: templateLocale,
      templateKeyCount: templateKeys.length,
      issues: issues,
      perLocale: perLocale,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum IssueType { missingFile, missingKey, extraKey, missingSafetyCritical }

class ValidationIssue {
  final String locale;
  final String key;
  final IssueType type;
  final String message;

  const ValidationIssue({
    required this.locale,
    required this.key,
    required this.type,
    required this.message,
  });
}

class LocaleResult {
  final List<String> missingKeys;
  final List<String> extraKeys;
  final List<String> safetyCriticalIssues;

  const LocaleResult({
    required this.missingKeys,
    required this.extraKeys,
    required this.safetyCriticalIssues,
  });
}

class ValidationReport {
  final String? fatalMessage;
  final String templateLocale;
  final int templateKeyCount;
  final List<ValidationIssue> issues;
  final Map<String, LocaleResult> perLocale;

  const ValidationReport({
    this.fatalMessage,
    required this.templateLocale,
    required this.templateKeyCount,
    required this.issues,
    required this.perLocale,
  });

  factory ValidationReport.fatal(String message) => ValidationReport(
        fatalMessage: message,
        templateLocale: '',
        templateKeyCount: 0,
        issues: [],
        perLocale: {},
      );

  /// True only when there are no missing files, no safety-critical issues,
  /// and no missing translation keys.
  bool get isValid =>
      fatalMessage == null &&
      issues.none((i) =>
          i.type == IssueType.missingFile ||
          i.type == IssueType.missingSafetyCritical ||
          i.type == IssueType.missingKey);

  void printReport() {
    final sep = '─' * 70;
    print('\n$sep');
    print('  Translation Validation Report');
    print(sep);

    if (fatalMessage != null) {
      print('  ✗ FATAL: $fatalMessage');
      print(sep);
      return;
    }

    print('  Template : $templateLocale  ($templateKeyCount keys)');
    print('  Locales  : ${perLocale.keys.join(', ')}');
    print(sep);

    if (issues.isEmpty) {
      print('  ✓ All translations are complete and valid.');
      print(sep);
      return;
    }

    // Group by severity
    final critical =
        issues.where((i) => i.type == IssueType.missingSafetyCritical).toList();
    final missing =
        issues.where((i) => i.type == IssueType.missingKey).toList();
    final extra = issues.where((i) => i.type == IssueType.extraKey).toList();
    final files = issues.where((i) => i.type == IssueType.missingFile).toList();

    if (files.isNotEmpty) {
      print('\n  [MISSING FILES]');
      for (final i in files) print('    ✗ ${i.message}');
    }

    if (critical.isNotEmpty) {
      print('\n  [SAFETY-CRITICAL MISSING — DEPLOYMENT BLOCKED]');
      for (final i in critical) print('    ✗ [${i.locale}] ${i.message}');
    }

    if (missing.isNotEmpty) {
      print('\n  [MISSING KEYS — fallback will be used at runtime]');
      for (final i in missing) print('    ⚠ [${i.locale}] ${i.message}');
    }

    if (extra.isNotEmpty) {
      print('\n  [ORPHANED KEYS — exist in locale but not in template]');
      for (final i in extra) print('    ℹ [${i.locale}] ${i.message}');
    }

    print('\n  Summary: ${critical.length} safety-critical, '
        '${missing.length} missing, '
        '${extra.length} extra, '
        '${files.length} missing files.');
    print(sep);
  }
}

extension _IterableNone<T> on Iterable<T> {
  bool none(bool Function(T) test) => !any(test);
}
