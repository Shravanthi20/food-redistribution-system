enum DeliveryStatus { listed, accepted, assigned, pickedUp, delivered }

class StatusTransitionValidator {
  static const Map<DeliveryStatus, List<DeliveryStatus>> _allowed = {
    DeliveryStatus.listed: [DeliveryStatus.accepted],
    DeliveryStatus.accepted: [DeliveryStatus.assigned],
    DeliveryStatus.assigned: [DeliveryStatus.pickedUp],
    DeliveryStatus.pickedUp: [DeliveryStatus.delivered],
    DeliveryStatus.delivered: [],
  };

  static bool isValidTransition(DeliveryStatus from, DeliveryStatus to) {
    if (from == to) return true; // idempotent
    final allowed = _allowed[from] ?? [];
    return allowed.contains(to);
  }
}
