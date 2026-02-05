# How to Use the Tracking Widgets

I built 4 reusable widgets that your teammates can drop into their dashboards without touching any other code. They all work with the TrackingProvider, so they update automatically in real-time.

## The 4 Widgets I Built

### 1. TrackingMapWidget
Shows the volunteer's live location on a map.

```dart
import 'package:food_redistribution/screens/tracking/tracking_map_widget.dart';

TrackingMapWidget(
  height: 300,
  showMultipleVolunteers: false,
)
```

Just paste this into any dashboard. It gets the volunteer location from TrackingProvider and updates automatically.

**What it shows:**
- Live volunteer position
- Map controls (zoom, my location button)
- Automatic marker updates

### 2. TrackingStatusCard
Shows if tracking is active, online/offline status, and pending syncs.

```dart
import 'package:food_redistribution/screens/tracking/tracking_status_card.dart';

TrackingStatusCard(
  showFullDetails: true,
)
```

**Shows:**
- 🟢 Online or 🔴 Offline
- What status the donation is at (picked, delivered, etc.)
- How many syncs are pending
- When it last updated
- How many active deliveries

### 3. DelayAlertsWidget
Shows red alerts if any pickups or deliveries are running late.

```dart
import 'package:food_redistribution/screens/tracking/delay_alerts_widget.dart';

DelayAlertsWidget(
  compact: false,
  onResolveCallback: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert marked as resolved')),
    );
  },
)
```

**Features:**
- Only shows if there are delays
- Color coded by severity (low/medium/high/critical)
- Shows reason for delay
- Resolve button to dismiss

### 4. LocationTimelineWidget
Real-time location history with timestamps and accuracy.

```dart
import 'package:food_redistribution/screens/tracking/location_timeline_widget.dart';

// Use it:
LocationTimelineWidget(
  itemsToShow: 5, // Show last 5 locations
)
```

**Shows:**
- Lat/lng coordinates
- Time since location update
- GPS accuracy (±Xm)
- Live indicator

---

## 📝 How Teammates Integrate These

### Example: Adding to Volunteer Dashboard

```dart
class VolunteerDashboard extends StatefulWidget {
  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize tracking when dashboard opens
      final trackingProvider = Provider.of<TrackingProvider>(
        context,
        listen: false,
      );
      trackingProvider.startTracking(volunteerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add the map widget
            TrackingMapWidget(height: 300),
            
            SizedBox(height: 16),
            
            // Add the status card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TrackingStatusCard(),
            ),
            
            SizedBox(height: 16),
            
            // Add delay alerts (shows nothing if no delays)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DelayAlertsWidget(
                compact: false,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Add location timeline
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LocationTimelineWidget(itemsToShow: 5),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 End-to-End Testing

### Running E2E Tests

```bash
# Run all tracking tests
flutter test test/tracking/

# Run only E2E test
flutter test test/tracking/e2e_delivery_lifecycle_test.dart

# Run with coverage
flutter test --coverage test/tracking/
```

### What E2E Tests Cover

Located in `test/tracking/e2e_delivery_lifecycle_test.dart`:

| Test | Scenario |
|------|----------|
| Complete flow | Donation → Assignment → Pickup → Delivery |
| Delay detection | SLA breach triggers alert |
| Geofence events | Entry/exit at pickup/delivery zones |
| Offline sync queue | Batched update handling offline |
| Location history | Chronological order maintained |
| Immutability | State updates follow copyWith pattern |
| Analytics | Stats recorded after completion |
| Notifications | Events trigger at key milestones |
| Connectivity | Graceful offline-first sync |

### Example Test Flow

```dart
test('Complete flow: donation created → volunteer assigned → pickup → delivery', 
  () async {
  
  // 1️⃣ Volunteer gets task and starts tracking
  await trackingProvider.startTracking(volunteerId);
  
  // 2️⃣ Save location while volunteer en route
  trackingProvider.updateVolunteerLocation(pickupLocation);
  
  // 3️⃣ Go offline and cache updates
  trackingProvider.setOnlineStatus(false);
  await offlineService.saveOfflineLocationUpdate(pickupLocation);
  
  // 4️⃣ Come online and sync
  trackingProvider.setOnlineStatus(true);
  await offlineService.markUpdatesSynced([pickupLocation.id]);
  
  // 5️⃣ Update status at pickup
  await trackingProvider.updateDonationStatus(
    donationId: donationId,
    newStatus: 'picked',
  );
  
  // 6️⃣ Travel to delivery location
  trackingProvider.updateVolunteerLocation(deliveryLocation);
  
  // 7️⃣ Mark as delivered and get metrics
  await trackingProvider.updateDonationStatus(
    donationId: donationId,
    newStatus: 'delivered',
  );
  final metrics = await trackingProvider.stopTracking();
  
  // ✅ Assertions
  expect(metrics.distanceKm, greaterThan(0));
  expect(trackingProvider.locationHistory.length, greaterThan(0));
}
```

---

## 🔌 Integration Testing

### Running Integration Tests

```bash
# Run integration tests
flutter test test/tracking/tracking_integration_test.dart

# Specific test
flutter test test/tracking/tracking_integration_test.dart -k "TrackingProvider + OfflineTrackingService"
```

### Integration Test Coverage

Located in `test/tracking/tracking_integration_test.dart`:

| Integration | Components |
|-------------|-----------|
| Provider + Offline Service | Real-time state + local caching |
| Delay Detection Service | Task monitoring + SLA checks |
| Multi-task handling | Concurrent deliveries |
| Delay alerts | Creation and resolution |
| Accuracy degradation | Low GPS accuracy handling |
| Status transitions | listed → matched → picked → delivered |
| Geofence actions | Zone entry/exit triggers |
| Analytics metrics | Distance, duration, speed calculations |
| Notifications | Payload structure validation |

---

## 🛠 Test Utilities

### Test Data Builder

```dart
import 'test/tracking/test_mocks.dart';

// Create location update
final locationMap = TestDataBuilder.createLocationUpdateMap(
  volunteerId: 'vol_123',
  taskId: 'task_456',
  latitude: 28.6139,
  longitude: 77.2090,
  status: 'in_transit',
);

// Create delay alert
final alertMap = TestDataBuilder.createDelayAlertMap(
  taskId: 'task_456',
  severity: 'high',
  reason: 'Traffic congestion',
);

// Create metrics
final metricsMap = TestDataBuilder.createTrackingMetricsMap(
  volunteerId: 'vol_123',
  distanceKm: 15.5,
  durationMinutes: 60,
);
```

### Test Scenarios

```dart
import 'test/tracking/test_mocks.dart';

// Get predefined scenario data
final completeDelivery = TrackingTestScenarios.completeDeliveryScenario();
// Returns: {
//   'volunteerId': '...',
//   'taskId': '...',
//   'pickupLocation': {...},
//   'deliveryLocation': {...},
//   'events': [
//     {'type': 'assignment', 'timeMinute': 0},
//     {'type': 'pickup_arrived', 'timeMinute': 12},
//     ...
//   ]
// }

final delayScenario = TrackingTestScenarios.delayedDeliveryScenario();
final offlineScenario = TrackingTestScenarios.offlineSyncScenario();
final multiTaskScenario = TrackingTestScenarios.multipleConcurrentDeliveriesScenario();
```

### Assertion Extensions

```dart
// Validate data structure
locationUpdateMap.expectValidLocationUpdate();
delayAlertMap.expectValidDelayAlert();
geofenceEventMap.expectValidGeofenceEvent();
```

---

## 📊 Running All Tests

```bash
# Run entire test suite
flutter test test/

# Run with coverage report
flutter test --coverage test/

# Generate coverage HTML
genhtml coverage/lcov.info -o coverage/html

# View coverage
open coverage/html/index.html
```

### Expected Coverage (Phase 2 & 3)

| Component | Tests | Coverage Target |
|-----------|-------|-----------------|
| TrackingProvider | 8 tests | 85% |
| OfflineTrackingService | 6 tests | 90% |
| DelayDetectionService | 5 tests | 80% |
| AnalyticsAggregationService | 4 tests | 75% |
| Notification handling | 3 tests | 70% |

---

## 🔄 Workflow for Teammates

### Step 1: Understand Widgets
1. Read this guide
2. Check widget implementations in `lib/screens/tracking/`
3. Look at examples above

### Step 2: Integrate into Your Dashboard
1. Import the widget you need
2. Add to your widget tree
3. Wrap with `Consumer<TrackingProvider>` if needed

### Step 3: Test Integration
1. Run your dashboard
2. Provider automatically updates widgets in real-time
3. No additional state management needed

### Example Quick Integration

```dart
// Add this single widget to your dashboard
import 'package:food_redistribution/screens/tracking/tracking_status_card.dart';

// In your build method
body: Column(
  children: [
    // Your existing UI
    TrackingStatusCard(), // 👈 That's it!
  ],
)
```

---

## 🚀 Running Tests in CI/CD

```yaml
# In your CI pipeline (GitHub Actions, GitLab CI, etc.)
- name: Run Tracking Tests
  run: flutter test test/tracking/ --coverage

- name: Upload Coverage
  run: |
    curl -s https://codecov.io/bash -o codecov.sh
    bash codecov.sh -f coverage/lcov.info
```

---

## ✅ Checklist for Phase 2 Completion

### Tracking Components Created ✅
- [x] TrackingMapWidget
- [x] TrackingStatusCard
- [x] DelayAlertsWidget
- [x] LocationTimelineWidget
- [x] Documentation + examples

### Tests Created ✅
- [x] E2E delivery lifecycle test (10 test cases)
- [x] Integration tests (11 test cases)
- [x] Test utilities and mocks
- [x] Test data builders
- [x] Assertion helpers

### Ready for Teammates ✅
- [x] Reusable widgets (no imports from protected services)
- [x] Full documentation
- [x] Usage examples
- [x] Integration guide

---

## 📞 Support

For teammates integrating tracking:

1. **Quick Start**: Read "How Teammates Integrate These" section
2. **Examples**: Check the "Example: Adding to Volunteer Dashboard" code
3. **Issues**: Widgets use Provider pattern - ensure TrackingProvider is in MultiProvider
4. **Questions**: Check test files for usage patterns

---

## Next Steps (Phase 4+)

- [ ] Real-time map updates with WebSocket
- [ ] Push notifications on delivery completion
- [ ] Offline map caching
- [ ] Extended analytics dashboard
- [ ] Historical tracking replay feature
