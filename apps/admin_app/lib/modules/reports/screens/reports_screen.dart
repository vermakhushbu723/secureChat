import '../../../core/core.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  void _review(BuildContext context, ReportItem r) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(r.title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoRow(label: 'Type', value: r.type),
              InfoRow(label: 'Reported by', value: r.reportedBy),
              InfoRow(label: 'Against', value: r.target),
              InfoRow(label: 'Reason', value: r.reason),
              InfoRow(label: 'Date', value: r.date),
              const SizedBox(height: 12),
              const AppTextField(hint: 'Resolution note', maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Reject')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Warn user')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = MockData.reports;
    return AdminPage(
      title: 'Reports',
      subtitle: 'Message, group and user reports from the community',
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: const [
            StatCard(icon: Icons.inbox_outlined, label: 'Pending', value: '37'),
            StatCard(icon: Icons.visibility_outlined, label: 'Under review', value: '12'),
            StatCard(icon: Icons.check_circle_outline, label: 'Resolved (30d)', value: '418'),
            StatCard(icon: Icons.cancel_outlined, label: 'Rejected (30d)', value: '96'),
          ],
        ),
        const SizedBox(height: 16),
        const AdminFilterBar(hint: 'Search reports', filters: ['All', 'Message', 'Group', 'User', 'Pending']),
        AdminTable(
          columns: const ['ID', 'Title', 'Type', 'Reported by', 'Against', 'Date', 'Status'],
          onRowTap: (i) => _review(context, reports[i]),
          rows: [
            for (final r in reports)
              [
                Text('#${r.id.toUpperCase()}'),
                Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(r.type),
                Text(r.reportedBy),
                Text(r.target),
                Text(r.date),
                StatusChip(r.status),
              ],
          ],
        ),
      ],
    );
  }
}
