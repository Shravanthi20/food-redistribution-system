import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  double _textScaleFactor = 1.0;
  bool _highContrastMode = false;
  bool _simplifiedMode = false;

  double get textScaleFactor => _textScaleFactor;
  bool get highContrastMode => _highContrastMode;
  bool get simplifiedMode => _simplifiedMode;

  AccessibilityProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _highContrastMode = prefs.getBool('highContrastMode') ?? false;
    _simplifiedMode = prefs.getBool('simplifiedMode') ?? false;
    notifyListeners();
  }

  Future<void> updateTextScaleFactor(double value) async {
    _textScaleFactor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', value);
    notifyListeners();
  }

  Future<void> toggleHighContrastMode(bool value) async {
    _highContrastMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrastMode', value);
    notifyListeners();
  }

  Future<void> toggleSimplifiedMode(bool value) async {
    _simplifiedMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('simplifiedMode', value);
    notifyListeners();
  }
}
