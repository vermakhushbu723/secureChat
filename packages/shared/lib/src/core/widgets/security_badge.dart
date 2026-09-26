import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';
import '../theme/app_palette.dart';

/// Small pill that shows the security level of a message / file.
class SecurityBadge extends StatelessWidget {
  const SecurityBadge(this.visibility, {super.key, this.compact = false, this.color});

  final MessageVisibility visibility;
  final bool compact;

  /// Override the foreground color (e.g. inside a dark chat bubble).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.onSurface;
    if (compact) return Icon(visibility.icon, size: 13, color: fg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visibility.icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              visibility.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of allowed / blocked actions for a security level.
class SecurityRulesList extends StatelessWidget {
  const SecurityRulesList({super.key, required this.visibility});

  final MessageVisibility visibility;

  static List<(String, bool)> rulesFor(MessageVisibility v) => switch (v) {
    MessageVisibility.public => [
      ('View', true),
      ('Forward', true),
      ('Copy', true),
      ('Download', true),
      ('Screenshot', true),
      ('Watermark', false),
    ],
    MessageVisibility.private => [
      ('View', true),
      ('Forward', false),
      ('Copy', false),
      ('Download', false),
      ('External share', false),
      ('Screenshot', false),
    ],
    MessageVisibility.highlyProtected => [
      ('View', true),
      ('Forward', false),
      ('Copy', false),
      ('Download', false),
      ('External share', false),
      ('Screenshot', false),
      ('Recording', false),
      ('Dynamic watermark', true),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in rulesFor(visibility))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                r.$2 ? Icons.check_circle_outline : Icons.block,
                size: 15,
                color: r.$2 ? context.palette.success : context.palette.danger,
              ),
              const SizedBox(width: 3),
              Text(r.$1, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
            ],
          ),
      ],
    );
  }
}
