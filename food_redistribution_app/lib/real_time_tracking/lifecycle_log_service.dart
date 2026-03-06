class LifecycleLogEntry {
  final String deliveryId;
  final String from;
  final String to;
  final DateTime timestamp;
  final String message;

  LifecycleLogEntry({
    required this.deliveryId,
    required this.from,
    required this.to,
    required this.timestamp,
    required this.message,
  });
}

class LifecycleLogService {
  final List<LifecycleLogEntry> _entries = [];

  void add(String deliveryId, String from, String to, String message) {
    _entries.add(
      LifecycleLogEntry(
        deliveryId: deliveryId,
        from: from,
        to: to,
        timestamp: DateTime.now(),
        message: message,
      ),
    );
  }

  List<LifecycleLogEntry> getEntriesFor(String deliveryId) {
    return _entries.where((e) => e.deliveryId == deliveryId).toList();
  }

  List<LifecycleLogEntry> get allEntries => List.unmodifiable(_entries);
}
