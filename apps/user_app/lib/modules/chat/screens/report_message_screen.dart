import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../widgets/chat_input_bar.dart' show MessagePreviewCard;

class ReportMessageScreen extends StatelessWidget {
  const ReportMessageScreen({super.key, required this.groupId, required this.messageId});

  final String groupId;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Report Message',
      child: Scaffold(
        appBar: AppBar(title: const Text('Report Message')),
        body: AsyncView<GroupMessage>(load: () => GroupRepository.message(messageId), builder: (_, m, _) => _Report(m: m)),
      ),
    );
  }
}

class _Report extends StatefulWidget {
  const _Report({required this.m});

  final GroupMessage m;

  @override
  State<_Report> createState() => _ReportState();
}

class _ReportState extends State<_Report> {
  String? _reason;
  bool _block = false;
  bool _sending = false;
  final _details = TextEditingController();

  static const _reasons = [
    'Spam or misleading',
    'Harassment or bullying',
    'Hate speech or abusive language',
    'Sharing private information',
    'Fraud or scam',
    'Violence or dangerous content',
    'Something else',
  ];

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final ok = await runAction(
      context,
      () => GroupRepository.report(type: 'message', messageId: widget.m.id, reasons: [_reason!], details: _details.text.trim(), alsoBlock: _block),
      done: _block ? 'Report submitted and ${widget.m.senderName} blocked' : 'Report submitted',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) context.pushReplacement(AppRoutes.myReports);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    return FormPage(
      items: [
        MessagePreviewCard(message: m.toChatMessage()),
        const SizedBox(height: 20),
        const Text('Why are you reporting this message?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          child: RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(children: [for (final r in _reasons) RadioListTile<String>(value: r, title: Text(r))]),
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(controller: _details, label: 'Additional details (optional)', hint: 'Tell us more...', maxLines: 3, maxLength: 1000),
        const SizedBox(height: 8),
        if (!m.isMine)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _block,
            onChanged: (v) => setState(() => _block = v ?? false),
            title: Text('Also block ${m.senderName}'),
          ),
        const InfoBanner(message: 'The reported message and its forward chain are shared with moderators. The member will not be notified.'),
      ],
      bottom: PrimaryButton(label: 'Submit Report', danger: true, loading: _sending, onPressed: _reason == null || _sending ? null : _submit),
    );
  }
}
