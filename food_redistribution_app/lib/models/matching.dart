import 'enums.dart';
import 'ngo_profile.dart';

class MatchingAlgorithm {
  final String id;
  final String name;
  final Map<MatchingCriteria, double> weights;
  final double maxDistance; // in kilometers
  
  const MatchingAlgorithm({
    required this.id,
    required this.name,
    required this.weights,
    required this.maxDistance,
  });
  
  // Validate that weights sum to 1.0
  bool get isValid {
    final sum = weights.values.fold(0.0, (sum, weight) => sum + weight);
    return (sum - 1.0).abs() < 0.001; // Allow small floating point errors
  }
  
  static const urgent = MatchingAlgorithm(
    id: 'urgent',
    name: 'Urgent Food Rescue',
    weights: {
      MatchingCriteria.distance: 0.4,
      MatchingCriteria.urgency: 0.35,
      MatchingCriteria.capacity: 0.15,
      MatchingCriteria.foodType: 0.05,
      MatchingCriteria.availability: 0.05,
    },
    maxDistance: 25.0,
  );
  
  static const optimal = MatchingAlgorithm(
    id: 'optimal',
    name: 'Optimal Distribution',
    weights: {
      MatchingCriteria.distance: 0.25,
      MatchingCriteria.capacity: 0.25,
      MatchingCriteria.availability: 0.2,
      MatchingCriteria.foodType: 0.15,
      MatchingCriteria.urgency: 0.15,
    },
    maxDistance: 50.0,
  );
  
  static const capacity = MatchingAlgorithm(
    id: 'capacity',
    name: 'Maximum Capacity',
    weights: {
      MatchingCriteria.capacity: 0.4,
      MatchingCriteria.distance: 0.3,
      MatchingCriteria.foodType: 0.15,
      MatchingCriteria.availability: 0.1,
      MatchingCriteria.urgency: 0.05,
    },
    maxDistance: 75.0,
  );
  
  static List<MatchingAlgorithm> get all => [urgent, optimal, capacity];
}

class MatchingResult {
  final String ngoId;
  final String donationId;
  final double score;
  final double distance;
  final Map<MatchingCriteria, double> criteriaScores;
  final NGOProfile? ngo;
  final String reasoning;
  final DateTime timestamp;
  
  MatchingResult({
    required this.ngoId,
    required this.donationId,
    required this.score,
    required this.distance,
    required this.criteriaScores,
    this.ngo,
    required this.reasoning,
    required this.timestamp,
  });
  
  // Validate score is between 0 and 1
  bool get isValidScore => score >= 0.0 && score <= 1.0;
  
  Map<String, dynamic> toMap() {
    return {
      'ngoId': ngoId,
      'donationId': donationId,
      'score': score,
      'distance': distance,
      'criteriaScores': criteriaScores.map((k, v) => MapEntry(k.name, v)),
      'reasoning': reasoning,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory MatchingResult.fromMap(Map<String, dynamic> map) {
    return MatchingResult(
      ngoId: map['ngoId'] ?? '',
      donationId: map['donationId'] ?? '',
      score: (map['score'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      criteriaScores: (map['criteriaScores'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(
                MatchingCriteria.values.firstWhere(
                  (e) => e.name == k,
                  orElse: () => MatchingCriteria.distance,
                ),
                (v ?? 0.0).toDouble(),
              )),
      reasoning: map['reasoning'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
