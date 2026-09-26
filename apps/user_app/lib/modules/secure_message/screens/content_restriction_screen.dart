import '../../../core/core.dart';

/// Shown when the message processing engine blocks content, or a protected
/// message is forwarded. [rule] is a [ContentRule] name or `privateForward`.
class ContentRestrictionScreen extends StatelessWidget {
  const ContentRestrictionScreen({super.key, this.rule, this.warnings, this.maxWarnings});

  final String? rule;

  /// Server side violation counter ("Warning 2 of 5").
  final int? warnings;
  final int? maxWarnings;

  static const _pipeline = ['Language', 'Abuse', 'Number', 'Number words', 'Spam', 'Links / contact'];

  @override
  Widget build(BuildContext context) {
    final contentRule = ContentRule.values.where((r) => r.name == rule).firstOrNull;
    final privateForward = rule == 'privateForward';
    final title = privateForward ? 'Protected content' : contentRule?.label ?? 'Restricted content';
    final detail = privateForward
        ? 'Private and Highly Protected messages cannot be forwarded, copied, shared or exported.'
        : contentRule == null
        ? 'Your content was blocked by the content policy.'
        : 'Detected: ${contentRule.description}.';

    return Scaffold(
      appBar: AppBar(title: const Text('Message Blocked')),
      body: FormPage(
        items: [
          const SizedBox(height: 12),
          MessageBlock(
            icon: privateForward ? Icons.lock_outline : contentRule?.icon ?? Icons.gpp_maybe_outlined,
            tone: Tone.warning,
            title: privateForward ? 'This action is not allowed' : 'Message not sent',
            message: privateForward
                ? 'This message is protected by its sender.'
                : 'This message cannot be sent because it contains restricted content.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(contentRule?.icon ?? Icons.lock_outline),
              title: Text('Rule triggered: $title', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(detail),
            ),
          ),
          if (!privateForward) ...[
            const SectionHeader('Checked before sending', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final p in _pipeline) StatusChip(p, tone: Tone.neutral, icon: Icons.check)],
            ),
            const SizedBox(height: 16),
            InfoBanner(
              icon: Icons.warning_amber_rounded,
              tone: Tone.danger,
              title: warnings == null ? 'Content policy warning' : 'Warning $warnings of ${maxWarnings ?? 5}',
              message: 'Repeated violations are reported to admins and may restrict or block your account.',
            ),
          ],
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.info_outline,
            message:
                'Sharing phone numbers, number words, links, social handles or personal details is not allowed in groups.',
          ),
        ],
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: privateForward ? 'OK' : 'Edit Message',
              icon: Icons.edit_outlined,
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.push(AppRoutes.policies), child: const Text('View content policy')),
          ],
        ),
      ),
    );
  }
}
