import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/widgets/media_viewers.dart' show openExternal;
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Public document of a group message. Protected documents use the secure viewer.
class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({super.key, this.messageId});

  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final id = messageId;
    if (id == null) return const Scaffold(body: EmptyState(icon: Icons.description_outlined, title: 'No document', message: 'Open a document from a chat.'));
    return LoginGate(
      title: 'Document',
      child: AsyncView<GroupMessage>(load: () => GroupRepository.message(id), builder: (context, m, _) => _Doc(m: m)),
    );
  }
}

class _Doc extends StatelessWidget {
  const _Doc({required this.m});

  final GroupMessage m;

  @override
  Widget build(BuildContext context) {
    final media = m.media;
    if (media?.secure == true && media?.fileId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pushReplacement(AppRoutes.secureFileViewerOf(media!.fileId!)));
    }
    final name = media?.name ?? 'Document';
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';
    return Scaffold(
      backgroundColor: context.palette.surfaceAlt,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
            Text('${formatBytes(media?.size ?? 0)}  |  ${m.senderName}  |  ${m.visibility.label}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          if (m.permissions.canForward)
            IconButton(icon: const Icon(Icons.shortcut), tooltip: 'Forward', onPressed: () => context.push(AppRoutes.forwardSelectionOf(m.groupId, preselect: m.id))),
          IconButton(icon: const Icon(Icons.info_outline), tooltip: 'Message info', onPressed: () => context.push(AppRoutes.messageInfoOf(m.groupId, m.id))),
        ],
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 140,
                height: 180,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(ext == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.description_outlined, size: 56, color: context.colors.primary),
                    const SizedBox(height: 8),
                    Text(ext, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (m.text.isNotEmpty) ...[const SizedBox(height: 6), Text(m.text, textAlign: TextAlign.center)],
            const SizedBox(height: 20),
            GroupedCard(
              children: [
                InfoRow(label: 'Type', value: media?.mimeType ?? ext, icon: Icons.category_outlined),
                InfoRow(label: 'Size', value: formatBytes(media?.size ?? 0), icon: Icons.sd_storage_outlined),
                InfoRow(label: 'Shared by', value: m.isMine ? 'You' : m.senderName, icon: Icons.person_outline),
                InfoRow(label: 'Shared', value: '${formatListTime(m.createdAt)}, ${formatClock(m.createdAt)}', icon: Icons.schedule),
                InfoRow(label: 'Privacy', value: '${m.visibility.label} (${m.visibility.levelLabel})', icon: m.visibility.icon),
              ],
            ),
            const SizedBox(height: 20),
            if (m.permissions.allowDownload && media?.fullUrl != null)
              PrimaryButton(label: 'Open / Download', icon: Icons.download_outlined, onPressed: () => openExternal(context, media!.fullUrl!))
            else
              const InfoBanner(icon: Icons.file_download_off_outlined, message: 'The sender turned off downloads for this document.'),
          ],
        ),
      ),
    );
  }
}
