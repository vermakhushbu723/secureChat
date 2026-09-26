import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/group_sender.dart';
import '../../secure_message/state/message_draft.dart';

/// Full screen composer:
/// Message -> PUBLIC / PRIVATE / HIGHLY PROTECTED -> Content & security check -> Send / Block.
class MessageComposerScreen extends StatelessWidget {
  const MessageComposerScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'New Message',
      child: Scaffold(
        appBar: AppBar(title: const Text('New Message')),
        body: AsyncView<GroupDetail>(load: () => GroupRepository.detail(groupId), builder: (_, d, _) => _Composer(detail: d)),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.detail});

  final GroupDetail detail;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  late MessageVisibility _visibility = Session.defaultVisibility.value;
  ContentRule? _violation;
  bool _sending = false;
  final _draft = MessageDraft.instance;

  GroupDetail get d => widget.detail;
  bool get _fixedMode => d.settings.messageMode != 'user_select';
  MessageVisibility get _effective => switch (d.settings.messageMode) {
    'public' => MessageVisibility.public,
    'private' => MessageVisibility.private,
    _ => _visibility,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Instant preview with this group's rules (the server does the real check).
  ContentRule? _check(String text) => ContentFilter.check(text, enabled: {...d.settings.contentRules, ContentRule.abuse});

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return context.showSnack('Type a message');
    setState(() => _sending = true);
    final blocked = await GroupSender.text(d.id, text, _effective);
    if (!mounted) return;
    setState(() => _sending = false);
    if (await GroupSender.handle(context, blocked, sent: '${_effective.label} message sent') && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!d.me.canSend) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(icon: Icons.lock_outline, title: 'You cannot send here', message: d.me.sendBlockedMessage ?? 'Sending is disabled for you in this group.'),
      );
    }
    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) => FormPage(
        items: [
          Text('To: ${d.name}', style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 6,
            maxLines: 12,
            maxLength: 4096,
            onChanged: (v) => setState(() => _violation = _check(v)),
            decoration: const InputDecoration(hintText: 'Type your message...'),
          ),
          if (_violation != null)
            InfoBanner(
              icon: Icons.gpp_bad_outlined,
              tone: Tone.danger,
              title: 'Restricted content: ${_violation!.label}',
              message: 'This message cannot be sent because it contains restricted content.',
            )
          else if (_controller.text.isNotEmpty)
            const InfoBanner(icon: Icons.verified_outlined, tone: Tone.success, message: 'Content check passed.'),
          const SizedBox(height: 12),
          Row(
            children: [
              if (d.me.canSendMedia) ...[
                IconButton.outlined(icon: const Icon(Icons.attach_file), tooltip: 'Attach', onPressed: () => context.push(AppRoutes.attachmentSelectionOf(d.id))),
                const SizedBox(width: 8),
                IconButton.outlined(icon: const Icon(Icons.mic_none), tooltip: 'Voice', onPressed: () => context.push(AppRoutes.voiceMessageOf(d.id))),
                const SizedBox(width: 8),
              ],
              IconButton.outlined(icon: const Icon(Icons.location_on_outlined), tooltip: 'Location', onPressed: () => context.push(AppRoutes.myLocationFor(d.id))),
            ],
          ),
          const SectionHeader('Message privacy', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          if (_fixedMode)
            InfoBanner(icon: Icons.lock_person_outlined, message: 'Group admin set message mode to ${messageModeLabel(d.settings.messageMode)}.')
          else
            for (final v in MessageVisibility.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _visibility = v),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _visibility == v ? context.colors.primary : context.palette.divider, width: _visibility == v ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(v.icon),
                            const SizedBox(width: 10),
                            Expanded(child: Text('${v.label} (${v.levelLabel})', style: const TextStyle(fontWeight: FontWeight.w700))),
                            Icon(_visibility == v ? Icons.radio_button_checked : Icons.radio_button_off),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SecurityRulesList(visibility: v),
                      ],
                    ),
                  ),
                ),
              ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_off_outlined),
                  title: const Text('Send silently'),
                  subtitle: const Text('Members get no notification'),
                  value: _draft.silent,
                  onChanged: (v) => _draft.update(silent: v),
                ),
                const Divider(indent: 56),
                AppTile(
                  icon: Icons.tune,
                  title: 'Advanced privacy permissions',
                  subtitle: 'Expiry: ${_draft.expiryLabel}',
                  onTap: () => context.push(AppRoutes.privacyPermission),
                ),
              ],
            ),
          ),
        ],
        bottom: PrimaryButton(label: 'Send as ${_effective.label}', icon: Icons.send, loading: _sending, onPressed: _sending ? null : _send),
      ),
    );
  }
}
