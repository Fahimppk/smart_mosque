import 'package:flutter/material.dart';
import 'package:msque/screens/permission_screen.dart';
import 'package:geofence_service/geofence_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MosqueApp());
}

// Background task entry point for geofence service
@pragma('vm:entry-point')
void geofenceServiceTask() {
  // Required by geofence_service to run in background
}

class MosqueApp extends StatelessWidget {
  const MosqueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mosque Auto Silent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const PermissionScreen(),
    );
  }
}
