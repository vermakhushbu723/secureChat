import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.initials, this.icon, this.size = 48, this.online = false, this.inverted = false});

  final String? initials;
  final IconData? icon;
  final double size;
  final bool online;

  /// Black background with white text when true.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    // Default avatar: light indigo with indigo initials; inverted: solid primary.
    final bg = inverted ? context.colors.primary : context.palette.activeBg;
    final fg = inverted ? context.colors.onPrimary : context.colors.primary;
    // Status dot: 10px on desktop sized avatars, 8px on small / mobile ones.
    final dot = size >= 44 ? 10.0 : 8.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: initials != null
                ? Text(
                    initials!,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: size * 0.34),
                  )
                : Icon(icon ?? Icons.person, color: fg, size: size * 0.5),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: context.palette.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
