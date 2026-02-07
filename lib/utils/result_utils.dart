import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized result type for all backend operations
class Result<T> {
  final T? data;
  final AppException? error;

  Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);
  factory Result.error(AppException error) => Result._(error: error);

  bool get isSuccess => error == null;
  bool get isError => error != null;

  void when({
    void Function(T data)? onSuccess,
    void Function(AppException error)? onError,
  }) {
    if (isSuccess && onSuccess != null) onSuccess(data as T);
    if (isError && onError != null) onError(error!);
  }
}

/// Specialized application exceptions for the backend
class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AppException(this.message, {this.code = 'unknown', this.originalError});

  factory AppException.fromFirebase(dynamic e) {
    if (e is FirebaseAuthException) {
      return AppException(e.message ?? 'Authentication failed', code: e.code, originalError: e);
    }
    if (e is FirebaseException) {
      return AppException(e.message ?? 'Database error occurred', code: e.code, originalError: e);
    }
    return AppException(e.toString(), originalError: e);
  }

  @override
  String toString() => 'AppException: [$code] $message';
}
