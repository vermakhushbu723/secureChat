import '../../../core/core.dart';

class AdminPlanManagementScreen extends StatefulWidget {
  const AdminPlanManagementScreen({super.key});

  @override
  State<AdminPlanManagementScreen> createState() => _AdminPlanManagementScreenState();
}

class _AdminPlanManagementScreenState extends State<AdminPlanManagementScreen> {
  int _reload = 0;
  bool _archived = false;

  void _refresh() => setState(() => _reload++);

  static const _periodDays = {'week': 7, 'month': 30, 'year': 365, 'custom': 30};
  static String _period(String p) => switch (p) {
    'week' => 'week',
    'year' => 'year',
    'custom' => 'custom',
    _ => 'month',
  };

  Future<void> _edit([Map<String, dynamic>? plan]) async {
    final name = TextEditingController(text: '${plan?['name'] ?? ''}');
    final price = TextEditingController(text: plan == null ? '' : '${plan['price']}');
    final days = TextEditingController(text: '${plan?['durationDays'] ?? 30}');
    final features = TextEditingController(text: [for (final f in (plan?['features'] as List? ?? const [])) '$f'].join('\n'));
    var period = '${plan?['period'] ?? 'month'}';
    var popular = plan?['popular'] == true;
    final saved = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(plan == null ? 'New plan' : 'Edit ${plan['name']}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(label: 'Plan name', controller: name),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: AppTextField(label: 'Price (INR)', controller: price, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: period,
                          decoration: const InputDecoration(labelText: 'Period'),
                          items: const [
                            DropdownMenuItem(value: 'week', child: Text('Weekly')),
                            DropdownMenuItem(value: 'month', child: Text('Monthly')),
                            DropdownMenuItem(value: 'year', child: Text('Yearly')),
                            DropdownMenuItem(value: 'custom', child: Text('Custom')),
                          ],
                          onChanged: (v) => setD(() {
                            period = v!;
                            days.text = '${_periodDays[period]}';
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Premium duration (days)', controller: days, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Features (one per line)', controller: features, maxLines: 4),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: popular, onChanged: (v) => setD(() => popular = v!), title: const Text('Mark as popular')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'name': name.text.trim(),
                'price': num.tryParse(price.text.trim()) ?? 0,
                'period': period,
                'durationDays': int.tryParse(days.text.trim()) ?? _periodDays[period],
                'features': [for (final f in features.text.split('\n')) if (f.trim().isNotEmpty) f.trim()],
                'popular': popular,
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    for (final c in [name, price, days, features]) {
      c.dispose();
    }
    if (saved == null || !mounted) return;
    if ((saved['name'] as String).isEmpty) return context.showSnack('Enter a plan name');
    final r = await runAction(context, () => plan == null ? AdminApi.post('/plans', saved) : AdminApi.patch('/plans/${plan['id']}', saved), success: plan == null ? 'Plan created' : 'Plan saved');
    if (r != null) _refresh();
  }

  Future<void> _patch(Map<String, dynamic> p, Map<String, Object?> body, String done) async {
    final r = await runAction(context, () => AdminApi.patch('/plans/${p['id']}', body), success: done);
    if (r != null) _refresh();
  }

  Future<void> _addCoupon() async {
    final code = TextEditingController();
    final percent = TextEditingController(text: '20');
    final desc = TextEditingController();
    final maxUses = TextEditingController(text: '0');
    DateTime? expires;
    final saved = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('New coupon'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Code', hint: 'WELCOME20', controller: code),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: '% off', controller: percent, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: AppTextField(label: 'Max uses (0 = unlimited)', controller: maxUses, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(label: 'Description', controller: desc),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(expires == null ? 'No expiry date' : 'Expires ${fmtDate(expires!.toIso8601String())}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)), initialDate: DateTime.now().add(const Duration(days: 30)));
                      if (d != null) setD(() => expires = d);
                    },
                    child: const Text('Pick date'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'code': code.text.trim().toUpperCase(),
                'percentOff': int.tryParse(percent.text.trim()) ?? 0,
                'description': desc.text.trim(),
                'maxUses': int.tryParse(maxUses.text.trim()) ?? 0,
                'expiresAt': expires?.toUtc().toIso8601String(),
              }),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    for (final c in [code, percent, desc, maxUses]) {
      c.dispose();
    }
    if (saved == null || !mounted) return;
    final r = await runAction(context, () => AdminApi.post('/coupons', saved), success: 'Coupon ${saved['code']} created');
    if (r != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<List<dynamic>>(
      reloadKey: '$_reload|$_archived',
      load: () async => [
        await AdminApi.get<List<dynamic>>('/plans', {'archived': _archived ? 'true' : null}),
        await AdminApi.get<List<dynamic>>('/coupons'),
        await AdminApi.get<Map<String, dynamic>>('/settings/subscription'),
      ],
      builder: (context, data, _) {
        final plans = (data[0] as List).cast<Map<String, dynamic>>();
        final coupons = (data[1] as List).cast<Map<String, dynamic>>();
        final settings = data[2] as Map<String, dynamic>;
        return AdminPage(
          title: 'Premium Plans',
          subtitle: 'Create plans and set trial / premium durations',
          onRefresh: _refresh,
          actions: [
            FilterChip(label: const Text('Show archived'), selected: _archived, onSelected: (v) => setState(() => _archived = v)),
            FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('New plan')),
          ],
          children: [
            if (plans.isEmpty)
              const InfoBanner(icon: Icons.workspace_premium_outlined, message: 'No plans yet. Tap "New plan" to create the first one - visible plans show in the app.'),
            ResponsiveGrid(
              minItemWidth: 300,
              children: [
                for (final p in plans)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('${p['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                              if (p['archived'] == true) const StatusChip('Archived', tone: Tone.neutral) else if (p['popular'] == true) const StatusChip('Popular', tone: Tone.dark),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${p['currency'] == 'INR' ? 'Rs ' : '${p['currency']} '}${p['price']} / ${_period('${p['period']}')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${p['durationDays']} days premium  |  ${fmtNum(p['subscribers'])} subscribers', style: TextStyle(color: context.palette.textSecondary)),
                          const Divider(height: 24),
                          for (final f in (p['features'] as List))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(children: [const Icon(Icons.check, size: 16), const SizedBox(width: 8), Expanded(child: Text('$f'))]),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Visible to users'),
                              const Spacer(),
                              Switch(value: p['visible'] == true, onChanged: p['archived'] == true ? null : (v) => _patch(p, {'visible': v}, v ? 'Plan visible in the app' : 'Plan hidden from the app')),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                                  onPressed: () => _edit(p),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                tooltip: p['archived'] == true ? 'Restore' : 'Archive',
                                icon: Icon(p['archived'] == true ? Icons.unarchive_outlined : Icons.archive_outlined, color: p['archived'] == true ? null : context.palette.danger),
                                onPressed: () => _patch(p, {'archived': p['archived'] != true, if (p['archived'] != true) 'visible': false}, p['archived'] == true ? 'Plan restored' : 'Plan archived'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Durations',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.hourglass_bottom),
                    title: const Text('Trial duration'),
                    subtitle: const Text('Applied to every new account (change in Trial Management)'),
                    trailing: Text('${settings['trialDays']} days', style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () => context.go(AdminRoutes.trials),
                  ),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('Premium duration'),
                    subtitle: Text(plans.isEmpty ? 'Set per plan' : plans.map((p) => '${p['name']} ${p['durationDays']} days').join('  |  ')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.more_time),
                    title: const Text('Premium extension by admin'),
                    subtitle: Text('Default extension ${settings['defaultExtensionDays']} days  |  ${settings['maxExtensions'] == 0 ? 'unlimited' : 'max ${settings['maxExtensions']}'} per user'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Coupons',
              action: 'Add coupon',
              onAction: _addCoupon,
              child: Column(
                children: [
                  for (final c in coupons)
                    ListTile(
                      leading: const Icon(Icons.local_offer_outlined),
                      title: Text('${c['code']}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        [
                          '${c['percentOff']}% off',
                          if ((c['description'] as String?)?.isNotEmpty == true) '${c['description']}',
                          '${c['uses']}${(c['maxUses'] as num) > 0 ? '/${c['maxUses']}' : ''} uses',
                          if (c['expiresAt'] != null) 'expires ${fmtDate(c['expiresAt'])}',
                        ].join('  |  '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip('${c['state']}', tone: c['state'] == 'Active' ? Tone.success : Tone.neutral),
                          Switch(
                            value: c['active'] == true,
                            onChanged: (v) async {
                              final r = await runAction(context, () => AdminApi.patch('/coupons/${c['id']}', {'active': v}), success: v ? 'Coupon active' : 'Coupon paused');
                              if (r != null) _refresh();
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(Icons.delete_outline, color: context.palette.danger),
                            onPressed: () async {
                              if (!await context.confirm(title: 'Delete ${c['code']}?', message: 'The code stops working.', confirmLabel: 'Delete', danger: true)) return;
                              if (!context.mounted) return;
                              final r = await runAction(context, () => AdminApi.delete('/coupons/${c['id']}'), success: 'Coupon deleted');
                              if (r != null) _refresh();
                            },
                          ),
                        ],
                      ),
                    ),
                  if (coupons.isEmpty) const ListTile(title: Text('No coupons yet')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
