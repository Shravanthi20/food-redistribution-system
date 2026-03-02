enum DeliveryStatus {
  Listed,
  Accepted,
  Assigned,
  PickedUp,
  Delivered,
}

class StatusTransitionValidator {
  static const Map<DeliveryStatus, List<DeliveryStatus>> _allowed = {
    DeliveryStatus.Listed: [DeliveryStatus.Accepted],
    DeliveryStatus.Accepted: [DeliveryStatus.Assigned],
    DeliveryStatus.Assigned: [DeliveryStatus.PickedUp],
    DeliveryStatus.PickedUp: [DeliveryStatus.Delivered],
    DeliveryStatus.Delivered: [],
  };

  static bool isValidTransition(DeliveryStatus from, DeliveryStatus to) {
    if (from == to) return true; // idempotent
    final allowed = _allowed[from] ?? [];
    return allowed.contains(to);
  }
}
