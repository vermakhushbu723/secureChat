import '../../../core/core.dart';
import '../data/subscription_repository.dart';

/// Premium plans from the admin panel (Premium Plans) -> checkout with the admin's UPI ID / QR.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Plans',
      child: Scaffold(
        appBar: AppBar(title: const Text('Choose a Plan')),
        body: AsyncView<(List<PremiumPlan>, PlanDetails)>(
          load: () async => (await SubscriptionRepository.plans(), await SubscriptionRepository.status()),
          builder: (context, d, _) {
            final (plans, me) = d;
            return ResponsiveBody(
              maxWidth: 1000,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Upgrade for secure, unlimited communication',
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    me.access == 'trial'
                        ? 'Your free trial has ${me.daysLeft} day${me.daysLeft == 1 ? '' : 's'} left'
                        : me.locked
                        ? 'Your free trial has ended - choose a plan to keep chatting'
                        : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: me.locked ? context.palette.danger : context.palette.textSecondary),
                  ),
                  if (me.pending?.payment != null) ...[
                    const SizedBox(height: 12),
                    InfoBanner(
                      icon: Icons.hourglass_top,
                      tone: Tone.warning,
                      title: 'Payment waiting for confirmation',
                      message: '${me.pending!.payment!.planName} - ${me.pending!.payment!.amountLabel}, UTR ${me.pending!.payment!.utr}. Premium starts as soon as the admin confirms it.',
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (plans.isEmpty)
                    const EmptyState(icon: Icons.workspace_premium_outlined, title: 'No plans yet', message: 'Premium plans will appear here soon.')
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final p in plans)
                          SizedBox(
                            width: 300,
                            child: _PlanCard(plan: p, onChoose: () => context.push(AppRoutes.checkoutOf(p.id))),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(onPressed: () => context.push(AppRoutes.subscriptionStatus), icon: const Icon(Icons.receipt_long_outlined), label: const Text('View my subscription')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onChoose});

  final PremiumPlan plan;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final hi = plan.popular;
    final fg = hi ? context.colors.onPrimary : context.colors.onSurface;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hi ? context.colors.primary : context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hi ? context.colors.primary : context.palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              if (hi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: context.colors.onPrimary, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Popular',
                    style: TextStyle(color: context.colors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: plan.priceLabel,
                  style: TextStyle(color: fg, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: ' / ${plan.periodLabel}',
                  style: TextStyle(color: fg.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final f in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: TextStyle(color: fg)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: hi
                ? FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: context.colors.onPrimary, foregroundColor: context.colors.primary),
                    onPressed: onChoose,
                    child: Text('Choose ${plan.name}'),
                  )
                : OutlinedButton(onPressed: onChoose, child: Text('Choose ${plan.name}')),
          ),
        ],
      ),
    );
  }
}
