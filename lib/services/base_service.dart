import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/result_utils.dart';
import 'audit_service.dart';

/// Base class for all services providing unified error handling and logging
abstract class BaseService {
  final AuditService _auditService = AuditService();

  /// Executes a database operation with safety and result wrapping
  @protected
  Future<Result<T>> safeExecute<T>(
    Future<T> Function() action, {
    String? auditAction,
    String? auditUserId,
    Map<String, dynamic>? auditData,
  }) async {
    try {
      final data = await action();
      
      if (auditAction != null) {
        await _auditService.logEvent(
          action: auditAction,
          userId: auditUserId ?? 'system',
          additionalData: auditData,
        );
      }
      
      return Result.success(data);
    } catch (e, stack) {
      debugPrint('Service Error: $e');
      debugPrint('Stacktrace: $stack');
      
      if (auditAction != null) {
        await _auditService.logEvent(
          action: '${auditAction}_failed',
          userId: auditUserId ?? 'system',
          additionalData: {
            'error': e.toString(),
            ...?auditData,
          },
        );
      }
      
      return Result.error(AppException.fromFirebase(e));
    }
  }

  /// Helper to convert QuerySnapshot to List of models
  @protected
  List<T> mapSnapshot<T>(
    QuerySnapshot snapshot,
    T Function(DocumentSnapshot) mapper,
  ) {
    return snapshot.docs.map(mapper).toList();
  }
}
