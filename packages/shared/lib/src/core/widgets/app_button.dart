import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final style = danger
        ? FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          )
        : null;
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Theme.of(context).colorScheme.onPrimary),
          )
        : Text(label);

    // Full width primary action (form bottoms, cards).
    return SizedBox(
      width: double.infinity,
      child: icon != null && !loading
          ? FilledButton.icon(style: style, onPressed: onPressed, icon: Icon(icon, size: 20), label: child)
          : FilledButton(style: style, onPressed: loading ? null : onPressed, child: child),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: icon != null
          ? OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 20), label: Text(label))
          : OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
