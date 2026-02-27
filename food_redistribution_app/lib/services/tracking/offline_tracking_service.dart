import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tracking/location_tracking_model.dart';

// Save and sync location data when internet is down
class OfflineTrackingService {
  static const String _offlineUpdatesKey = 'offline_tracking_updates';
  static const String _lastSyncKey = 'last_tracking_sync';

  SharedPreferences? _prefs;
  bool _isInitializing = false;

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;

    if (!_isInitializing) {
      _isInitializing = true;
      _prefs = await SharedPreferences.getInstance();
      _isInitializing = false;
    } else {
      while (_prefs == null) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    return _prefs!;
  }

  // Store location to phone when no internet
  Future<bool> saveOfflineLocationUpdate(LocationUpdate location) async {
    try {
      final p = await prefs;
      final existingJson = p.getString(_offlineUpdatesKey);
      final List<dynamic> updates =
          existingJson != null ? jsonDecode(existingJson) : [];

      updates.add({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'volunteerId': location.volunteerId,
        'taskId': location.taskId,
        'timestamp': location.timestamp.toIso8601String(),
        'status': location.status.name,
      });

      await p.setString(_offlineUpdatesKey, jsonEncode(updates));
      return true;
    } catch (e) {
      debugPrint('Error saving offline location: $e');
      return false;
    }
  }

  // Store status changes offline
  Future<bool> saveOfflineStatusUpdate(String taskId, String newStatus) async {
    try {
      final p = await prefs;
      final key = '${_offlineUpdatesKey}_status';
      final existingJson = p.getString(key);
      final List<dynamic> updates =
          existingJson != null ? jsonDecode(existingJson) : [];

      updates.add({
        'taskId': taskId,
        'status': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await p.setString(key, jsonEncode(updates));
      return true;
    } catch (e) {
      debugPrint('Error saving offline status: $e');
      return false;
    }
  }

  // Get all pending updates
  Future<List<Map<String, dynamic>>> getOfflineUpdates() async {
    try {
      final updates = <Map<String, dynamic>>[];

      final p = await prefs;
      // Get location updates
      final locationJson = p.getString(_offlineUpdatesKey);
      if (locationJson != null) {
        final List<dynamic> decoded = jsonDecode(locationJson);
        updates.addAll(decoded.cast<Map<String, dynamic>>());
      }

      // Get status updates
      final statusJson = p.getString('${_offlineUpdatesKey}_status');
      if (statusJson != null) {
        final List<dynamic> decoded = jsonDecode(statusJson);
        updates.addAll(decoded.cast<Map<String, dynamic>>());
      }

      return updates;
    } catch (e) {
      debugPrint('Error getting offline updates: $e');
      return [];
    }
  }

  // Mark updates as synced
  Future<bool> markUpdatesSynced() async {
    try {
      final p = await prefs;
      await p.remove(_offlineUpdatesKey);
      await p.remove('${_offlineUpdatesKey}_status');
      await p.setString(_lastSyncKey, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('Error marking updates as synced: $e');
      return false;
    }
  }

  // Get count of pending updates
  Future<int> getPendingUpdateCount() async {
    try {
      int count = 0;
      final p = await prefs;

      final locationJson = p.getString(_offlineUpdatesKey);
      if (locationJson != null) {
        count += (jsonDecode(locationJson) as List).length;
      }

      final statusJson = p.getString('${_offlineUpdatesKey}_status');
      if (statusJson != null) {
        count += (jsonDecode(statusJson) as List).length;
      }

      return count;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }

  // Clear synced updates
  Future<bool> clearSyncedUpdates() async {
    try {
      final p = await prefs;
      await p.remove(_offlineUpdatesKey);
      await p.remove('${_offlineUpdatesKey}_status');
      return true;
    } catch (e) {
      debugPrint('Error clearing synced updates: $e');
      return false;
    }
  }
}
