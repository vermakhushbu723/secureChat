import '../../../core/core.dart';

class AdminPlanManagementScreen extends StatelessWidget {
  const AdminPlanManagementScreen({super.key});

  void _edit(BuildContext context, [Plan? plan]) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(plan == null ? 'New plan' : 'Edit ${plan.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Plan name', initialValue: plan?.name),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(label: 'Price', initialValue: plan?.price),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(label: 'Period', initialValue: plan?.period),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Features (one per line)', initialValue: plan?.features.join('\n'), maxLines: 4),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Premium Plans',
      subtitle: 'Create plans and set trial / premium durations',
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('New plan'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 300,
          children: [
            for (final p in MockData.plans)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          if (p.isPopular) const StatusChip('Popular', tone: Tone.dark),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${p.price} / ${p.period}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text('${p.subscribers} subscribers', style: TextStyle(color: context.palette.textSecondary)),
                      const Divider(height: 24),
                      for (final f in p.features)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.check, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Visible to users'),
                          const Spacer(),
                          Switch(value: true, onChanged: (_) {}),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                              onPressed: () => _edit(context, p),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            icon: Icon(Icons.archive_outlined, color: context.palette.danger),
                            onPressed: () {},
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
                subtitle: const Text('Applied to every new account'),
                trailing: Text('${AppStrings.trialDays} days', style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.go(AdminRoutes.trials),
              ),
              const ListTile(
                leading: Icon(Icons.workspace_premium_outlined),
                title: Text('Premium duration'),
                subtitle: Text('Monthly 30 days  |  Yearly 365 days'),
              ),
              const ListTile(
                leading: Icon(Icons.more_time),
                title: Text('Premium extension by admin'),
                subtitle: Text('7 / 30 days or until a date'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Coupons',
          action: 'Add coupon',
          onAction: () {},
          child: const Column(
            children: [
              ListTile(
                leading: Icon(Icons.local_offer_outlined),
                title: Text('WELCOME20'),
                subtitle: Text('20% off first month  |  412 uses'),
                trailing: StatusChip('Active'),
              ),
              ListTile(
                leading: Icon(Icons.local_offer_outlined),
                title: Text('DIWALI50'),
                subtitle: Text('50% off yearly  |  expires 10 Nov'),
                trailing: StatusChip('Pending'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
