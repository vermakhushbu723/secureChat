import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Dynamic, user specific watermark drawn over protected content:
/// CONFIDENTIAL - name - masked user ID - date - time.
class WatermarkOverlay extends StatelessWidget {
  const WatermarkOverlay({
    super.key,
    required this.child,
    required this.name,
    required this.userId,
    this.timestamp = '24 Sep 2026  12:42 PM',
    this.opacity = 0.08,
  });

  final Widget child;
  final String name;
  final String userId;
  final String timestamp;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurface.withValues(alpha: opacity);
    final label = 'CONFIDENTIAL  $name  $userId  $timestamp';
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: OverflowBox(
                maxWidth: 2400,
                maxHeight: 2400,
                child: Transform.rotate(
                  angle: -math.pi / 7,
                  child: Wrap(
                    spacing: 48,
                    runSpacing: 64,
                    children: List.generate(
                      80,
                      (_) => Text(
                        label,
                        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
