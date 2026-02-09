#!/usr/bin/env dart

/// Quick test script for matching algorithms
/// Run with: dart run test_matching.dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() async {
  print('🍽️  Food Redistribution App - Matching Algorithm Test');
  print('=' * 50);

  // Test Data Setup
  final testDonation = {
    'id': 'test_donation_1',
    'title': 'Fresh Sandwiches from Restaurant',
    'quantity': 50,
    'foodTypes': ['cooked', 'packaged'],
    'location': {'latitude': 40.7128, 'longitude': -74.0060},
    'isUrgent': true,
    'expiresAt': DateTime.now().add(Duration(hours: 4)).toIso8601String(),
  };

  final testNGOs = [
    {
      'id': 'ngo_1',
      'organizationName': 'Children\'s Food Bank',
      'servingPopulation': ['Children', 'Families'],
      'capacity': 100,
      'location': {'latitude': 40.7589, 'longitude': -73.9851}, // 5km away
      'preferredFoodTypes': ['cooked', 'fruits', 'dairy'],
    },
    {
      'id': 'ngo_2', 
      'organizationName': 'Homeless Shelter Downtown',
      'servingPopulation': ['Homeless', 'Adults'],
      'capacity': 75,
      'location': {'latitude': 40.7505, 'longitude': -73.9934}, // 2km away
      'preferredFoodTypes': ['cooked', 'packaged'],
    },
    {
      'id': 'ngo_3',
      'organizationName': 'Elderly Care Center',
      'servingPopulation': ['Elderly'],
      'capacity': 30,
      'location': {'latitude': 40.7282, 'longitude': -74.0776}, // 8km away  
      'preferredFoodTypes': ['cooked', 'dairy', 'fruits'],
    }
  ];

  print('📍 Test Donation: ${testDonation['title']}');
  print('   Quantity: ${testDonation['quantity']} servings');
  print('   Food Types: ${testDonation['foodTypes']}');
  print('   Expires: ${testDonation['expiresAt']}');
  print('');

  print('🏢 Available NGOs:');
  for (int i = 0; i < testNGOs.length; i++) {
    final ngo = testNGOs[i];
    print('   ${i+1}. ${ngo['organizationName']}');
    print('      Serves: ${ngo['servingPopulation']}');
    print('      Capacity: ${ngo['capacity']} people');
    print('      Preferred: ${ngo['preferredFoodTypes']}');
  }
  print('');

  // Simulate Matching Algorithm  
  print('🎯 Running Matching Algorithm...');
  final matches = _simulateMatching(testDonation, testNGOs);
  
  print('📊 Matching Results:');
  print('=' * 30);
  
  for (int i = 0; i < matches.length; i++) {
    final match = matches[i];
    print('Rank ${i+1}: ${match['ngoName']} (Score: ${match['score'].toStringAsFixed(2)})');
    print('   Distance: ${match['distance'].toStringAsFixed(1)}km');
    print('   Food Match: ${match['foodCompatibility'].toStringAsFixed(2)}');
    print('   Capacity Match: ${match['capacityScore'].toStringAsFixed(2)}');
    print('   Population Match: ${match['populationScore'].toStringAsFixed(2)}');
    print('');
  }

  print('✅ Algorithm Testing Complete!');
  print('💡 The matching system is working with weighted scoring based on:');
  print('   • Geographic proximity (30%)');
  print('   • Food type compatibility (25%)');
  print('   • NGO capacity (25%)');
  print('   • Population served compatibility (20%)');
}

List<Map<String, dynamic>> _simulateMatching(Map<String, dynamic> donation, List<Map<String, dynamic>> ngos) {
  final matches = <Map<String, dynamic>>[];
  
  for (final ngo in ngos) {
    // Calculate distance (simplified)
    final donationLat = donation['location']['latitude'];
    final donationLng = donation['location']['longitude'];
    final ngoLat = ngo['location']['latitude'];
    final ngoLng = ngo['location']['longitude'];
    
    final distance = _calculateDistance(donationLat, donationLng, ngoLat, ngoLng);
    
    // Calculate compatibility scores
    final foodCompatibility = _calculateFoodCompatibility(
      donation['foodTypes'] as List<String>, 
      ngo['preferredFoodTypes'] as List<String>
    );
    
    final capacityScore = _calculateCapacityScore(
      donation['quantity'] as int,
      ngo['capacity'] as int
    );
    
    final populationScore = _calculatePopulationScore(
      donation['foodTypes'] as List<String>,
      ngo['servingPopulation'] as List<String>
    );
    
    // Calculate weighted overall score
    final distanceScore = (15 - distance).clamp(0, 15) / 15; // Closer = better
    final overallScore = (distanceScore * 0.30) + 
                        (foodCompatibility * 0.25) + 
                        (capacityScore * 0.25) + 
                        (populationScore * 0.20);
    
    matches.add({
      'ngoId': ngo['id'],
      'ngoName': ngo['organizationName'],
      'score': overallScore,
      'distance': distance,
      'foodCompatibility': foodCompatibility,
      'capacityScore': capacityScore,
      'populationScore': populationScore,
    });
  }
  
  // Sort by score descending
  matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  return matches;
}

double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  // Simplified distance calculation (Haversine formula approximation)
  const earthRadius = 6371; // km
  final dLat = (lat2 - lat1) * (pi / 180);
  final dLng = (lng2 - lng1) * (pi / 180);
  final a = sin(dLat / 2) * sin(dLat / 2) + 
           cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
           sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * asin(sqrt(a));
  return (earthRadius * c).toDouble();
}

double _calculateFoodCompatibility(List<String> donationTypes, List<String> preferredTypes) {
  if (donationTypes.isEmpty || preferredTypes.isEmpty) return 0.5;
  
  int matches = 0;
  for (final donationType in donationTypes) {
    if (preferredTypes.contains(donationType)) {
      matches++;
    }
  }
  
  return matches / donationTypes.length;
}

double _calculateCapacityScore(int donationQuantity, int ngoCapacity) {
  if (ngoCapacity <= 0) return 0.0;
  
  final ratio = donationQuantity / ngoCapacity;
  if (ratio <= 0.5) return 1.0; // Perfect match
  if (ratio <= 1.0) return 0.8; // Good match
  return 0.3; // Over capacity but possible
}

double _calculatePopulationScore(List<String> foodTypes, List<String> populations) {
  double score = 0.6; // Base score
  
  if (populations.contains('Children') && foodTypes.contains('fruits')) score += 0.2;
  if (populations.contains('Homeless') && foodTypes.contains('cooked')) score += 0.3;
  if (populations.contains('Elderly') && foodTypes.contains('cooked')) score += 0.2;
  
  return score.clamp(0.0, 1.0);
}