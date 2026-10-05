import '../../../core/core.dart';
import '../../../core/widgets/admin_shell.dart';

/// Admin decision on trial extension requests:
/// [Approve 7 Days] [Approve 30 Days] [Premium] [Reject]
class AdminExtensionRequestsScreen extends StatefulWidget {
  const AdminExtensionRequestsScreen({super.key});

  @override
  State<AdminExtensionRequestsScreen> createState() => _AdminExtensionRequestsScreenState();
}

class _AdminExtensionRequestsScreenState extends State<AdminExtensionRequestsScreen> {
  String _q = '';
  String _status = 'pending';
  int _page = 1;
  int _reload = 0;

  Future<void> _decide(Map<String, dynamic> r, {required bool approve, int? days, String? as}) async {
    final name = (r['user'] as Map)['name'];
    if (!approve && !await context.confirm(title: 'Reject request?', message: 'Chat stays locked for $name.', confirmLabel: 'Reject', danger: true)) return;
    if (!mounted) return;
    final done = await runAction(
      context,
      () => AdminApi.post('/requests/${r['id']}', {'approve': approve, 'days': ?days, 'as': ?as}),
      success: !approve ? 'Request rejected - chat stays locked' : as == 'premium' ? 'Premium granted to $name ($days days)' : 'Approved $days days for $name',
    );
    if (done != null) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_status|$_page|$_reload',
      load: () => AdminApi.get('/requests', {'q': _q, 'status': _status, 'page': _page}),
      builder: (context, d, _) {
        final rows = (d['items'] as List).cast<Map<String, dynamic>>();
        WidgetsBinding.instance.addPostFrameCallback((_) => pendingRequests.value = (d['pending'] as num).toInt());
        return AdminPage(
          title: 'Extension Requests',
          subtitle: '${fmtNum(d['pending'])} pending requests',
          onRefresh: () => setState(() => _reload++),
          children: [
            AdminFilterBar(
              hint: 'Search user name, mobile or email',
              filters: const {'Pending': 'pending', 'Approved': 'approved', 'Rejected': 'rejected', 'All': 'all'},
              selected: _status,
              onSearch: (q) => setState(() {
                _q = q;
                _page = 1;
              }),
              onChanged: (s) => setState(() {
                _status = s;
                _page = 1;
              }),
            ),
            if (rows.isEmpty) const InfoBanner(icon: Icons.inbox_outlined, message: 'No requests in this list.'),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(initials: initialsOf((r['user'] as Map)['name'] as String?), size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push(AdminRoutes.userDetailsOf('${(r['user'] as Map)['id']}')),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('User: ${(r['user'] as Map)['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(
                                      '${(r['user'] as Map)['internalId']}  |  ${accessLabel((r['user'] as Map)['access'] as String?)}  |  Trial ${(r['user'] as Map)['trialEndsAt'] == null ? 'not claimed' : 'ended ${fmtDate((r['user'] as Map)['trialEndsAt'])}'}  |  ${(r['user'] as Map)['extensionCount'] ?? 0} extensions used',
                                      style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            StatusChip(capitalize('${r['status']}')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            Text('Reason: ${(r['reason'] as String?)?.isNotEmpty == true ? r['reason'] : '-'}'),
                            Text('Requested: ${r['kind'] == 'premium' ? 'Premium' : '${r['days']} days extension'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('On ${fmtDateTime(r['createdAt'])}', style: TextStyle(color: context.palette.textSecondary)),
                            if (r['status'] != 'pending')
                              Text(
                                '${capitalize('${r['status']}')}${r['grantedAs'] == 'premium' ? ' as premium' : ''} by ${r['decidedBy'] ?? 'admin'} on ${fmtDateTime(r['decidedAt'])}',
                                style: TextStyle(color: context.palette.textSecondary),
                              ),
                          ],
                        ),
                        if (r['status'] == 'pending') ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _decide(r, approve: true, days: 7, as: 'extension'),
                                child: const Text('Approve 7 Days'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _decide(r, approve: true, days: 30, as: 'extension'),
                                child: const Text('Approve 30 Days'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () async {
                                  final days = await askDays(context, title: 'Premium for', options: const [30, 90, 365]);
                                  if (days != null) await _decide(r, approve: true, days: days, as: 'premium');
                                },
                                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                                label: const Text('Premium'),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), foregroundColor: context.palette.danger),
                                onPressed: () => _decide(r, approve: false),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            if ((d['total'] as num) > rows.length)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Page $_page', style: TextStyle(color: context.palette.textSecondary)),
                  IconButton(onPressed: _page > 1 ? () => setState(() => _page--) : null, icon: const Icon(Icons.chevron_left)),
                  IconButton(onPressed: _page * 25 < (d['total'] as num) ? () => setState(() => _page++) : null, icon: const Icon(Icons.chevron_right)),
                ],
              ),
          ],
        );
      },
    );
  }
}
