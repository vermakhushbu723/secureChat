import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    Widget? suffix = widget.suffix;
    if (widget.obscure) {
      suffix = IconButton(
        icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => setState(() => _hidden = !_hidden),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 22),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({super.key, this.hint = 'Search', this.onChanged, this.autofocus = false});

  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  /// Compact search box: 36px high, #F1F5F9, radius 10, 16px icon, 12px muted placeholder.
  @override
  Widget build(BuildContext context) {
    final muted = context.palette.textMuted;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none);
    return SizedBox(
      height: 36,
      child: TextField(
        autofocus: autofocus,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: muted, fontSize: 12),
          prefixIcon: Icon(Icons.search, size: 16, color: context.palette.textSecondary),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          isDense: true,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}
