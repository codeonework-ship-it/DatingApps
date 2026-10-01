import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SosCoordinates {
  const SosCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class DevicePermissionService {
  const DevicePermissionService();

  Future<bool> requestCallPermissions() async {
    final statuses = await <Permission>[
      Permission.camera,
      Permission.microphone,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<SosCoordinates?> currentSosCoordinates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return SosCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

final devicePermissionServiceProvider = Provider<DevicePermissionService>(
  (_) => const DevicePermissionService(),
);
