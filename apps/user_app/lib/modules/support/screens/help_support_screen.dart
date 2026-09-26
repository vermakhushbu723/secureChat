import '../../../core/core.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'Why can I not message a member directly?',
      'Direct 1-to-1 chat is disabled by design. All communication happens inside authorized groups.',
    ),
    (
      'Can members see my phone number?',
      'No. Members see only your display (starting) name. Number, email and user ID stay hidden.',
    ),
    (
      'Why was my message blocked?',
      'Messages with numbers, number words (ONE, TWO...), abusive words, links, social handles or personal details are blocked before sending.',
    ),
    (
      'What is the difference between Public, Private and Highly Protected?',
      'Public can be forwarded. Private cannot be forwarded, copied or downloaded. Highly Protected also blocks copy, screenshots and adds a watermark.',
    ),
    (
      'How does delete for everyone work?',
      'Deleting a message removes it and every copy forwarded from it, across all groups.',
    ),
    (
      'Why does a group need my location?',
      'The group creator made location mandatory. Joining completes only after you allow location.',
    ),
    (
      'What happens after the 7-day trial?',
      'Chat becomes locked. Request an extension from the admin or choose a plan.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: AppSearchField(hint: 'Search help articles'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _Contact(
                    icon: Icons.chat_outlined,
                    label: 'Live chat',
                    onTap: () => context.showSnack('Connecting to support...'),
                  ),
                  const SizedBox(width: 10),
                  _Contact(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    onTap: () => context.showSnack('support@securechat.app'),
                  ),
                  const SizedBox(width: 10),
                  _Contact(icon: Icons.call_outlined, label: 'Call', onTap: () => context.showSnack('1800 000 000')),
                ],
              ),
            ),
            const SectionHeader('Frequently asked questions'),
            GroupedCard(
              children: [
                for (final f in _faqs)
                  ExpansionTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                    shape: const Border(),
                    childrenPadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                    children: [Text(f.$2, style: TextStyle(color: context.palette.textSecondary, height: 1.4))],
                  ),
              ],
            ),
            const SectionHeader('Raise a ticket'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: 'Account',
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                        items: const [
                          'Account',
                          'Messages',
                          'Groups',
                          'Payment',
                          'Location',
                          'Other',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 12),
                      const AppTextField(hint: 'Describe your issue', maxLines: 4),
                      const SizedBox(height: 12),
                      PrimaryButton(label: 'Submit Ticket', onPressed: () => context.showSnack('Ticket #4821 created')),
                    ],
                  ),
                ),
              ),
            ),
            const SectionHeader('My tickets'),
            const GroupedCard(
              children: [
                ListTile(
                  leading: Icon(Icons.confirmation_number_outlined),
                  title: Text('#4790 - Payment not reflected'),
                  subtitle: Text('Updated 2 days ago'),
                  trailing: StatusChip('Resolved'),
                ),
                ListTile(
                  leading: Icon(Icons.confirmation_number_outlined),
                  title: Text('#4802 - Location not updating'),
                  subtitle: Text('Updated today'),
                  trailing: StatusChip('Pending'),
                ),
              ],
            ),
            const SectionHeader('Legal'),
            GroupedCard(
              children: [
                AppTile(
                  icon: Icons.article_outlined,
                  title: 'Terms, Privacy & Policy',
                  onTap: () => context.push(AppRoutes.policies),
                ),
                AppTile(icon: Icons.flag_outlined, title: 'My reports', onTap: () => context.push(AppRoutes.myReports)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: context.palette.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
