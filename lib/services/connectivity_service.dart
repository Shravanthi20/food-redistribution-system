import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Error checking connectivity: $e');
      _connectionStatusController.add(false); // Assume offline on error
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If list contains anything other than none, we have connectivity
    bool isOnline = results.any((r) => r != ConnectivityResult.none);
    _connectionStatusController.add(isOnline);
  }

  // Dispose method if needed
  void dispose() {
    _connectionStatusController.close();
  }
}
