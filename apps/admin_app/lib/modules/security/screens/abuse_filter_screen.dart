import '../../../core/core.dart';

class AdminAbuseFilterScreen extends StatefulWidget {
  const AdminAbuseFilterScreen({super.key});

  @override
  State<AdminAbuseFilterScreen> createState() => _AdminAbuseFilterScreenState();
}

class _AdminAbuseFilterScreenState extends State<AdminAbuseFilterScreen> {
  double _sensitivity = 2;
  final _words = ['badword1', 'badword2', 'scam', 'free recharge', 'lottery', 'abuse*'];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const levels = ['Low', 'Medium', 'High'];
    return AdminPage(
      title: 'Abuse / Profanity Filter',
      subtitle: 'Block abusive, hateful and spam words',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Filter saved'),
          child: const Text('Save changes'),
        ),
      ],
      children: [
        PanelCard(
          title: 'Settings',
          child: Column(
            children: [
              const AppSwitchTile(
                icon: Icons.do_not_disturb_on_outlined,
                title: 'Enable profanity filter',
                value: true,
              ),
              const AppSwitchTile(icon: Icons.translate, title: 'Hindi / Hinglish word list', value: true),
              const AppSwitchTile(
                icon: Icons.auto_fix_high,
                title: 'Detect misspellings and symbols',
                subtitle: 'e.g. b@dw0rd',
                value: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 32),
                    const Expanded(child: Text('Sensitivity')),
                    Text(levels[_sensitivity.round() - 1], style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Slider(
                value: _sensitivity,
                min: 1,
                max: 3,
                divisions: 2,
                onChanged: (v) => setState(() => _sensitivity = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Blocked words (${_words.length})',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Add word or phrase'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    color: Colors.white,
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) return;
                      setState(() => _words.add(_controller.text.trim()));
                      _controller.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in _words) InputChip(label: Text(w), onDeleted: () => setState(() => _words.remove(w))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const PanelCard(
          title: 'Penalties',
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.looks_one_outlined),
                title: Text('1st violation'),
                trailing: Text('Warning'),
              ),
              ListTile(
                leading: Icon(Icons.looks_two_outlined),
                title: Text('3 violations in 24h'),
                trailing: Text('Mute 24 hours'),
              ),
              ListTile(
                leading: Icon(Icons.looks_3_outlined),
                title: Text('5 violations in 7 days'),
                trailing: Text('Suspend 7 days'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
