import 'dart:math' as math;

import 'package:shared/shared.dart';

/// Chat background: the chat colour with a faint doodle pattern.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(color: context.palette.chatBackground),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _DoodlePainter(dark ? const Color(0x10C84DF5) : const Color(0x146C2BF2))),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.color);

  final Color color;

  static const _icons = [
    Icons.chat_bubble_outline,
    Icons.favorite_border,
    Icons.camera_alt_outlined,
    Icons.music_note_outlined,
    Icons.star_border,
    Icons.call_outlined,
    Icons.emoji_emotions_outlined,
    Icons.lock_outline,
    Icons.cloud_outlined,
    Icons.image_outlined,
    Icons.local_cafe_outlined,
    Icons.headphones_outlined,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 76.0;
    final random = math.Random(7); // same pattern on every frame
    var n = 0;
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final icon = _icons[n++ % _icons.length];
        final dx = x + random.nextDouble() * 30 + ((y ~/ cell).isOdd ? cell / 2 : 0);
        final dy = y + random.nextDouble() * 30;
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 22 + random.nextDouble() * 8, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas
          ..save()
          ..translate(dx, dy)
          ..rotate((random.nextDouble() - 0.5) * 0.8);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => old.color != color;
}
