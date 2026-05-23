import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:flutter/services.dart';

class AudioManager {
  static RingerModeStatus? _previousMode;

  /// Changes the device sound mode to silent/vibrate.
  /// Stores the previous mode so it can be restored later.
  static Future<void> silenceDevice() async {
    try {
      // Get current mode before changing
      _previousMode = await SoundMode.ringerModeStatus;
      
      // Attempt to set to silent (or vibrate if silent is not allowed)
      await SoundMode.setSoundMode(RingerModeStatus.silent);
    } on PlatformException catch (e) {
      print('Failed to silence device: ${e.message}');
      // Fallback to vibrate if silent fails
      try {
        await SoundMode.setSoundMode(RingerModeStatus.vibrate);
      } catch (_) {}
    } catch (err) {
      print('Error silencing device: $err');
    }
  }

  /// Restores the device sound mode to what it was before being silenced.
  static Future<void> restoreDeviceSound() async {
    try {
      if (_previousMode != null) {
        await SoundMode.setSoundMode(_previousMode!);
        _previousMode = null;
      } else {
        // Fallback to normal if previous mode is unknown
        await SoundMode.setSoundMode(RingerModeStatus.normal);
      }
    } catch (err) {
      print('Error restoring device sound: $err');
    }
  }
}
