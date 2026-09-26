import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Message / Group / Member reports submitted by the user.
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  static Tone _tone(String status) => switch (status) {
    'resolved' => Tone.success,
    'rejected' => Tone.danger,
    'reviewing' => Tone.warning,
    _ => Tone.neutral,
  };

  static String _title(UserReport r) => switch (r.type) {
    'group' => r.groupName ?? 'Group',
    'user' => r.targetName ?? 'Member',
    _ => r.messagePreview?.isNotEmpty == true ? '"${r.messagePreview}"' : 'Message',
  };

  static String _against(UserReport r) => switch (r.type) {
    'group' => 'Group',
    'user' => [r.targetName ?? 'Member', if (r.groupName != null) 'in ${r.groupName}'].join(' '),
    _ => [if (r.targetName != null) r.targetName!, if (r.groupName != null) 'in ${r.groupName}'].join(' '),
  };

  void _details(BuildContext context, UserReport r) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_title(r), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  StatusChip(r.statusLabel, tone: _tone(r.status)),
                ],
              ),
              const SizedBox(height: 12),
              InfoRow(label: 'Report ID', value: '#${r.id.substring(r.id.length - 8).toUpperCase()}'),
              InfoRow(label: 'Type', value: r.typeLabel),
              InfoRow(label: 'Against', value: _against(r)),
              InfoRow(label: 'Reason', value: r.reasons.join(', ')),
              if (r.details.isNotEmpty) InfoRow(label: 'Details', value: r.details),
              InfoRow(label: 'Submitted', value: r.createdAt == null ? '-' : '${formatListTime(r.createdAt)}, ${formatClock(r.createdAt!)}'),
              if (r.resolution.isNotEmpty) InfoRow(label: 'Outcome', value: r.resolution),
              const SizedBox(height: 8),
              const InfoBanner(message: 'Our moderation team reviews reports within 48 hours. You will be notified of the outcome.'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [('All', null), ('Message', 'message'), ('Group', 'group'), ('Member', 'user')];
    return LoginGate(
      title: 'My Reports',
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My Reports'),
            bottom: TabBar(tabs: [for (final t in tabs) Tab(text: t.$1)]),
          ),
          body: AsyncView<List<UserReport>>(
            load: GroupRepository.myReports,
            builder: (context, all, reload) => TabBarView(
              children: [
                for (final t in tabs)
                  Builder(
                    builder: (context) {
                      final list = all.where((r) => t.$2 == null || r.type == t.$2).toList();
                      if (list.isEmpty) {
                        return const EmptyState(icon: Icons.flag_outlined, title: 'No reports', message: 'You have not reported anything here.');
                      }
                      return RefreshIndicator(
                        onRefresh: reload,
                        child: ResponsiveBody(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const Divider(indent: 72),
                            itemBuilder: (_, i) {
                              final r = list[i];
                              return ListTile(
                                onTap: () => _details(context, r),
                                leading: AppAvatar(
                                  icon: switch (r.type) {
                                    'group' => Icons.groups_outlined,
                                    'user' => Icons.person_outline,
                                    _ => Icons.chat_bubble_outline,
                                  },
                                  size: 44,
                                ),
                                title: Text(_title(r), style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${r.typeLabel} - ${r.reasons.join(', ')}\n${formatListTime(r.createdAt)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                isThreeLine: true,
                                trailing: StatusChip(r.statusLabel, tone: _tone(r.status)),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
