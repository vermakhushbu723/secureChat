import '../../../core/core.dart';

/// Numeric content detection engine: digits, number words, mixed formats
/// and a normalization layer (T H R E E -> THREE, ONE1 -> ONE).
class AdminNumberFilterScreen extends StatefulWidget {
  const AdminNumberFilterScreen({super.key});

  @override
  State<AdminNumberFilterScreen> createState() => _AdminNumberFilterScreenState();
}

class _AdminNumberFilterScreenState extends State<AdminNumberFilterScreen> {
  bool _digits = true;
  bool _words = true;
  final _test = TextEditingController(text: 'call me on NINE8 seven T H R E E');

  static const _numeric = ['1', '12', '123', '12345', '999', '1000', '9876543210'];
  static const _wordList = [
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
    'HUNDRED',
    'THOUSAND',
    'MILLION',
  ];
  static const _mixed = ['ONE1', 'TWO2', 'THREE3', 'NINETY9', '99 NINETY NINE', 'T H R E E', 'O N E'];

  @override
  void dispose() {
    _test.dispose();
    super.dispose();
  }

  Widget _chips(List<String> items) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final i in items)
        Chip(
          label: Text(i, style: const TextStyle(fontFamily: 'monospace')),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = {if (_digits) ContentRule.numbers, if (_words) ContentRule.numberWords};
    final result = ContentFilter.check(_test.text, enabled: enabled);
    final tokens = ContentFilter.tokens(_test.text);
    return AdminPage(
      title: 'Number Filter',
      subtitle: 'Blocks phone numbers and any numeric content, in every format',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Number filter saved'),
          child: const Text('Save'),
        ),
      ],
      children: [
        PanelCard(
          title: 'Rules',
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.pin_outlined),
                title: const Text('Number Blocking'),
                subtitle: const Text('Any digit 0-9'),
                value: _digits,
                onChanged: (v) => setState(() => _digits = v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.text_fields),
                title: const Text('Number Words Blocking'),
                subtitle: const Text('Includes mixed and spaced formats'),
                value: _words,
                onChanged: (v) => setState(() => _words = v),
              ),
              const AppSwitchTile(icon: Icons.translate, title: 'Hindi number words (ek, do, teen...)', value: true),
              const AppSwitchTile(
                icon: Icons.auto_fix_high,
                title: 'Normalization layer',
                subtitle: 'Remove spaces / symbols, join single letters',
                value: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 300,
          children: [
            PanelCard(title: 'Numeric', padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _chips(_numeric)),
            PanelCard(
              title: 'Number words',
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _chips(_wordList),
            ),
            PanelCard(title: 'Mixed formats', padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _chips(_mixed)),
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Test the engine',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _test,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Type a sample message'),
              ),
              const SizedBox(height: 12),
              Text(
                'Normalized tokens: ${tokens.join('  ')}',
                style: TextStyle(color: context.palette.textSecondary, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              InfoBanner(
                icon: result == null ? Icons.check_circle_outline : Icons.gpp_bad_outlined,
                tone: result == null ? Tone.success : Tone.danger,
                title: result == null ? 'ALLOWED' : 'BLOCKED',
                message: result == null ? 'No numeric content detected.' : 'Rule triggered: ${result.label}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
