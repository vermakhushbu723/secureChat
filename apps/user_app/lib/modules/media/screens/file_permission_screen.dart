import '../../../core/core.dart';
import 'secure_file_viewer_screen.dart' show showSecureFile;
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Who can view a protected file, access expiry, protection flags and the access log.
class FilePermissionScreen extends StatelessWidget {
  const FilePermissionScreen({super.key, this.fileId});

  final String? fileId;

  @override
  Widget build(BuildContext context) {
    final id = fileId;
    if (id == null) {
      return const Scaffold(body: EmptyState(icon: Icons.admin_panel_settings_outlined, title: 'No file', message: 'Open file permissions from a protected file.'));
    }
    return LoginGate(
      title: 'File Permissions',
      child: AsyncView<FileInfoData>(load: () => GroupRepository.fileInfo(id), builder: (context, f, _) => _Editor(info: f)),
    );
  }
}

class _Editor extends StatefulWidget {
  const _Editor({required this.info});

  final FileInfoData info;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late FileInfoData _f = widget.info;
  late String _viewer = _f.permissions.whoCanView == 'admins' ? 'admins' : 'members';
  String? _expiry;
  late bool _download = _f.permissions.allowDownload;
  late bool _share = _f.permissions.allowShare;
  late bool _print = _f.permissions.allowPrint;
  late Future<List<AccessLogEntry>> _log = _loadLog();
  bool _saving = false;

  Future<List<AccessLogEntry>> _loadLog() => _f.canManage ? GroupRepository.accessLog(_f.fileId) : Future.value(const []);

  bool get _public => _f.visibility == MessageVisibility.public;

  String get _expiryLabel {
    final at = _f.permissions.accessExpiresAt;
    if (at == null) return 'Never';
    return at.isBefore(DateTime.now()) ? 'Expired' : '${formatListTime(at)}, ${formatClock(at)}';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await GroupRepository.updateFilePermissions(_f.fileId, {
        'whoCanView': _viewer,
        'accessExpiry': ?_expiry,
        if (_public) ...{'allowDownload': _download, 'allowShare': _share, 'allowPrint': _print},
      });
      if (!mounted) return;
      setState(() {
        _f = updated;
        _expiry = null;
        _log = _loadLog();
      });
      context.showSnack('File permissions updated');
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _f;
    // 1-to-1 files have fixed protection (no group permissions to change).
    final manage = f.canManage && !f.revoked && !f.direct;
    return Scaffold(
      appBar: AppBar(title: const Text('File Permissions')),
      body: FormPage(
        items: [
          Card(
            child: ListTile(
              leading: AppAvatar(icon: f.kind == 'image' ? Icons.image_outlined : f.kind == 'video' ? Icons.videocam_outlined : Icons.description_outlined, size: 44, inverted: true),
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              subtitle: Text('${formatBytes(f.size)}  |  ${f.visibility.label} (${f.visibility.levelLabel})  |  ${f.groupName}'),
              trailing: f.revoked
                  ? const StatusChip('Revoked', tone: Tone.danger)
                  : IconButton(icon: const Icon(Icons.visibility_outlined), tooltip: 'Open', onPressed: () => showSecureFile(context, f.fileId)),
            ),
          ),
          if (!f.canManage) ...[
            const SizedBox(height: 12),
            const InfoBanner(icon: Icons.lock_outline, message: 'Only the sender or group admins can change these permissions.'),
          ],
          const SectionHeader('Access', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('Who can view'),
                  trailing: DropdownButton<String>(
                    value: _viewer,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'members', child: Text('Group members')),
                      DropdownMenuItem(value: 'admins', child: Text('Admins only')),
                    ],
                    onChanged: manage ? (v) => setState(() => _viewer = v!) : null,
                  ),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Access expires'),
                  subtitle: Text('Current: $_expiryLabel'),
                  trailing: DropdownButton<String>(
                    value: _expiry,
                    hint: const Text('Change'),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '1h', child: Text('1 hour')),
                      DropdownMenuItem(value: '24h', child: Text('24 hours')),
                      DropdownMenuItem(value: '7d', child: Text('7 days')),
                      DropdownMenuItem(value: 'never', child: Text('Never')),
                    ],
                    onChanged: manage ? (v) => setState(() => _expiry = v) : null,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Protection', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.enhanced_encryption_outlined),
                  title: const Text('Protected file'),
                  subtitle: Text(_public ? 'Public file - normal viewer' : 'Encrypted, opens only in secure viewer'),
                  value: !_public,
                  onChanged: null,
                ),
                const Divider(indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.download_outlined),
                  title: const Text('Allow download'),
                  subtitle: _public ? null : const Text('Never for Level 2 / 3'),
                  value: _download,
                  onChanged: manage && _public ? (v) => setState(() => _download = v) : null,
                ),
                const Divider(indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.ios_share),
                  title: const Text('Allow external share'),
                  value: _share,
                  onChanged: manage && _public ? (v) => setState(() => _share = v) : null,
                ),
                const Divider(indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.print_outlined),
                  title: const Text('Allow print'),
                  value: _print,
                  onChanged: manage && _public ? (v) => setState(() => _print = v) : null,
                ),
                const Divider(indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.link_off),
                  title: const Text('Public file URL'),
                  subtitle: Text(_public ? 'Media URL' : 'Never - access only via secure token'),
                  value: _public,
                  onChanged: null,
                ),
                const Divider(indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.water_drop_outlined),
                  title: const Text('Watermark with viewer ID'),
                  subtitle: const Text('Set by privacy level and group security'),
                  value: f.permissions.watermark,
                  onChanged: null,
                ),
              ],
            ),
          ),
          if (f.canManage) ...[
            const SectionHeader('Access log', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            FutureBuilder<List<AccessLogEntry>>(
              future: _log,
              builder: (context, snap) {
                if (!snap.hasData) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())));
                final log = snap.data!;
                if (log.isEmpty) return const Card(child: ListTile(title: Text('No activity yet')));
                return Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < log.length; i++) ...[
                        if (i > 0) const Divider(indent: 16),
                        ListTile(
                          dense: true,
                          title: Text(log[i].displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(log[i].label),
                          trailing: Text(log[i].at == null ? '' : '${formatListTime(log[i].at)}\n${formatClock(log[i].at!)}', textAlign: TextAlign.end),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
        bottom: manage ? PrimaryButton(label: 'Save', loading: _saving, onPressed: _saving ? null : _save) : null,
      ),
    );
  }
}
