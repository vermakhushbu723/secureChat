import '../../../core/core.dart';

/// Progress header for the 3 step group creation flow.
class CreateSteps extends StatelessWidget {
  const CreateSteps({super.key, required this.current});

  final int current;

  static const _labels = ['Name & Photo', 'Description', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= current ? context.colors.primary : context.palette.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Step ${i + 1}  ${_labels[i]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                    color: i == current ? context.colors.onSurface : context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (i < _labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// Radio card used for Off / Optional / Mandatory style choices.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.colors.primary : context.palette.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AppAvatar(icon: icon, size: 40, inverted: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
                  ],
                ),
              ),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
            ],
          ),
        ),
      ),
    );
  }
}
