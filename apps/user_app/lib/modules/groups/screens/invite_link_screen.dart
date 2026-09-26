import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../widgets/group_tile.dart';

/// Generate Link -> Set Expiry -> Set Maximum Joins -> Optional Approval -> Generate.
/// Links can be reset or revoked at any time.
class InviteLinkScreen extends StatelessWidget {
  const InviteLinkScreen({super.key, required this.groupId, this.created = false});

  final String groupId;

  /// True right after the group was created.
  final bool created;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'Invite Link', child: _Invite(groupId: groupId, created: created));
}

class _Invite extends StatefulWidget {
  const _Invite({required this.groupId, required this.created});

  final String groupId;
  final bool created;

  @override
  State<_Invite> createState() => _InviteState();
}

class _InviteState extends State<_Invite> {
  GroupDetail? _detail;
  List<InviteLinkInfo> _links = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _expiry = '24 hours';
  String _maxJoins = '100';
  bool _approval = false;

  static const _expiryValues = {'1 hour': '1h', '24 hours': '24h', '7 days': '7d', '30 days': '30d', 'Never': 'never'};

  InviteLinkInfo? get _current => _links.where((l) => l.isActive).firstOrNull;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([GroupRepository.detail(widget.groupId), GroupRepository.invites(widget.groupId)]);
      if (!mounted) return;
      setState(() {
        _detail = results[0] as GroupDetail;
        _links = results[1] as List<InviteLinkInfo>;
        _approval = _detail!.settings.approveNewMembers;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate({bool reset = false}) async {
    setState(() => _busy = true);
    try {
      final expiry = _expiryValues[_expiry]!;
      final max = _maxJoins == 'Unlimited' ? 0 : int.parse(_maxJoins);
      reset
          ? await GroupRepository.resetInvites(widget.groupId, expiry: expiry, maxJoins: max, requireApproval: _approval)
          : await GroupRepository.newInvite(widget.groupId, expiry: expiry, maxJoins: max, requireApproval: _approval);
      if (mounted) context.showSnack(reset ? 'All old links stopped working. New link created.' : 'New invite link generated');
      await _load();
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(InviteLinkInfo l) async {
    final ok = await context.confirm(title: 'Revoke link?', message: 'The link will stop working immediately.', confirmLabel: 'Revoke', danger: true);
    if (!ok || !mounted) return;
    await runAction(context, () => GroupRepository.revokeInvite(widget.groupId, l.code), done: 'Link revoked');
    await _load();
  }

  Future<void> _share(String via, String url) async {
    final text = 'Join my group "${_detail?.name ?? ''}" on ${AppStrings.appName}: $url';
    final encoded = Uri.encodeComponent(text);
    final uri = switch (via) {
      'WhatsApp' => Uri.parse('https://wa.me/?text=$encoded'),
      'Telegram' => Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent('Join my group on ${AppStrings.appName}')}'),
      'SMS' => Uri.parse('sms:?body=$encoded'),
      _ => null,
    };
    if (uri == null) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) context.showSnack('Invite message copied - paste it anywhere');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) context.showSnack('Could not open $via');
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final current = _current;
    final isAdmin = d?.me.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Link')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
          ? EmptyState(icon: Icons.error_outline, title: 'Could not load', message: _error ?? '')
          : ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.created) ...[
                    const InfoBanner(
                      icon: Icons.check_circle_outline,
                      tone: Tone.success,
                      title: 'Group created',
                      message: 'Share the invite link so people can join. You are the group creator.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(child: GroupAvatar(name: d.name, avatarUrl: d.summary.avatarUrl, size: 72, inverted: true)),
                  const SizedBox(height: 10),
                  Center(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
                  const SizedBox(height: 20),
                  if (current == null)
                    InfoBanner(
                      icon: Icons.link_off,
                      tone: Tone.warning,
                      message: isAdmin ? 'There is no active invite link. Generate a new one below.' : 'There is no active invite link. Ask a group admin.',
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: context.palette.divider), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(8),
                            child: QrImageView(data: current.url, size: 160, backgroundColor: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: context.palette.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.link),
                                const SizedBox(width: 10),
                                Expanded(child: SelectableText(current.url, style: const TextStyle(fontWeight: FontWeight.w700))),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: current.url));
                                    context.showSnack('Link copied');
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expires ${current.expiryLabel}  |  ${current.maxJoins == 0 ? '${current.joins} joins (unlimited)' : '${current.joins}/${current.maxJoins} joins'}${current.requireApproval ? '  |  approval on' : ''}',
                            style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (current != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final (icon, label) in const [
                          (Icons.chat_outlined, 'WhatsApp'),
                          (Icons.send_outlined, 'Telegram'),
                          (Icons.sms_outlined, 'SMS'),
                          (Icons.share_outlined, 'More'),
                        ])
                          _ShareButton(icon: icon, label: label, onTap: () => _share(label, current.url)),
                      ],
                    ),
                  ],
                  if (isAdmin) ...[
                    const SectionHeader('Generate new link', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.timer_outlined),
                            title: const Text('Expiry'),
                            trailing: DropdownButton<String>(
                              value: _expiry,
                              underline: const SizedBox(),
                              items: _expiryValues.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) => setState(() => _expiry = v!),
                            ),
                          ),
                          const Divider(indent: 56),
                          ListTile(
                            leading: const Icon(Icons.group_add_outlined),
                            title: const Text('Maximum joins'),
                            trailing: DropdownButton<String>(
                              value: _maxJoins,
                              underline: const SizedBox(),
                              items: const ['10', '50', '100', '500', 'Unlimited'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) => setState(() => _maxJoins = v!),
                            ),
                          ),
                          const Divider(indent: 56),
                          SwitchListTile(
                            secondary: const Icon(Icons.how_to_reg_outlined),
                            title: const Text('Require approval'),
                            subtitle: const Text('Admin approves every join request'),
                            value: _approval,
                            onChanged: (v) => setState(() => _approval = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(label: 'Generate Link', icon: Icons.add_link, loading: _busy, onPressed: _busy ? null : _generate),
                    const SectionHeader('All links', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
                    Card(
                      child: Column(
                        children: [
                          if (_links.isEmpty) const ListTile(title: Text('No links yet')),
                          for (final l in _links)
                            ListTile(
                              leading: Icon(l.isActive ? Icons.link : Icons.link_off),
                              title: Text(l.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                '${l.joins}${l.maxJoins > 0 ? '/${l.maxJoins}' : ''} joins  |  expires ${l.expiryLabel}${l.createdBy == null ? '' : '  |  by ${l.createdBy}'}',
                              ),
                              trailing: l.isActive
                                  ? TextButton(onPressed: () => _revoke(l), child: Text('Revoke', style: TextStyle(color: context.palette.danger)))
                                  : StatusChip(l.state),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              final ok = await context.confirm(
                                title: 'Reset invite link?',
                                message: 'All existing links will stop working and a new one will be created.',
                                confirmLabel: 'Reset',
                                danger: true,
                              );
                              if (ok) await _generate(reset: true);
                            },
                      icon: Icon(Icons.refresh, color: context.palette.danger),
                      label: Text('Reset invite link', style: TextStyle(color: context.palette.danger)),
                    ),
                  ],
                  if (widget.created) ...[
                    const SizedBox(height: 8),
                    SecondaryButton(label: 'Open group chat', icon: Icons.chat_outlined, onPressed: () => context.pushReplacement(AppRoutes.groupChatOf(widget.groupId))),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              AppAvatar(icon: icon, size: 48),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
