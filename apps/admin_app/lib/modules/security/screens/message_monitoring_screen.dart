import '../../../core/core.dart';

const _typeIcons = {
  'text': Icons.chat_bubble_outline,
  'image': Icons.image_outlined,
  'video': Icons.videocam_outlined,
  'audio': Icons.audiotrack_outlined,
  'voice': Icons.mic_none,
  'file': Icons.description_outlined,
  'location': Icons.location_on_outlined,
  'contact': Icons.person_outline,
};

String visibilityName(String? v) => switch (v) {
  'private' => 'Private',
  'highly_protected' => 'Highly protected',
  _ => 'Public',
};

class AdminMessageMonitoringScreen extends StatefulWidget {
  const AdminMessageMonitoringScreen({super.key});

  @override
  State<AdminMessageMonitoringScreen> createState() => _AdminMessageMonitoringScreenState();
}

class _AdminMessageMonitoringScreenState extends State<AdminMessageMonitoringScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/messages', {'q': _q, 'filter': _filter, 'page': _page}),
      builder: (context, d, _) {
        final s = d['stats'] as Map<String, dynamic>;
        final rows = (d['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Message Monitoring',
          subtitle: 'Metadata of messages. Private content stays encrypted.',
          onRefresh: () => setState(() => _reload++),
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.forum_outlined, label: 'Messages (24h)', value: fmtNum(s['messages24h'])),
                StatCard(icon: Icons.lock_outline, label: 'Private share', value: '${s['privateShare']}%'),
                StatCard(icon: Icons.shortcut, label: 'Forwards (24h)', value: fmtNum(s['forwards24h'])),
                StatCard(icon: Icons.gpp_maybe_outlined, label: 'Auto-blocked (24h)', value: fmtNum(s['autoBlocked24h'])),
              ],
            ),
            const SizedBox(height: 16),
            const InfoBanner(
              icon: Icons.privacy_tip_outlined,
              message: 'Only public messages are readable by moderators. Private and highly protected content is never shown. Every view is recorded in the audit log.',
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              hint: 'Search by user, group or public text',
              filters: const {'All': 'all', 'Flagged': 'flagged', 'Forwarded': 'forwarded', 'Files': 'files', 'Private': 'private'},
              selected: _filter,
              onSearch: (q) => setState(() {
                _q = q;
                _page = 1;
              }),
              onChanged: (f) => setState(() {
                _filter = f;
                _page = 1;
              }),
            ),
            AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['Time', 'Message ID', 'Sender', 'Group', 'Type', 'Visibility', 'Content', 'Flags', ''],
              emptyText: 'No messages',
              rows: [
                for (final m in rows)
                  [
                    Text(fmtDateTime(m['at'])),
                    Text('${m['shortId']}', style: const TextStyle(fontFamily: 'monospace')),
                    InkWell(onTap: () => context.push(AdminRoutes.userDetailsOf('${m['senderId']}')), child: Text('${m['sender']}', style: TextStyle(color: context.colors.primary))),
                    InkWell(onTap: () => context.push(AdminRoutes.groupDetailsOf('${m['groupId']}')), child: Text('${m['group']}', style: TextStyle(color: context.colors.primary))),
                    Tooltip(message: capitalize('${m['type']}'), child: Icon(_typeIcons[m['type']] ?? Icons.chat_bubble_outline, size: 20)),
                    StatusChip(visibilityName(m['visibility'] as String?), tone: m['visibility'] == 'public' ? Tone.neutral : Tone.dark),
                    SizedBox(
                      width: 240,
                      child: Text(
                        m['deleted'] == true ? 'Deleted' : (m['content'] as String?) ?? 'Encrypted content',
                        overflow: TextOverflow.ellipsis,
                        style: m['content'] == null || m['deleted'] == true ? const TextStyle(fontStyle: FontStyle.italic) : null,
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (m['forwarded'] == true) const StatusChip('Forwarded', tone: Tone.warning),
                        if (m['flagged'] == true) const StatusChip('Reported', tone: Tone.danger),
                        if (m['forwarded'] != true && m['flagged'] != true) const Text('-'),
                      ],
                    ),
                    IconButton(
                      tooltip: 'View chain',
                      icon: const Icon(Icons.account_tree_outlined),
                      onPressed: () => context.go('${AdminRoutes.forwardChains}?id=${m['rootId']}'),
                    ),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
