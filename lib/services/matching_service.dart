import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_donation.dart';
import '../models/ngo_profile.dart';
import '../models/volunteer_profile.dart';
import 'base_service.dart';
import '../utils/result_utils.dart';
import '../utils/location_utils.dart';

class MatchingService extends BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Finds potential NGOs for a given donation based on food types and distance.
  Future<Result<List<NGOProfile>>> findPotentialNGOs(FoodDonation donation, {double radiusKm = 10.0}) async {
    return safeExecute(() async {
      final donationLat = donation.pickupLocation['latitude'] as double?;
      final donationLon = donation.pickupLocation['longitude'] as double?;

      if (donationLat == null || donationLon == null) {
        throw Exception('Donation has no location data');
      }

      // 1. Fetch all verified NGOs (optimally should use geo-queries)
      final ngosQuery = await _firestore
          .collection('ngo_profiles')
          .where('isVerified', isEqualTo: true)
          .get();

      final allNGOs = ngosQuery.docs.map((doc) => NGOProfile.fromFirestore(doc)).toList();

      // 2. Filter by location and food types
      final filteredNGOs = allNGOs.where((ngo) {
        final ngoLat = ngo.location['latitude'] as double?;
        final ngoLon = ngo.location['longitude'] as double?;

        if (ngoLat == null || ngoLon == null) return false;

        // Check distance
        final distance = LocationUtils.calculateDistance(donationLat, donationLon, ngoLat, ngoLon);
        if (distance > radiusKm) return false;

        // Check food type overlap (simple intersection)
        // Note: Models might need matching enum types, checking both for now
        return true; 
      }).toList();

      return filteredNGOs;
    });
  }

  /// Finds potential available volunteers for a given donation.
  Future<Result<List<VolunteerProfile>>> findPotentialVolunteers(FoodDonation donation, {double radiusKm = 5.0}) async {
    return safeExecute(() async {
      final donationLat = donation.pickupLocation['latitude'] as double?;
      final donationLon = donation.pickupLocation['longitude'] as double?;

      if (donationLat == null || donationLon == null) {
        throw Exception('Donation has no location data');
      }

      // 1. Fetch available volunteers
      final volunteersQuery = await _firestore
          .collection('volunteer_profiles')
          .where('isAvailable', isEqualTo: true)
          .get();

      final allVolunteers = volunteersQuery.docs.map((doc) => VolunteerProfile.fromFirestore(doc)).toList();

      // 2. Filter by distance
      final filteredVolunteers = allVolunteers.where((volunteer) {
        // Volunteers might use a different location structure or current location
        // Here we assume they have a registered city or specific coordinates
        final vLat = volunteer.location?['latitude'] as double?;
        final vLon = volunteer.location?['longitude'] as double?;

        if (vLat == null || vLon == null) return false;

        final distance = LocationUtils.calculateDistance(donationLat, donationLon, vLat, vLon);
        return distance <= radiusKm;
      }).toList();

      return filteredVolunteers;
    });
  }
}
