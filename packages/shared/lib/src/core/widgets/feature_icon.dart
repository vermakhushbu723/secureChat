import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'status_chip.dart';

/// Large circular icon used as a hero on permission / warning / info screens.
class FeatureIcon extends StatelessWidget {
  const FeatureIcon(this.icon, {super.key, this.size = 96, this.tone = Tone.dark});

  final IconData icon;
  final double size;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone);
    final filled = tone == Tone.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? context.colors.primary : color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: size * 0.46, color: filled ? context.colors.onPrimary : color),
    );
  }
}

/// Centered icon + title + message block, used for empty and status screens.
class MessageBlock extends StatelessWidget {
  const MessageBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = Tone.dark,
    this.iconSize = 96,
  });

  final IconData icon;
  final String title;
  final String message;
  final Tone tone;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FeatureIcon(icon, tone: tone, size: iconSize),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.textSecondary, height: 1.45, fontSize: 15),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MessageBlock(icon: icon, title: title, message: message, tone: Tone.neutral, iconSize: 80),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
