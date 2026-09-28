import '../../../core/core.dart';
import '../../direct/data/direct_models.dart' show formatListTime;
import '../data/subscription_repository.dart';

/// My plan: 7 day free trial -> premium / admin extension -> locked.
class TrialStatusScreen extends StatelessWidget {
  const TrialStatusScreen({super.key});

  static const _features = [
    '1-to-1 chats and groups',
    'Public, Private & Highly Protected messages',
    'Secure file viewer',
    'Group location features',
  ];

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'My plan',
      child: Scaffold(
        appBar: AppBar(title: const Text('My plan')),
        body: AsyncView<PlanDetails>(load: SubscriptionRepository.status, builder: (context, plan, reload) => _body(context, plan, reload)),
      ),
    );
  }

  Widget _body(BuildContext context, PlanDetails plan, Future<void> Function() reload) {
    final p = context.palette;
    final total = plan.access == 'trial' ? plan.trialDays : (plan.daysLeft == 0 ? 1 : plan.daysLeft);
    final title = switch (plan.access) {
      'premium' => 'Premium',
      'extended' => 'Extended by admin',
      'trial' => 'Free trial',
      _ => 'Trial ended',
    };
    final color = plan.locked ? p.danger : AppColors.primary;
    return RefreshIndicator(
      onRefresh: reload,
      child: FormPage(
        items: [
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: plan.locked ? 1 : (plan.daysLeft / total).clamp(0, 1).toDouble(),
                    strokeWidth: 12,
                    color: color,
                    backgroundColor: p.surfaceAlt,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (plan.locked)
                          Icon(Icons.lock_clock_outlined, size: 48, color: color)
                        else
                          Text('${plan.daysLeft}', style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800)),
                        Text(plan.locked ? 'locked' : 'days left'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            plan.locked
                ? 'You can still read messages. To send messages and open protected files, upgrade or request an extension. '
                      'In premium groups the creator can let you reply without your own plan.'
                : '${plan.access == 'trial' ? 'Trial ends' : 'Valid until'} ${plan.until == null ? '-' : formatListTime(plan.until)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          if (plan.pending != null) ...[
            const SizedBox(height: 16),
            InfoBanner(
              icon: Icons.hourglass_top,
              tone: Tone.success,
              title: 'Request sent',
              message: 'Your ${plan.pending!.kind} request (${plan.pending!.days} days) is waiting for admin approval.',
            ),
          ],
          const SectionHeader('Included', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          for (final f in _features)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(plan.locked ? Icons.lock_outline : Icons.check_circle_outline, color: plan.locked ? p.textMuted : AppColors.primary),
              title: Text(f),
            ),
          if (plan.requests.isNotEmpty) ...[
            const SectionHeader('Requests', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            for (final r in plan.requests)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text('${r.kind == 'premium' ? 'Premium' : 'Extension'} - ${r.days} days'),
                subtitle: Text(r.createdAt == null ? '' : formatListTime(r.createdAt)),
                trailing: StatusChip(
                  r.status[0].toUpperCase() + r.status.substring(1),
                  tone: r.status == 'approved' ? Tone.success : r.status == 'rejected' ? Tone.danger : Tone.warning,
                ),
              ),
          ],
        ],
        bottom: plan.access == 'premium'
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(label: 'View plans', icon: Icons.workspace_premium_outlined, onPressed: () => context.push(AppRoutes.plans)),
                  if (plan.pending == null) ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => context.push(AppRoutes.extensionRequest), child: const Text('Request extension')),
                  ],
                ],
              ),
      ),
    );
  }
}
