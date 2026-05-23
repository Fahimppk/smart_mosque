import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:msque/screens/home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _locationGranted = false;
  bool _dndGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() => _locationGranted = true);
    }

    // Check DND / Sound Mode Access
    bool? isGranted = await PermissionHandler.permissionsGranted;
    if (isGranted == true) {
      setState(() => _dndGranted = true);
    }

    if (_locationGranted && _dndGranted) {
      _navigateToHome();
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable them.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
      );
      return;
    }

    setState(() => _locationGranted = true);
    _checkAllGranted();
  }

  Future<void> _requestDndPermission() async {
    bool? isGranted = await PermissionHandler.permissionsGranted;
    if (isGranted != true) {
      await PermissionHandler.openDoNotDisturbSetting();
    }
    // Re-check after returning from settings
    isGranted = await PermissionHandler.permissionsGranted;
    if (isGranted == true) {
      setState(() => _dndGranted = true);
      _checkAllGranted();
    }
  }

  void _checkAllGranted() {
    if (_locationGranted && _dndGranted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions Required')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'The Mosque App needs the following permissions to function correctly:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: Icon(Icons.location_on, color: _locationGranted ? Colors.green : Colors.grey),
              title: const Text('Location Access'),
              subtitle: const Text('Needed to detect when you enter a mosque.'),
              trailing: _locationGranted 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                      onPressed: _requestLocationPermission,
                      child: const Text('Grant'),
                    ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.do_not_disturb_on, color: _dndGranted ? Colors.green : Colors.grey),
              title: const Text('Do Not Disturb Access'),
              subtitle: const Text('Needed to silence your phone automatically.'),
              trailing: _dndGranted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                      onPressed: _requestDndPermission,
                      child: const Text('Grant'),
                    ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: (_locationGranted && _dndGranted) ? _navigateToHome : null,
              child: const Text('Continue'),
            )
          ],
        ),
      ),
    );
  }
}
