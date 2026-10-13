import 'package:file_picker/file_picker.dart';

import '../../../core/core.dart';

/// Payments (UPI): the UPI ID, payee name and QR code shown on the app's checkout, and the
/// payments users sent (plan, amount, UTR) waiting for the admin to check and approve.
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  int _reload = 0;
  String _status = 'pending';

  void _refresh() => setState(() => _reload++);

  static final _upi = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z][a-zA-Z0-9.\-]{1,64}$');

  Future<void> _editSettings(Map<String, dynamic> s) async {
    final upi = TextEditingController(text: '${s['upiId'] ?? ''}');
    final name = TextEditingController(text: '${s['payeeName'] ?? 'SecureChat'}');
    final note = TextEditingController(text: '${s['instructions'] ?? ''}');
    final body = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final valid = _upi.hasMatch(upi.text.trim());
          return AlertDialog(
            title: const Text('Edit UPI details'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: upi,
                    onChanged: (_) => setD(() {}),
                    decoration: InputDecoration(
                      labelText: 'UPI ID',
                      hintText: 'name@upi',
                      prefixIcon: const Icon(Icons.alternate_email),
                      errorText: upi.text.trim().isEmpty || valid ? null : 'Enter a valid UPI ID, e.g. name@upi',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Payee name (shown in the UPI app)', controller: name),
                  const SizedBox(height: 12),
                  TextField(controller: note, maxLines: 3, maxLength: 400, decoration: const InputDecoration(labelText: 'Instructions shown on checkout')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: valid ? () => Navigator.pop(ctx, {'upiId': upi.text.trim(), 'payeeName': name.text.trim().isEmpty ? 'SecureChat' : name.text.trim(), 'instructions': note.text.trim()}) : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    for (final c in [upi, name, note]) {
      c.dispose();
    }
    if (body == null || !mounted) return;
    final r = await runAction(context, () => AdminApi.put('/settings/payment', body), success: 'UPI details saved - the app shows them on checkout');
    if (r != null) _refresh();
  }

  Future<void> _uploadQr() async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp']);
    if (picked.isEmpty || !mounted) return;
    final f = picked.first;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    final ext = f.name.split('.').last.toLowerCase();
    final type = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
    final r = await runAction(context, () => AdminApi.upload('/settings/payment/qr', bytes, f.name, contentType: type), success: 'QR code uploaded');
    if (r != null) _refresh();
  }

  Future<void> _removeQr() async {
    if (!await context.confirm(title: 'Remove the QR code?', message: 'The app then shows a QR made from the UPI ID.', confirmLabel: 'Remove', danger: true)) return;
    if (!mounted) return;
    final r = await runAction(context, () => AdminApi.delete('/settings/payment/qr'), success: 'QR code removed');
    if (r != null) _refresh();
  }

  Future<void> _decide(Map<String, dynamic> r, bool approve) async {
    final p = r['payment'] as Map<String, dynamic>;
    final ok = await context.confirm(
      title: approve ? 'Approve payment?' : 'Reject payment?',
      message: approve
          ? 'Check that ${fmtMoney(p['amount'], p['currency'])} with UTR ${p['utr']} reached ${p['payTo']}. ${r['user']['name']} gets ${p['planName']} premium for ${r['days']} days.'
          : 'The user is told the payment could not be confirmed and can send it again.',
      confirmLabel: approve ? 'Approve & activate' : 'Reject',
      danger: !approve,
    );
    if (!ok || !mounted) return;
    final res = await runAction(context, () => AdminApi.post('/requests/${r['id']}', {'approve': approve, 'as': 'premium'}), success: approve ? 'Premium activated for ${r['user']['name']}' : 'Payment rejected');
    if (res != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<List<dynamic>>(
      reloadKey: '$_reload|$_status',
      load: () async => [
        await AdminApi.get<Map<String, dynamic>>('/settings/payment'),
        await AdminApi.get<Map<String, dynamic>>('/requests', {'status': _status, 'limit': 100}),
      ],
      builder: (context, data, _) {
        final s = data[0] as Map<String, dynamic>;
        final all = ((data[1] as Map)['items'] as List).cast<Map<String, dynamic>>();
        final rows = all.where((r) => r['payment'] != null).toList();
        final qr = s['qrImageUrl'] as String?;
        final enabled = s['enabled'] != false;
        return AdminPage(
          title: 'Payments (UPI)',
          subtitle: 'UPI ID and QR shown when a user upgrades - approve each payment after checking the UTR',
          onRefresh: _refresh,
          actions: [FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => _editSettings(s), icon: const Icon(Icons.edit_outlined), label: const Text('Edit UPI ID'))],
          children: [
            ResponsiveGrid(
              minItemWidth: 360,
              children: [
                PanelCard(
                  title: 'UPI details',
                  child: Column(
                    children: [
                      SettingSwitch(
                        icon: Icons.payments_outlined,
                        title: 'Accept UPI payments',
                        subtitle: enabled ? 'Checkout shows the UPI ID and QR' : 'Checkout says payments are not available',
                        value: enabled,
                        onChanged: (v) async {
                          final r = await runAction(context, () => AdminApi.put('/settings/payment', {'enabled': v}), success: v ? 'UPI payments on' : 'UPI payments off');
                          if (r != null) _refresh();
                        },
                      ),
                      InfoRow(label: 'UPI ID', value: '${s['upiId'] ?? '-'}', icon: Icons.alternate_email),
                      InfoRow(label: 'Payee name', value: '${s['payeeName'] ?? 'SecureChat'}', icon: Icons.badge_outlined),
                      InfoRow(label: 'Instructions', value: '${s['instructions'] ?? '-'}', icon: Icons.info_outline),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(onPressed: () => _editSettings(s), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                      ),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'QR code',
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(border: Border.all(color: context.palette.divider), borderRadius: BorderRadius.circular(12)),
                        child: qr == null
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('No QR uploaded.\nThe app shows a QR made from the UPI ID (with the plan amount).', textAlign: TextAlign.center, style: TextStyle(color: context.palette.textSecondary)),
                              )
                            : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network('${AdminApi.baseUrl}$qr', fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined))),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.icon(onPressed: _uploadQr, icon: const Icon(Icons.upload_outlined), label: Text(qr == null ? 'Upload QR' : 'Change QR')),
                          if (qr != null) OutlinedButton.icon(onPressed: _removeQr, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              showSearch: false,
              filters: const {'Waiting': 'pending', 'Approved': 'approved', 'Rejected': 'rejected', 'All': 'all'},
              selected: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            AdminTable(
              columns: const ['User', 'Plan', 'Amount', 'UTR / transaction ID', 'Paid to', 'Sent', 'Status', ''],
              emptyText: 'No payments',
              rows: [
                for (final r in rows)
                  [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${r['user']['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${r['user']['phone'] ?? r['user']['email'] ?? ''}', style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
                      ],
                    ),
                    Text('${r['payment']['planName']}  (${r['days']} days)'),
                    Text(fmtMoney(r['payment']['amount'], r['payment']['currency']), style: const TextStyle(fontWeight: FontWeight.w600)),
                    SelectableText('${r['payment']['utr']}', style: const TextStyle(fontFamily: 'monospace')),
                    Text('${r['payment']['payTo'] ?? '-'}'),
                    Text(fmtAgo(r['createdAt'])),
                    StatusChip(capitalize('${r['status']}'), tone: r['status'] == 'approved' ? Tone.success : r['status'] == 'rejected' ? Tone.danger : Tone.warning),
                    r['status'] == 'pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton(onPressed: () => _decide(r, true), child: const Text('Approve')),
                              const SizedBox(width: 6),
                              TextButton(onPressed: () => _decide(r, false), child: const Text('Reject')),
                            ],
                          )
                        : Text('${r['decidedBy'] ?? ''}', style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
