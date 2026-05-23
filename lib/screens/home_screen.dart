import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geofence_service/geofence_service.dart' hide LocationAccuracy;
import 'package:msque/services/geofence_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAutoSilentEnabled = false;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  // Mock list of mosques for testing MVP
  final List<Geofence> _mockMosques = [
    Geofence(
      id: 'mosque_1',
      latitude: 0.0, // Will be updated to user's location + slight offset
      longitude: 0.0,
      radius: [GeofenceRadius(id: 'radius_100m', length: 100)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getCurrentLocation();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoSilentEnabled = prefs.getBool('auto_silent_enabled') ?? false;
    });

    if (_isAutoSilentEnabled) {
      _startGeofencing();
    }
  }

  Future<void> _toggleAutoSilent(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_silent_enabled', value);
    setState(() {
      _isAutoSilentEnabled = value;
    });

    if (_isAutoSilentEnabled) {
      _startGeofencing();
    } else {
      MosqueGeofenceService().stopGeofencing();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        
        // Setup mock mosque slightly offset from current location for testing
        double offsetLat = position.latitude + 0.001;
        double offsetLng = position.longitude + 0.001;

        _mockMosques[0] = Geofence(
          id: 'mock_mosque_nearby',
          latitude: offsetLat,
          longitude: offsetLng,
          radius: [GeofenceRadius(id: 'radius_100m', length: 100)],
        );

        _markers.add(
          Marker(
            markerId: const MarkerId('mosque_1'),
            position: LatLng(offsetLat, offsetLng),
            infoWindow: const InfoWindow(title: 'Nearby Mosque (Mock)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );

        _circles.add(
          Circle(
            circleId: const CircleId('mosque_1_radius'),
            center: LatLng(offsetLat, offsetLng),
            radius: 100,
            fillColor: Colors.green.withOpacity(0.2),
            strokeColor: Colors.green,
            strokeWidth: 2,
          )
        );

        if (_isAutoSilentEnabled) {
          _startGeofencing();
        }
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      print("Error getting location: \$e");
    }
  }

  void _startGeofencing() {
    MosqueGeofenceService().initialize();
    MosqueGeofenceService().startGeofencing(_mockMosques);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mosque Auto Silent'),
        actions: [
          Row(
            children: [
              const Text('Auto Silent', style: TextStyle(fontSize: 14)),
              Switch(
                value: _isAutoSilentEnabled,
                onChanged: _toggleAutoSilent,
                activeColor: Colors.green,
              ),
            ],
          )
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              circles: _circles,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
    );
  }
}
