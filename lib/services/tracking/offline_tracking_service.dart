import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tracking/location_tracking_model.dart';

// Save and sync location data when internet is down
class OfflineTrackingService {
  static const String _offlineUpdatesKey = 'offline_tracking_updates';
  static const String _lastSyncKey = 'last_tracking_sync';

  late SharedPreferences _prefs;

  OfflineTrackingService() {
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Store location to phone when no internet
  Future<bool> saveOfflineLocationUpdate(LocationUpdate location) async {
    try {
      await _prefs.setString(
        _offlineUpdatesKey,
        jsonEncode({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'volunteerId': location.volunteerId,
          'taskId': location.taskId,
          'timestamp': location.timestamp.toIso8601String(),
          'status': location.status,
        }),
      );
      return true;
    } catch (e) {
      debugPrint('Error saving offline location: $e');
      return false;
    }
  }

  // Store status changes offline
  Future<bool> saveOfflineStatusUpdate(String taskId, String newStatus) async {
    try {
      await _prefs.setString(
        '${_offlineUpdatesKey}_status',
        jsonEncode({
          'taskId': taskId,
          'status': newStatus,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
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

      // Get location update
      final locationJson = _prefs.getString(_offlineUpdatesKey);
      if (locationJson != null) {
        updates.add(jsonDecode(locationJson) as Map<String, dynamic>);
      }

      // Get status update
      final statusJson = _prefs.getString('${_offlineUpdatesKey}_status');
      if (statusJson != null) {
        updates.add(jsonDecode(statusJson) as Map<String, dynamic>);
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
      await _prefs.remove(_offlineUpdatesKey);
      await _prefs.remove('${_offlineUpdatesKey}_status');
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
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
      if (_prefs.getString(_offlineUpdatesKey) != null) count++;
      if (_prefs.getString('${_offlineUpdatesKey}_status') != null) count++;
      return count;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }

  // Clear synced updates
  Future<bool> clearSyncedUpdates() async {
    try {
      await _prefs.remove(_offlineUpdatesKey);
      await _prefs.remove('${_offlineUpdatesKey}_status');
      return true;
    } catch (e) {
      debugPrint('Error clearing synced updates: $e');
      return false;
    }
  }
}
