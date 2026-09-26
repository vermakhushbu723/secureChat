import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum Tone { neutral, dark, success, warning, danger, info }

Color toneColor(BuildContext context, Tone tone) {
  final p = context.palette;
  switch (tone) {
    case Tone.neutral:
      return p.textSecondary;
    case Tone.dark:
      return context.colors.onSurface;
    case Tone.success:
      return p.success;
    case Tone.warning:
      return p.warning;
    case Tone.danger:
      return p.danger;
    case Tone.info:
      return p.info;
  }
}

/// Maps common status text to a tone.
Tone toneForStatus(String status) {
  switch (status.toLowerCase()) {
    case 'active':
    case 'approved':
    case 'resolved':
    case 'paid':
    case 'enabled':
    case 'online':
    case 'premium':
      return Tone.success;
    case 'pending':
    case 'trial':
    case 'reviewed':
    case 'expiring':
      return Tone.warning;
    case 'blocked':
    case 'suspended':
    case 'rejected':
    case 'expired':
    case 'deleted':
    case 'failed':
      return Tone.danger;
    default:
      return Tone.neutral;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone, this.icon});

  final String label;
  final Tone? tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone ?? toneForStatus(label));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
