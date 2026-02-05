import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_provider.dart';

// Reusable widget showing live volunteer location on map
class TrackingMapWidget extends StatefulWidget {
  final double height;
  final bool showMultipleVolunteers;

  const TrackingMapWidget({
    Key? key,
    this.height = 300,
    this.showMultipleVolunteers = false,
  }) : super(key: key);

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  late GoogleMapController _mapController;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, trackingProvider, _) {
        final currentLocation = trackingProvider.currentLocation;
        final latLng = currentLocation != null
            ? LatLng(currentLocation.latitude, currentLocation.longitude)
            : const LatLng(28.6139, 77.2090);
        
        return SizedBox(
          height: widget.height,
          child: GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: latLng,
              zoom: 16,
            ),
            markers: _buildMarkers(trackingProvider),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
        );
      },
    );
  }

  Set<Marker> _buildMarkers(TrackingProvider provider) {
    final markers = <Marker>{};

    // Add current volunteer location
    if (provider.currentLocation != null) {
      final location = provider.currentLocation!;
      markers.add(
        Marker(
          markerId: const MarkerId('volunteer'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: const InfoWindow(
            title: 'Volunteer Location',
            snippet: 'Live tracking active',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    return markers;
  }
}
