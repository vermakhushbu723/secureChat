import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../core/core.dart';

/// Device location + projection of real coordinates onto the drawn map.
class Geo {
  Geo._();

  /// Asks for permission when needed and returns the current position.
  /// Throws a readable [String] on failure.
  static Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw 'Location services are turned off on this device';
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw 'Location permission denied. Allow it from browser / device settings.';
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
    );
  }

  static Future<LocationPermission> permission() => Geolocator.checkPermission();

  static Future<LocationPermission> request() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.denied ? Geolocator.requestPermission() : p;
  }

  /// Fits every point into the 0..1 map area with a margin.
  static List<MapPin> pins(List<({double lat, double lng, String label, bool isMe})> points) {
    if (points.isEmpty) return const [];
    if (points.length == 1) return [MapPin(dx: 0.5, dy: 0.5, label: points.first.label, isMe: points.first.isMe)];
    final lats = points.map((p) => p.lat);
    final lngs = points.map((p) => p.lng);
    final minLat = lats.reduce(math.min), maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min), maxLng = lngs.reduce(math.max);
    final spanLat = math.max(maxLat - minLat, 0.0005);
    final spanLng = math.max(maxLng - minLng, 0.0005);
    return [
      for (final p in points)
        MapPin(
          dx: 0.12 + 0.76 * ((p.lng - minLng) / spanLng),
          dy: 0.12 + 0.76 * (1 - (p.lat - minLat) / spanLat),
          label: p.label,
          isMe: p.isMe,
        ),
    ];
  }

  static String coords(double lat, double lng) => '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  static String ago(DateTime? t) {
    if (t == null) return 'Never';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  static String mapsUrl(double lat, double lng) => 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}
