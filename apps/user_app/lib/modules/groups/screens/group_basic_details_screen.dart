import '../../../core/core.dart';
import '../state/group_draft.dart';
import '../widgets/create_steps.dart';

/// Create Group - step 2: description, category and rules.
class GroupBasicDetailsScreen extends StatefulWidget {
  const GroupBasicDetailsScreen({super.key});

  @override
  State<GroupBasicDetailsScreen> createState() => _GroupBasicDetailsScreenState();
}

class _GroupBasicDetailsScreenState extends State<GroupBasicDetailsScreen> {
  final _draft = GroupDraft.current;
  late final _description = TextEditingController(text: _draft.description);
  late final _rules = TextEditingController(text: _draft.rules);
  late String _category = _draft.category;

  static const _categories = ['Business', 'Team / Office', 'Training', 'Community', 'Family', 'Other'];

  @override
  void dispose() {
    _description.dispose();
    _rules.dispose();
    super.dispose();
  }

  void _next() {
    _draft
      ..description = _description.text.trim()
      ..rules = _rules.text.trim()
      ..category = _category;
    context.push(AppRoutes.newGroupSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: FormPage(
        items: [
          const CreateSteps(current: 1),
          const SizedBox(height: 24),
          AppTextField(
            controller: _description,
            label: 'Group Description',
            hint: 'What is this group about?',
            prefixIcon: Icons.notes,
            maxLines: 4,
            maxLength: 300,
          ),
          const SizedBox(height: 12),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _categories)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AppTextField(controller: _rules, label: 'Group Rules (optional)', hint: 'Be respectful. No selling.', maxLines: 3, maxLength: 500),
        ],
        bottom: PrimaryButton(label: 'Next', icon: Icons.arrow_forward, onPressed: _next),
      ),
    );
  }
}
