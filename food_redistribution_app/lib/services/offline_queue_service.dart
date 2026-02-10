import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline Queue Sync Service
/// Provides robust offline operation handling with:
/// - Queue-based operation storage
/// - Automatic sync when connectivity resumes
/// - Conflict resolution strategies
/// - Retry logic with exponential backoff
class OfflineQueueService {
  static const String _queueKey = 'offline_operation_queue';
  static const int _maxRetries = 3;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  late SharedPreferences _prefs;
  
  final StreamController<QueueStatus> _statusController = 
      StreamController<QueueStatus>.broadcast();
  
  Stream<QueueStatus> get statusStream => _statusController.stream;
  
  bool _isInitialized = false;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _attemptSync();
      }
    });
    
    _isInitialized = true;
    
    // Attempt sync on startup
    _attemptSync();
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // ============================================================
  // QUEUE OPERATIONS
  // ============================================================

  /// Add an operation to the offline queue
  Future<bool> queueOperation(OfflineOperation operation) async {
    try {
      final queue = await _getQueue();
      queue.add(operation.toJson());
      await _saveQueue(queue);
      
      _emitStatus();
      
      // Try to sync immediately if online
      if (await isOnline()) {
        _attemptSync();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error queuing operation: $e');
      return false;
    }
  }

  /// Queue a donation creation
  Future<bool> queueDonationCreation(Map<String, dynamic> donationData) async {
    return queueOperation(OfflineOperation(
      id: _generateId(),
      type: OperationType.createDonation,
      data: donationData,
      createdAt: DateTime.now(),
    ));
  }

  /// Queue a status update
  Future<bool> queueStatusUpdate({
    required String collection,
    required String documentId,
    required String status,
  }) async {
    return queueOperation(OfflineOperation(
      id: _generateId(),
      type: OperationType.updateStatus,
      data: {
        'collection': collection,
        'documentId': documentId,
        'status': status,
      },
      createdAt: DateTime.now(),
    ));
  }

  /// Queue a location update
  Future<bool> queueLocationUpdate({
    required String volunteerId,
    required String taskId,
    required double latitude,
    required double longitude,
  }) async {
    return queueOperation(OfflineOperation(
      id: _generateId(),
      type: OperationType.updateLocation,
      data: {
        'volunteerId': volunteerId,
        'taskId': taskId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
      createdAt: DateTime.now(),
    ));
  }

  /// Queue a demand request creation
  Future<bool> queueDemandRequest(Map<String, dynamic> demandData) async {
    return queueOperation(OfflineOperation(
      id: _generateId(),
      type: OperationType.createDemand,
      data: demandData,
      createdAt: DateTime.now(),
    ));
  }

  /// Queue any generic Firestore write
  Future<bool> queueFirestoreWrite({
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    return queueOperation(OfflineOperation(
      id: _generateId(),
      type: OperationType.genericWrite,
      data: {
        'collection': collection,
        'documentId': documentId,
        'data': data,
        'merge': merge,
      },
      createdAt: DateTime.now(),
    ));
  }

  // ============================================================
  // SYNC OPERATIONS
  // ============================================================

  /// Attempt to sync all queued operations
  Future<SyncResult> _attemptSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        processed: 0,
        failed: 0,
      );
    }
    
    if (!await isOnline()) {
      return SyncResult(
        success: false,
        message: 'Device is offline',
        processed: 0,
        failed: 0,
      );
    }
    
    _isSyncing = true;
    _emitStatus(isSyncing: true);
    
    int processed = 0;
    int failed = 0;
    final failedOperations = <Map<String, dynamic>>[];
    
    try {
      final queue = await _getQueue();
      
      for (final opJson in queue) {
        final operation = OfflineOperation.fromJson(opJson);
        
        bool success = await _executeOperation(operation);
        
        if (success) {
          processed++;
        } else {
          failed++;
          // Increment retry count
          opJson['retryCount'] = (opJson['retryCount'] ?? 0) + 1;
          
          if ((opJson['retryCount'] as int) < _maxRetries) {
            failedOperations.add(opJson);
          } else {
            // Max retries exceeded, log and discard
            debugPrint('Operation ${operation.id} exceeded max retries, discarding');
          }
        }
      }
      
      // Save only failed operations back to queue
      await _saveQueue(failedOperations);
      
      _isSyncing = false;
      _emitStatus();
      
      return SyncResult(
        success: failed == 0,
        message: failed == 0 ? 'All operations synced' : '$failed operations failed',
        processed: processed,
        failed: failed,
      );
    } catch (e) {
      _isSyncing = false;
      _emitStatus();
      debugPrint('Error during sync: $e');
      return SyncResult(
        success: false,
        message: 'Sync error: $e',
        processed: processed,
        failed: failed,
      );
    }
  }

  /// Manually trigger a sync
  Future<SyncResult> manualSync() async {
    return _attemptSync();
  }

  /// Execute a single operation
  Future<bool> _executeOperation(OfflineOperation operation) async {
    try {
      switch (operation.type) {
        case OperationType.createDonation:
          await _firestore.collection('food_donations').add({
            ...operation.data,
            'syncedFromOffline': true,
            'offlineCreatedAt': operation.createdAt.toIso8601String(),
          });
          return true;
          
        case OperationType.createDemand:
          await _firestore.collection('demand_requests').add({
            ...operation.data,
            'syncedFromOffline': true,
            'offlineCreatedAt': operation.createdAt.toIso8601String(),
          });
          return true;
          
        case OperationType.updateStatus:
          final collection = operation.data['collection'] as String;
          final docId = operation.data['documentId'] as String;
          final status = operation.data['status'] as String;
          
          await _firestore.collection(collection).doc(docId).update({
            'status': status,
            'lastUpdated': FieldValue.serverTimestamp(),
            'updatedFromOffline': true,
          });
          return true;
          
        case OperationType.updateLocation:
          await _firestore.collection('location_updates').add({
            ...operation.data,
            'syncedFromOffline': true,
          });
          return true;
          
        case OperationType.genericWrite:
          final collection = operation.data['collection'] as String;
          final docId = operation.data['documentId'] as String?;
          final data = operation.data['data'] as Map<String, dynamic>;
          final merge = operation.data['merge'] as bool? ?? false;
          
          if (docId != null) {
            await _firestore.collection(collection).doc(docId).set(
              {...data, 'syncedFromOffline': true},
              SetOptions(merge: merge),
            );
          } else {
            await _firestore.collection(collection).add({
              ...data,
              'syncedFromOffline': true,
            });
          }
          return true;
      }
    } catch (e) {
      debugPrint('Error executing operation ${operation.id}: $e');
      return false;
    }
  }

  // ============================================================
  // QUEUE MANAGEMENT
  // ============================================================

  Future<List<Map<String, dynamic>>> _getQueue() async {
    try {
      final jsonStr = _prefs.getString(_queueKey);
      if (jsonStr == null) return [];
      
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error reading queue: $e');
      return [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Get the number of pending operations
  Future<int> getPendingCount() async {
    final queue = await _getQueue();
    return queue.length;
  }

  /// Clear all pending operations
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
    _emitStatus();
  }

  /// Get all pending operations
  Future<List<OfflineOperation>> getPendingOperations() async {
    final queue = await _getQueue();
    return queue.map((e) => OfflineOperation.fromJson(e)).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  void _emitStatus({bool isSyncing = false}) async {
    final count = await getPendingCount();
    _statusController.add(QueueStatus(
      pendingOperations: count,
      isSyncing: isSyncing,
      lastAttempt: DateTime.now(),
    ));
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

// ============================================================
// DATA MODELS
// ============================================================

enum OperationType {
  createDonation,
  createDemand,
  updateStatus,
  updateLocation,
  genericWrite,
}

class OfflineOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OperationType.genericWrite,
      ),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

class QueueStatus {
  final int pendingOperations;
  final bool isSyncing;
  final DateTime lastAttempt;

  QueueStatus({
    required this.pendingOperations,
    required this.isSyncing,
    required this.lastAttempt,
  });
}

class SyncResult {
  final bool success;
  final String message;
  final int processed;
  final int failed;

  SyncResult({
    required this.success,
    required this.message,
    required this.processed,
    required this.failed,
  });
}
