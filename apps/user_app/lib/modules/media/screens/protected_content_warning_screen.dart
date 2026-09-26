import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Shown before opening a Private / Highly Protected file.
class ProtectedContentWarningScreen extends StatelessWidget {
  const ProtectedContentWarningScreen({super.key, this.fileId});

  final String? fileId;

  static const _rules = [
    (Icons.file_download_off_outlined, 'Download disabled'),
    (Icons.save_alt, 'Save to device / gallery disabled'),
    (Icons.share_outlined, 'External share disabled'),
    (Icons.open_in_new_off, 'Open with / external app disabled'),
    (Icons.content_copy_outlined, 'Copy file disabled'),
    (Icons.screenshot_outlined, 'Screenshot & screen recording protected'),
    (Icons.water_drop_outlined, 'Your name and masked ID are watermarked'),
    (Icons.history, 'Every view is logged'),
  ];

  @override
  Widget build(BuildContext context) {
    final id = fileId;
    if (id == null) {
      return const Scaffold(body: EmptyState(icon: Icons.shield_outlined, title: 'No file', message: 'Open a protected file from a chat.'));
    }
    return LoginGate(
      title: 'Protected Content',
      child: Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home))),
        body: AsyncView<FileInfoData>(
          load: () => GroupRepository.fileInfo(id),
          builder: (context, f, _) => FormPage(
            items: [
              const MessageBlock(
                icon: Icons.shield_outlined,
                title: 'Protected Content',
                message: 'The sender protected this file. It opens only inside the app secure viewer.',
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: AppAvatar(icon: f.visibility.icon, size: 44, inverted: true),
                  title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  subtitle: Text('${f.visibility.label} (${f.visibility.levelLabel})  |  ${f.groupName}'),
                ),
              ),
              if (f.permissions.viewOnce) ...[
                const SizedBox(height: 12),
                const InfoBanner(icon: Icons.looks_one_outlined, message: 'View once: you can open this file only one time.'),
              ],
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < _rules.length; i++) ...[
                      if (i > 0) const Divider(indent: 56),
                      ListTile(leading: Icon(_rules[i].$1), title: Text(_rules[i].$2)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const InfoBanner(
                icon: Icons.info_outline,
                message: 'On web, screenshots cannot be fully blocked by the browser. The watermark identifies the viewer if content leaks.',
              ),
            ],
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (f.revoked)
                  const InfoBanner(icon: Icons.delete_forever_outlined, message: 'This file is no longer available.')
                else
                  PrimaryButton(
                    label: 'Open in Secure Viewer',
                    icon: Icons.lock_open_outlined,
                    onPressed: () => context.pushReplacement(AppRoutes.secureFileViewerOf(id)),
                  ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home), child: const Text('Cancel')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
