import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double lat;
  final double lng;
  const LocationResult({required this.lat, required this.lng});
}

class LocationService {
  LocationService._();

  /// Запрашивает разрешение и возвращает текущую позицию.
  /// Бросает исключение с человеко-понятным текстом.
  static Future<LocationResult> getCurrentLocation({Duration timeout = const Duration(seconds: 12)}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Службы геолокации выключены. Включите геолокацию в настройках устройства.');
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied) {
      throw Exception('Доступ к геолокации не разрешён.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Доступ к геолокации запрещён навсегда. Разрешите его в настройках приложения.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: timeout,
    );

    return LocationResult(lat: pos.latitude, lng: pos.longitude);
  }

  static Future<void> openAppSettings() => Geolocator.openAppSettings();
  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

