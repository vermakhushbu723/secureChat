import '../../../core/core.dart';

/// Reason -> Extension Required -> Submit -> Admin approval.
class ExtensionRequestScreen extends StatefulWidget {
  const ExtensionRequestScreen({super.key});

  @override
  State<ExtensionRequestScreen> createState() => _ExtensionRequestScreenState();
}

class _ExtensionRequestScreenState extends State<ExtensionRequestScreen> {
  String _required = '7 days';
  String _reason = 'Still evaluating for my group';
  bool _submitted = false;

  static const _reasons = [
    'Still evaluating for my group',
    'Waiting for payment approval',
    'Faced technical issues',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _pending(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Extension Request')),
      body: FormPage(
        items: [
          const Center(child: FeatureIcon(Icons.more_time, size: 84)),
          const SizedBox(height: 16),
          Text(
            'Request more time',
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Trial expired on ${MockData.currentUser.trialEnd}. The admin reviews every request.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SectionHeader('Extension required', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: '7 days', label: Text('7 days')),
              ButtonSegment(value: '30 days', label: Text('30 days')),
              ButtonSegment(value: 'Premium', label: Text('Premium')),
            ],
            selected: {_required},
            onSelectionChanged: (s) => setState(() => _required = s.first),
          ),
          const SectionHeader('Reason', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: RadioGroup<String>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v!),
              child: Column(
                children: [for (final r in _reasons) RadioListTile<String>(value: r, title: Text(r))],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AppTextField(label: 'Message to admin (optional)', hint: 'Tell us why you need more time', maxLines: 3),
          const SectionHeader('Previous requests', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('7 days extension'),
              subtitle: Text('Requested 10 Aug 2026'),
              trailing: StatusChip('Approved'),
            ),
          ),
        ],
        bottom: PrimaryButton(label: 'Submit Request', onPressed: () => setState(() => _submitted = true)),
      ),
    );
  }

  Widget _pending(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extension Request')),
      body: FormPage(
        items: [
          const MessageBlock(
            icon: Icons.pending_actions_outlined,
            tone: Tone.warning,
            title: 'Request submitted',
            message: 'The admin will approve or reject your request. You will get a notification.',
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                InfoRow(label: 'Extension required', value: _required, icon: Icons.more_time),
                InfoRow(label: 'Reason', value: _reason, icon: Icons.notes),
                const InfoRow(label: 'Status', value: 'Pending admin decision', icon: Icons.hourglass_top),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Approve 7 / 30 days'),
                  subtitle: Text('Extended free access'),
                ),
                ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Premium'),
                  subtitle: Text('Premium access granted'),
                ),
                ListTile(
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Reject'),
                  subtitle: Text('Chat stays locked / limited'),
                ),
              ],
            ),
          ),
        ],
        bottom: PrimaryButton(label: 'Back to Chats', onPressed: () => context.go(AppRoutes.home)),
      ),
    );
  }
}
