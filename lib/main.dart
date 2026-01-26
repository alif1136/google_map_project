import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LocationTracker(),
    );
  }
}

class LocationTracker extends StatefulWidget {
  const LocationTracker({super.key});

  @override
  State<LocationTracker> createState() => _LocationTrackerState();
}

class _LocationTrackerState extends State<LocationTracker> {
  GoogleMapController? mapController;
  Timer? timer;

  LatLng? currentLocation;
  LatLng? previousLocation;

  final Set<Marker> markers = {};
  final List<LatLng> polylineCoordinates = [];

  final Set<Polyline> polylines = {
    const Polyline(
      polylineId: PolylineId("route"),
      color: Colors.blue,
      width: 5,
    ),
  };

  @override
  void initState() {
    super.initState();
    _getInitialLocation();
    _startLocationUpdates();
  }

  Future<void> _getInitialLocation() async {
    Position position = await _getPosition();
    currentLocation = LatLng(position.latitude, position.longitude);

    _updateMarker(position);
  }

  void _startLocationUpdates() {
    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      Position position = await _getPosition();

      previousLocation = currentLocation;
      currentLocation = LatLng(position.latitude, position.longitude);

      if (previousLocation != null) {
        polylineCoordinates.add(previousLocation!);
        polylineCoordinates.add(currentLocation!);
      }

      _updateMarker(position);
      _animateCamera();
      _updatePolyline();
    });
  }

  Future<Position> _getPosition() async {
    await Geolocator.requestPermission();
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _updateMarker(Position position) {
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId("currentLocation"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(
          title: "My current location",
          snippet:
          "Lat: ${position.latitude}, Lng: ${position.longitude}",
        ),
      ),
    );
    setState(() {});
  }

  void _updatePolyline() {
    polylines.clear();
    polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        width: 5,
        points: polylineCoordinates,
      ),
    );
    setState(() {});
  }

  void _animateCamera() {
    if (mapController != null && currentLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(currentLocation!),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Real-Time Location Tracker"),
        backgroundColor: Colors.blue,
      ),
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocation!,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
