import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'status_chip.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
    this.tone = Tone.neutral,
  });

  final String? title;
  final String message;
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == Tone.neutral ? context.colors.onSurface : toneColor(context, tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone == Tone.neutral ? context.palette.surfaceAlt : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone == Tone.neutral ? context.palette.divider : color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(message, style: TextStyle(color: context.colors.onSurface, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
