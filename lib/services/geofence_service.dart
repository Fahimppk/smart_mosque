import 'dart:async';
import 'package:geofence_service/geofence_service.dart';
import 'package:msque/services/audio_manager.dart';

class MosqueGeofenceService {
  static final MosqueGeofenceService _instance = MosqueGeofenceService._internal();
  factory MosqueGeofenceService() => _instance;
  MosqueGeofenceService._internal();

  Timer? _silenceTimer;
  bool _isSilenced = false;
  final int _delaySeconds = 30;

  final _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
    useActivityRecognition: false,
    allowMockLocations: true,
    printDevLog: true,
  );

  void initialize() {
    _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.addLocationChangeListener(_onLocationChanged);
    _geofenceService.addLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
    _geofenceService.addActivityChangeListener(_onActivityChanged);
    _geofenceService.addStreamErrorListener(_onError);
  }

  void startGeofencing(List<Geofence> mosques) {
    _geofenceService.start(mosques).catchError(_onError);
  }

  void stopGeofencing() {
    _geofenceService.stop();
    _cancelTimer();
    if (_isSilenced) {
      AudioManager.restoreDeviceSound();
      _isSilenced = false;
    }
  }

  Future<void> _onGeofenceStatusChanged(
      Geofence geofence,
      GeofenceRadius geofenceRadius,
      GeofenceStatus geofenceStatus,
      Location location) async {
    print('geofence: \${geofence.id}, status: \${geofenceStatus.toString()}');

    if (geofenceStatus == GeofenceStatus.ENTER) {
      // User entered a mosque
      _startSilenceTimer();
    } else if (geofenceStatus == GeofenceStatus.EXIT) {
      // User exited the mosque
      _cancelTimer();
      if (_isSilenced) {
        AudioManager.restoreDeviceSound();
        _isSilenced = false;
      }
    }
  }

  void _startSilenceTimer() {
    _cancelTimer(); // Ensure no overlapping timers
    _silenceTimer = Timer(Duration(seconds: _delaySeconds), () async {
      await AudioManager.silenceDevice();
      _isSilenced = true;
    });
  }

  void _cancelTimer() {
    if (_silenceTimer != null && _silenceTimer!.isActive) {
      _silenceTimer!.cancel();
    }
  }

  void _onLocationChanged(Location location) {
    print('location: \${location.toJson()}');
  }

  void _onLocationServicesStatusChanged(bool status) {
    print('isLocationServicesEnabled: \$status');
  }

  void _onActivityChanged(Activity prevActivity, Activity currActivity) {
    print('prevActivity: \${prevActivity.toJson()}');
    print('currActivity: \${currActivity.toJson()}');
  }

  void _onError(dynamic error) {
    final errorCode = getErrorCodesFromError(error);
    if (errorCode == null) {
      print('Undefined error: \$error');
      return;
    }
    print('ErrorCode: \$errorCode');
  }
}
