import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/food_donation.dart';

class LiveTrackingMap extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final LatLng? volunteerLocation;
  final DonationStatus status;

  const LiveTrackingMap({
    Key? key,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.volunteerLocation,
    required this.status,
  }) : super(key: key);

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.volunteerLocation != oldWidget.volunteerLocation ||
        widget.status != oldWidget.status) {
      _updateMarkers();
      _fitBounds();
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        // Donor / Pickup Marker
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupLocation,
          infoWindow: const InfoWindow(title: 'Pickup Location (Donor)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        // NGO / Dropoff Marker
        Marker(
          markerId: const MarkerId('dropoff'),
          position: widget.dropoffLocation,
          infoWindow: const InfoWindow(title: 'Dropoff Location (NGO)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      };

      // Volunteer Marker (only if assigned/active)
      if (widget.volunteerLocation != null &&
          (widget.status == DonationStatus.pickedUp || 
           widget.status == DonationStatus.inTransit ||
           widget.status == DonationStatus.matched)) {
        
        _markers.add(
          Marker(
            markerId: const MarkerId('volunteer'),
            position: widget.volunteerLocation!,
            infoWindow: const InfoWindow(title: 'Volunteer'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            zIndex: 2, // Show on top
          ),
        );
      }
    });
  }

  void _fitBounds() {
    if (!mounted) return;
    
    // Calculate bounds to include all relevant points
    double minLat = widget.pickupLocation.latitude;
    double maxLat = widget.pickupLocation.latitude;
    double minLng = widget.pickupLocation.longitude;
    double maxLng = widget.pickupLocation.longitude;

    if (widget.dropoffLocation.latitude < minLat) minLat = widget.dropoffLocation.latitude;
    if (widget.dropoffLocation.latitude > maxLat) maxLat = widget.dropoffLocation.latitude;
    if (widget.dropoffLocation.longitude < minLng) minLng = widget.dropoffLocation.longitude;
    if (widget.dropoffLocation.longitude > maxLng) maxLng = widget.dropoffLocation.longitude;

    if (widget.volunteerLocation != null) {
      if (widget.volunteerLocation!.latitude < minLat) minLat = widget.volunteerLocation!.latitude;
      if (widget.volunteerLocation!.latitude > maxLat) maxLat = widget.volunteerLocation!.latitude;
      if (widget.volunteerLocation!.longitude < minLng) minLng = widget.volunteerLocation!.longitude;
      if (widget.volunteerLocation!.longitude > maxLng) maxLng = widget.volunteerLocation!.longitude;
    }

    _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.pickupLocation,
            zoom: 13,
          ),
          markers: _markers,
          onMapCreated: (controller) {
            _controller = controller;
            _fitBounds();
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}
