import '../../../core/core.dart';
import '../state/message_draft.dart';

/// Public / Private selection with the 3 message security levels.
class VisibilitySelectionScreen extends StatefulWidget {
  const VisibilitySelectionScreen({super.key});

  @override
  State<VisibilitySelectionScreen> createState() => _VisibilitySelectionScreenState();
}

class _VisibilitySelectionScreenState extends State<VisibilitySelectionScreen> {
  MessageVisibility _value = Session.defaultVisibility.value;

  static const _features = [
    'View',
    'Forward',
    'Copy',
    'Download',
    'External share',
    'Screenshot',
    'Recording',
    'Watermark',
  ];

  static bool _allowed(MessageVisibility v, String f) => switch (f) {
    'View' => true,
    'Forward' || 'Copy' => v == MessageVisibility.public,
    'Download' || 'External share' || 'Screenshot' => v == MessageVisibility.public,
    'Recording' => v != MessageVisibility.highlyProtected,
    'Watermark' => v == MessageVisibility.highlyProtected,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Privacy')),
      body: FormPage(
        items: [
          Text('Select Message Privacy', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Chosen for every message and file you send. This sets your default.',
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 16),
          for (final v in MessageVisibility.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _value = v),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _value == v ? context.colors.primary : context.palette.divider,
                      width: _value == v ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(icon: v.icon, inverted: _value == v, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text(
                                  v.levelLabel,
                                  style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(_value == v ? Icons.radio_button_checked : Icons.radio_button_off),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(switch (v) {
                        MessageVisibility.public =>
                          'Authorized group members can view and forward. Forward chain is tracked from the original message.',
                        MessageVisibility.private =>
                          'Visible only in this group. Forward, copy, external share and download are disabled. Files open only in the app.',
                        MessageVisibility.highlyProtected =>
                          'Everything in Private plus no copy, screenshot or recording, and a dynamic watermark with your viewer identity.',
                      }),
                      const SizedBox(height: 10),
                      SecurityRulesList(visibility: v),
                    ],
                  ),
                ),
              ),
            ),
          const SectionHeader('Security levels', padding: EdgeInsets.fromLTRB(0, 12, 0, 8)),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  const DataColumn(label: Text('Feature')),
                  for (final v in MessageVisibility.values) DataColumn(label: Text(v.levelLabel)),
                ],
                rows: [
                  for (final f in _features)
                    DataRow(
                      cells: [
                        DataCell(Text(f)),
                        for (final v in MessageVisibility.values)
                          DataCell(
                            Icon(
                              _allowed(v, f) ? Icons.check : Icons.close,
                              size: 18,
                              color: _allowed(v, f) ? context.palette.success : context.palette.danger,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.privacyPermission),
            icon: const Icon(Icons.tune),
            label: const Text('Advanced privacy permissions'),
          ),
        ],
        bottom: PrimaryButton(
          label: 'Use ${_value.label}',
          onPressed: () async {
            await MessageDraft.saveDefault(_value);
            if (!context.mounted) return;
            context.showSnack('Default privacy set to ${_value.label}');
            if (context.canPop()) context.pop();
          },
        ),
      ),
    );
  }
}
