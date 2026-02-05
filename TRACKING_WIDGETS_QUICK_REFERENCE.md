# Quick Start - Add These Widgets to Your Dashboard

Here are the 4 widgets I built. Just copy-paste them into your dashboards - they're standalone and won't break anything.

---

## 1. TrackingStatusCard
Shows: Online/offline status, pending syncs, active deliveries

```dart
import 'package:food_redistribution/screens/tracking/tracking_status_card.dart';

TrackingStatusCard(
  showFullDetails: true,
)
```

Example output:
```
Tracking Status                    🟢 Online
Active Tracking: ✅ Yes
Current Status: 📦 picked
Pending Syncs: 3
Last Update: 5 mins ago
Active Deliveries: 2
```

---

## 2. TrackingMapWidget
Shows: Live volunteer location on Google Map

```dart
import 'package:food_redistribution/screens/tracking/tracking_map_widget.dart';

TrackingMapWidget(
  height: 300,
  showMultipleVolunteers: false,
)
```

Features:
- Live marker updates
- My location button
- Zoom controls
- Auto-centers on volunteer

---

## 3. DelayAlertsWidget
Shows: Active delay alerts with resolve button

```dart
import 'package:food_redistribution/screens/tracking/delay_alerts_widget.dart';

DelayAlertsWidget(
  compact: false,
  onResolveCallback: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert resolved!')),
    );
  },
)
```

Only shows if there are delays. Example:
```
⚠️ Delay Alerts (1)
pickup_delay - HIGH
Traffic congestion [Resolve]
```

---

## 4. LocationTimelineWidget
**Shows**: Real-time location history with timestamps

```dart
import 'package:food_redistribution/screens/tracking/location_timeline_widget.dart';

LocationTimelineWidget(
  itemsToShow: 5, // Show last 5 locations
)
```

**Output**:
```
Location Updates                   🟢 Live
────────────────────────────────────────
🔵 28.6139, 77.2090
   Just now • ±5m

🔵 28.6150, 77.2100
   2m ago • ±4m

🔵 28.6160, 77.2110
   5m ago • ±6m
```

---

## 📋 Integration Examples

### Volunteer Dashboard
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
      Provider.of<TrackingProvider>(context, listen: false)
        .startTracking(volunteerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TrackingMapWidget(height: 300),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TrackingStatusCard(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: LocationTimelineWidget(itemsToShow: 5),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DelayAlertsWidget(compact: false),
            ),
          ],
        ),
      ),
    );
  }
}
```

### NGO Dashboard
```dart
class NGODashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NGO Dashboard')),
      body: Column(
        children: [
          TrackingMapWidget(height: 250),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TrackingStatusCard(showFullDetails: false), // Compact
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DelayAlertsWidget(compact: true),
          ),
        ],
      ),
    );
  }
}
```

### Donor Dashboard
```dart
class DonorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TrackingStatusCard(showFullDetails: true),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: LocationTimelineWidget(itemsToShow: 3),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DelayAlertsWidget(compact: false),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ⚙️ How It Works (Behind the Scenes)

All widgets use **TrackingProvider** via Consumer pattern:

```dart
Consumer<TrackingProvider>(
  builder: (context, trackingProvider, _) {
    return Text('Location: ${trackingProvider.currentLocation}');
  },
)
```

**Available from TrackingProvider**:
```dart
trackingProvider.isOnline            // bool
trackingProvider.isTracking          // bool
trackingProvider.currentLocation     // LocationUpdate?
trackingProvider.currentStatus       // String?
trackingProvider.pendingUpdates      // int
trackingProvider.lastSync            // DateTime?
trackingProvider.activeTasksCount    // int
trackingProvider.locationHistory     // List<LocationUpdate>
trackingProvider.delayAlerts         // List<DelayAlert>
trackingProvider.geofenceEvents      // List<GeofenceEvent>
```

---

## 🔧 Advanced Options

### Customize Status Card

```dart
// Show only essential info
TrackingStatusCard(showFullDetails: false)

// Show all metrics
TrackingStatusCard(showFullDetails: true)
```

### Customize Delay Alerts

```dart
// Full view with resolve button
DelayAlertsWidget(compact: false)

// Compact list only
DelayAlertsWidget(compact: true)

// With custom callback
DelayAlertsWidget(
  onResolveCallback: () {
    // Your custom logic
    _sendNotification('Alert resolved!');
  },
)
```

### Customize Timeline

```dart
// Show last 3 locations
LocationTimelineWidget(itemsToShow: 3)

// Show last 10 locations
LocationTimelineWidget(itemsToShow: 10)

// Show all
LocationTimelineWidget(itemsToShow: 999)
```

---

## 🐛 Troubleshooting

### Widget showing nothing?
- Check if `TrackingProvider` is in `MultiProvider`
- Verify `startTracking()` was called
- Check console for errors

### Map not showing location?
- Ensure Google Maps API key configured
- Check location permissions granted
- Verify Geolocator plugin installed

### Notifications not appearing?
- Check FCM setup in Firebase Console
- Verify `NotificationHandler.initializeNotifications()` called
- Check background notification permissions

---

## 📚 Full Documentation

See `TRACKING_INTEGRATION_GUIDE.md` for:
- Complete setup instructions
- E2E testing guide
- All available features
- Advanced customization

---

## ✅ Checklist Before Integration

- [ ] TrackingProvider added to MultiProvider
- [ ] Import widgets from `lib/screens/tracking/`
- [ ] Add widgets to your widget tree
- [ ] Call `startTracking()` in initState
- [ ] Test on device with location enabled
- [ ] Verify Firebase rules allow read/write

---

## 📞 Need Help?

Check these files:
1. `test/tracking/e2e_delivery_lifecycle_test.dart` - Usage examples
2. `TRACKING_INTEGRATION_GUIDE.md` - Full guide
3. Widget source files - Implementation details

**That's it! You're ready to integrate real-time tracking!** 🚀
