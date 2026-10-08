import '../../../core/core.dart';

/// Admin "Email Accounts": mailboxes that send OTP codes and notices. Each email goes out
/// from the next mailbox; a busy or failing one rests and the next one sends instead.
class AdminEmailAccountsScreen extends StatefulWidget {
  const AdminEmailAccountsScreen({super.key});

  @override
  State<AdminEmailAccountsScreen> createState() => _AdminEmailAccountsScreenState();
}

class _AdminEmailAccountsScreenState extends State<AdminEmailAccountsScreen> {
  int _reload = 0;

  void _refresh() => setState(() => _reload++);

  static Tone _tone(String s) => switch (s) {
    'Ready' => Tone.success,
    'Resting' => Tone.warning,
    'Daily limit' => Tone.info,
    _ => Tone.neutral,
  };

  Future<void> _add() async {
    final lines = TextEditingController();
    final host = TextEditingController(text: 'smtp.hostinger.com');
    final limit = TextEditingController(text: '500');
    var port = 465;
    final body = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Add mailboxes'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const InfoBanner(
                    icon: Icons.info_outline,
                    message: 'One mailbox per line: the email address, a space, then its password. An existing mailbox gets the new password.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lines,
                    minLines: 5,
                    maxLines: 12,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(hintText: 'otp0@prosecurely.online Password0\notp1@prosecurely.online Password1'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(flex: 3, child: AppTextField(label: 'SMTP server', controller: host)),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          initialValue: port,
                          decoration: const InputDecoration(labelText: 'Port'),
                          items: const [DropdownMenuItem(value: 465, child: Text('465 (SSL)')), DropdownMenuItem(value: 587, child: Text('587 (TLS)'))],
                          onChanged: (v) => setD(() => port = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: AppTextField(label: 'Emails / day each', controller: limit, keyboardType: TextInputType.number)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final accounts = <Map<String, String>>[];
                for (final l in lines.text.split('\n')) {
                  final t = l.trim();
                  if (t.isEmpty) continue;
                  final i = t.indexOf(RegExp(r'\s'));
                  if (i <= 0) continue;
                  accounts.add({'email': t.substring(0, i).trim(), 'password': t.substring(i).trim()});
                }
                Navigator.pop(ctx, {'accounts': accounts, 'host': host.text.trim(), 'port': port, 'dailyLimit': int.tryParse(limit.text.trim()) ?? 500});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    for (final c in [lines, host, limit]) {
      c.dispose();
    }
    if (body == null || !mounted) return;
    if ((body['accounts'] as List).isEmpty) return context.showSnack('Write "email password" on each line');
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/mail-accounts', body));
    if (r == null || !mounted) return;
    context.showSnack('${(r['added'] as List).length} added, ${(r['updated'] as List).length} updated. Use Test to check each one.');
    _refresh();
  }

  Future<void> _test(Map<String, dynamic> a) async {
    final to = await askText(context, title: 'Send a test email from ${a['email']}', label: 'Send to', hint: 'you@gmail.com', initial: AdminSession.staff.value?.email ?? '', confirm: 'Send');
    if (to == null || to.trim().isEmpty || !mounted) return;
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/mail-accounts/${a['id']}/test', {'to': to.trim()}));
    if (r == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(r['ok'] == true ? 'Test email sent' : 'Test failed'),
        content: Text(r['ok'] == true ? 'Sent from ${r['from']} to $to. Check the inbox (and spam folder).' : '${r['error']}'),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    _refresh();
  }

  /// Edit everything of one mailbox: email, password (empty = keep), server, port, daily limit.
  Future<void> _edit(Map<String, dynamic> a) async {
    final email = TextEditingController(text: '${a['email']}');
    final pass = TextEditingController();
    final host = TextEditingController(text: '${a['host']}');
    final limit = TextEditingController(text: '${a['dailyLimit']}');
    var port = (a['port'] as num?)?.toInt() ?? 465;
    var show = false;
    final body = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit mailbox'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Email address', controller: email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(
                  controller: pass,
                  obscureText: !show,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Leave empty to keep the current password',
                    suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility), onPressed: () => setD(() => show = !show)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 3, child: AppTextField(label: 'SMTP server', controller: host)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: port == 587 ? 587 : 465,
                        decoration: const InputDecoration(labelText: 'Port'),
                        items: const [DropdownMenuItem(value: 465, child: Text('465 (SSL)')), DropdownMenuItem(value: 587, child: Text('587 (TLS)'))],
                        onChanged: (v) => setD(() => port = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(label: 'Emails per day', controller: limit, keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                if (email.text.trim().toLowerCase() != a['email']) 'email': email.text.trim().toLowerCase(),
                if (pass.text.isNotEmpty) 'password': pass.text,
                if (host.text.trim() != a['host']) 'host': host.text.trim(),
                if (port != a['port']) 'port': port,
                if ((int.tryParse(limit.text.trim()) ?? a['dailyLimit']) != a['dailyLimit']) 'dailyLimit': int.tryParse(limit.text.trim()),
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    for (final c in [email, pass, host, limit]) {
      c.dispose();
    }
    if (body == null || body.isEmpty || !mounted) return;
    await _patch(a, body, '${a['email']} saved');
  }

  /// One password for every mailbox (Hostinger mailboxes made with the same password).
  Future<void> _passwordAll(int count) async {
    final p = await askText(context, title: 'Same password for all $count mailboxes', label: 'Password', confirm: 'Save');
    if (p == null || p.isEmpty || !mounted) return;
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/mail-accounts/password-all', {'password': p}));
    if (r == null || !mounted) return;
    context.showSnack('Password saved for ${r['updated']} mailboxes. Use Test to check each one.');
    _refresh();
  }

  Future<void> _patch(Map<String, dynamic> a, Map<String, Object?> body, String done) async {
    final r = await runAction(context, () => AdminApi.patch('/mail-accounts/${a['id']}', body), success: done);
    if (r != null) _refresh();
  }

  Future<void> _menu(Map<String, dynamic> a, String action) async {
    switch (action) {
      case 'edit':
        await _edit(a);
      case 'password':
        final p = await askText(context, title: 'New password for ${a['email']}', label: 'Password', confirm: 'Save');
        if (p != null && p.isNotEmpty) await _patch(a, {'password': p}, 'Password saved');
      case 'limit':
        final v = await askText(context, title: 'Emails per day from ${a['email']}', label: 'Daily limit', initial: '${a['dailyLimit']}', confirm: 'Save');
        final n = int.tryParse(v ?? '');
        if (n != null && n > 0) await _patch(a, {'dailyLimit': n}, 'Daily limit $n');
      case 'ready':
        final r = await runAction(context, () => AdminApi.post('/mail-accounts/${a['id']}/ready'), success: '${a['email']} is ready again');
        if (r != null) _refresh();
      case 'delete':
        if (!await context.confirm(title: 'Remove ${a['email']}?', message: 'Emails will not be sent from this mailbox any more.', confirmLabel: 'Remove', danger: true)) return;
        if (!mounted) return;
        final r = await runAction(context, () => AdminApi.delete('/mail-accounts/${a['id']}'), success: '${a['email']} removed');
        if (r != null) _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: _reload,
      load: () => AdminApi.get('/mail-accounts'),
      builder: (context, d, _) {
        final accounts = (d['accounts'] as List).cast<Map<String, dynamic>>();
        final ready = accounts.where((a) => a['status'] == 'Ready').length;
        final sentToday = accounts.fold<int>(0, (s, a) => s + ((a['sentToday'] as num?)?.toInt() ?? 0));
        final capacity = accounts.where((a) => a['active'] == true).fold<int>(0, (s, a) => s + ((a['dailyLimit'] as num?)?.toInt() ?? 0));
        return AdminPage(
          title: 'Email Accounts',
          subtitle: 'Mailboxes that send OTP codes and notices - they take turns, a busy one is skipped automatically',
          onRefresh: _refresh,
          actions: [
            if (accounts.isNotEmpty)
              OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => _passwordAll(accounts.length), icon: const Icon(Icons.password), label: const Text('Same password for all')),
            FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add mailboxes')),
          ],
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.mark_email_read_outlined, label: 'Mailboxes ready', value: '$ready / ${accounts.length}'),
                StatCard(icon: Icons.send_outlined, label: 'Emails sent today', value: fmtNum(sentToday)),
                StatCard(icon: Icons.speed_outlined, label: 'Daily capacity', value: fmtNum(capacity)),
                StatCard(icon: Icons.pause_circle_outline, label: 'Resting (busy / error)', value: fmtNum(accounts.where((a) => a['status'] == 'Resting').length)),
              ],
            ),
            const SizedBox(height: 16),
            if (accounts.isEmpty)
              const InfoBanner(
                icon: Icons.mail_lock_outlined,
                tone: Tone.warning,
                title: 'No mailbox yet',
                message: 'Until you add one, login codes are shown in the app (test mode). Tap "Add mailboxes" and paste the Hostinger mailboxes with their passwords.',
              ),
            AdminTable(
              columns: const ['Mailbox', 'Status', 'Sent today', 'Total sent', 'Last sent', 'Last problem', 'Server', 'On', ''],
              emptyText: 'No mailboxes',
              rows: [
                for (final a in accounts)
                  [
                    InkWell(onTap: () => _edit(a), child: Text('${a['email']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    Tooltip(
                      message: a['status'] == 'Resting' ? '${a['coolingReason']} - back in ${((a['coolingSeconds'] as num) / 60).ceil()} min' : '',
                      child: StatusChip('${a['status']}', tone: _tone('${a['status']}')),
                    ),
                    Text('${a['sentToday']} / ${a['dailyLimit']}'),
                    Text(fmtNum(a['totalSent'])),
                    Text(fmtAgo(a['lastSentAt'])),
                    SizedBox(
                      width: 220,
                      child: Text(
                        a['lastError'] == null ? '-' : '${a['lastError']} (${fmtAgo(a['lastErrorAt'])})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: a['lastError'] == null ? null : context.palette.danger),
                      ),
                    ),
                    Text('${a['host']}:${a['port']}'),
                    Switch(value: a['active'] == true, onChanged: (v) => _patch(a, {'active': v}, v ? '${a['email']} on' : '${a['email']} off')),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(onPressed: () => _test(a), icon: const Icon(Icons.outgoing_mail, size: 18), label: const Text('Test')),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (v) => _menu(a, v),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'password', child: Text('Change password')),
                            const PopupMenuItem(value: 'limit', child: Text('Daily limit')),
                            if (a['status'] == 'Resting') const PopupMenuItem(value: 'ready', child: Text('Ready now (skip the rest)')),
                            const PopupMenuItem(value: 'delete', child: Text('Remove')),
                          ],
                        ),
                      ],
                    ),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            const InfoBanner(
              icon: Icons.tips_and_updates_outlined,
              message:
                  'How it works: every email is sent from the next mailbox in turn. A mailbox that fails rests for a while - wrong password 60 min, busy / limit 10 min, '
                  'connection problem 5 min - and the email goes out from the next one at once. If every mailbox is down the user sees "try again in a minute".',
            ),
          ],
        );
      },
    );
  }
}
