import 'dart:math' show cos, sqrt, asin;

class LocationUtils {
  /// Calculates the distance between two geographical points in kilometers.
  /// Uses the Haversine formula.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Checks if a point is within a certain radius (in km) from a center.
  static bool isWithinRadius(double centerLat, double centerLon, double pointLat, double pointLon, double radiusKm) {
    return calculateDistance(centerLat, centerLon, pointLat, pointLon) <= radiusKm;
  }
}
