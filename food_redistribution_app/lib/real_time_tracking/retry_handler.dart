import 'dart:async';

class RetryHandler {
  /// Runs [action]. If it throws, retries up to [retries] times with [delay].
  static Future<T> runWithRetry<T>(
    Future<T> Function() action, {
    int retries = 3,
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt > retries) rethrow;
        await Future.delayed(delay);
      }
    }
  }
}
