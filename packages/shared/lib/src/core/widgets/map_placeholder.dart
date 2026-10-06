import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'live_map/live_map_frame_stub.dart'
    if (dart.library.js_interop) 'live_map/live_map_frame_web.dart'
    if (dart.library.io) 'live_map/live_map_frame_io.dart';

class MapPin {
  const MapPin({required this.dx, required this.dy, required this.label, this.isMe = false, this.lat, this.lng});

  /// Relative position 0..1 inside the drawn map.
  final double dx;
  final double dy;
  final String label;
  final bool isMe;

  /// Real coordinates: shown on Google Maps when the map is set up.
  final double? lat;
  final double? lng;

  bool get hasCoords => lat != null && lng != null;
}

/// Google Maps for the apps. Each app sets [embedUrl] (the API's /maps/embed page) and
/// [enabled] from GET /config (admin System Settings -> Google Maps).
class MapConfig {
  MapConfig._();

  static String embedUrl = '';
  static final enabled = ValueNotifier<bool>(false);

  /// Web, Android and iOS can show the map page.
  static bool get supported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
}

/// Map with pins: Google Maps when it is set up and the pins have coordinates, otherwise
/// a lightweight drawn map. [interactive] maps can be dragged / zoomed ([fullScreen]: freely,
/// otherwise ctrl + scroll); other maps are previews and let taps through.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, this.pins = const [], this.height, this.radius = 16, this.showControls = false, bool? interactive, this.fullScreen = false, this.zoom})
    : interactive = interactive ?? showControls;

  final List<MapPin> pins;
  final double? height;
  final double radius;
  final bool showControls;
  final bool interactive;
  final bool fullScreen;
  final int? zoom;

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MapConfig.enabled,
      builder: (context, on, _) {
        if (!on || !MapConfig.supported || MapConfig.embedUrl.isEmpty || pins.isEmpty || !pins.every((p) => p.hasCoords)) return _drawn(context);
        final data = jsonEncode({
          'pins': [for (final p in pins) {'lat': p.lat, 'lng': p.lng, 'label': p.label, 'me': p.isMe}],
          'mode': !interactive ? 'static' : fullScreen ? 'full' : 'embed',
          'color': _hex(context.colors.primary),
          'meColor': _hex(context.palette.info),
          'zoom': ?zoom,
        });
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: height,
            child: ColoredBox(
              color: context.palette.surfaceAlt,
              child: LiveMapFrame(url: MapConfig.embedUrl, data: data, interactive: interactive),
            ),
          ),
        );
      },
    );
  }

  Widget _drawn(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPainter(
                      bg: context.palette.surfaceAlt,
                      road: context.colors.surface,
                      block: context.palette.divider,
                    ),
                  ),
                ),
                for (final pin in pins)
                  Positioned(
                    left: pin.dx * c.maxWidth - 20,
                    top: pin.dy * c.maxHeight - 44,
                    child: _PinWidget(pin: pin),
                  ),
                if (showControls)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(
                      children: [
                        _MapButton(icon: Icons.add, onTap: () {}),
                        const SizedBox(height: 8),
                        _MapButton(icon: Icons.remove, onTap: () {}),
                        const SizedBox(height: 8),
                        _MapButton(icon: Icons.my_location, onTap: () {}),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }
}

class _PinWidget extends StatelessWidget {
  const _PinWidget({required this.pin});

  final MapPin pin;

  @override
  Widget build(BuildContext context) {
    final color = pin.isMe ? context.palette.info : context.colors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x22000000))],
          ),
          child: Text(pin.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ),
        Icon(pin.isMe ? Icons.navigation : Icons.location_on, color: color, size: 28),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.bg, required this.road, required this.block});

  final Color bg;
  final Color road;
  final Color block;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    final blockPaint = Paint()..color = block.withValues(alpha: 0.6);
    const cell = 70.0;
    for (double x = 10; x < size.width; x += cell) {
      for (double y = 10; y < size.height; y += cell) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cell - 16, cell - 16), const Radius.circular(6)),
          blockPaint,
        );
      }
    }

    final roadPaint = Paint()
      ..color = road
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.45, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.65, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.bg != bg || old.road != road || old.block != block;
}
