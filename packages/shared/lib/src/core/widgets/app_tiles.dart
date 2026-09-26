import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Standard list row with a leading icon.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.palette.danger : context.colors.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap != null && showChevron ? Icon(Icons.chevron_right, color: context.palette.textSecondary) : null),
    );
  }
}

/// A switch row that keeps its own on/off state (UI only).
class AppSwitchTile extends StatefulWidget {
  const AppSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value = false,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<AppSwitchTile> createState() => _AppSwitchTileState();
}

class _AppSwitchTileState extends State<AppSwitchTile> {
  late bool _value = widget.value;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon),
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged?.call(v);
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// Card with a list of children separated by dividers.
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children, this.margin});

  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) items.add(const Divider(indent: 56));
    }
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: items),
      ),
    );
  }
}

/// Key / value row used on detail screens.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: context.palette.textSecondary), const SizedBox(width: 12)],
          Expanded(
            child: Text(label, style: TextStyle(color: context.palette.textSecondary)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
