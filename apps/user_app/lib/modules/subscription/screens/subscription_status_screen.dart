import '../../../core/core.dart';
import '../../direct/data/direct_models.dart' show formatDayHeader;
import '../data/subscription_repository.dart';

/// My Subscription: current access (trial / premium / extended / locked), payments sent by UPI
/// and extension requests, all from the server.
class SubscriptionStatusScreen extends StatelessWidget {
  const SubscriptionStatusScreen({super.key});

  static String _title(String access) => switch (access) {
    'premium' => 'Premium',
    'extended' => 'Trial extended',
    'trial' => 'Free trial',
    'free' => 'Free access',
    _ => 'Trial ended',
  };

  static String _date(DateTime? d) => d == null ? '-' : formatDayHeader(d);

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'My Subscription',
      child: Scaffold(
        appBar: AppBar(title: const Text('My Subscription')),
        body: AsyncView<PlanDetails>(
          load: SubscriptionRepository.status,
          builder: (context, p, reload) {
            final active = !p.locked;
            final ends = p.access == 'trial' ? p.trialEndsAt : p.until;
            return ResponsiveBody(
              child: RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: active ? context.colors.primary : context.palette.danger, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(active ? Icons.workspace_premium : Icons.lock_clock, color: Colors.white, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _title(p.access),
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                              ),
                              StatusChip(active ? 'Active' : 'Locked'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            active ? (ends == null ? 'No end date' : '${p.daysLeft} day${p.daysLeft == 1 ? '' : 's'} left  |  until ${_date(ends)}') : 'Chat is read only. Upgrade to keep chatting.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (p.pending?.payment != null)
                      InfoBanner(
                        icon: Icons.hourglass_top,
                        tone: Tone.warning,
                        title: 'Payment waiting for confirmation',
                        message: '${p.pending!.payment!.planName} - ${p.pending!.payment!.amountLabel}, UTR ${p.pending!.payment!.utr}. Premium starts as soon as the admin confirms it.',
                      )
                    else
                      PrimaryButton(label: p.access == 'premium' ? 'Renew / change plan' : 'Upgrade to premium', onPressed: () => context.push(AppRoutes.plans)),
                    const SectionHeader('Payments & requests', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
                    if (p.requests.isEmpty)
                      const Card(
                        child: ListTile(leading: Icon(Icons.receipt_long_outlined), title: Text('No payments yet')),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < p.requests.length; i++) ...[if (i > 0) const Divider(indent: 56), _RequestTile(r: p.requests[i])],
                          ],
                        ),
                      ),
                    const SectionHeader('Manage', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
                    Card(
                      child: Column(
                        children: [
                          AppTile(icon: Icons.swap_horiz, title: 'Plans', onTap: () => context.push(AppRoutes.plans)),
                          const Divider(indent: 56),
                          AppTile(icon: Icons.hourglass_bottom, title: 'Trial details', onTap: () => context.push(AppRoutes.trialStatus)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.r});

  final PlanRequest r;

  @override
  Widget build(BuildContext context) {
    final pay = r.payment;
    final status = switch (r.status) {
      'approved' => pay != null ? 'Paid' : 'Approved',
      'rejected' => 'Rejected',
      _ => 'Waiting',
    };
    final tone = switch (r.status) {
      'approved' => Tone.success,
      'rejected' => Tone.danger,
      _ => Tone.warning,
    };
    final when = r.createdAt == null ? '' : formatDayHeader(r.createdAt!);
    return ListTile(
      leading: Icon(pay != null ? Icons.qr_code_2 : Icons.more_time),
      title: Text(
        pay != null ? '${pay.planName} - ${pay.amountLabel}' : '${r.kind == 'premium' ? 'Premium' : 'Extension'} request - ${r.days} days',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(pay != null ? '$when  |  UTR ${pay.utr}' : when),
      trailing: StatusChip(status, tone: tone),
    );
  }
}
