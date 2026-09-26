import '../../../core/core.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.planId});

  final String planId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _method = 'upi';
  bool _paying = false;

  static const _methods = [
    ('upi', Icons.qr_code_2, 'UPI', 'Google Pay, PhonePe, Paytm'),
    ('card', Icons.credit_card, 'Credit / Debit Card', 'Visa, Mastercard, RuPay'),
    ('netbanking', Icons.account_balance_outlined, 'Net Banking', 'All major banks'),
    ('wallet', Icons.account_balance_wallet_outlined, 'Wallet', 'Paytm, Amazon Pay'),
  ];

  @override
  Widget build(BuildContext context) {
    final plan = MockData.planById(widget.planId);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: FormPage(
        items: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppAvatar(icon: Icons.workspace_premium_outlined, inverted: true, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${plan.name} Plan',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            Text('Billed every ${plan.period}', style: TextStyle(color: context.palette.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: () => context.pop(), child: const Text('Change')),
                    ],
                  ),
                  const Divider(height: 28),
                  InfoRow(label: 'Plan price', value: plan.price),
                  const InfoRow(label: 'GST (18%)', value: 'Included'),
                  const InfoRow(label: 'Discount', value: '- Rs 0'),
                  const Divider(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        Text(plan.price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            hint: 'Coupon code',
            prefixIcon: Icons.local_offer_outlined,
            suffix: TextButton(onPressed: () => context.showSnack('Invalid coupon'), child: const Text('Apply')),
          ),
          const SectionHeader('Payment method', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: RadioGroup<String>(
              groupValue: _method,
              onChanged: (v) => setState(() => _method = v!),
              child: Column(
                children: [
                  for (var i = 0; i < _methods.length; i++) ...[
                    if (i > 0) const Divider(indent: 56),
                    RadioListTile<String>(
                      value: _methods[i].$1,
                      secondary: Icon(_methods[i].$2),
                      title: Text(_methods[i].$3, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_methods[i].$4),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: context.palette.textSecondary),
              const SizedBox(width: 6),
              Text('100% secure payment', style: TextStyle(color: context.palette.textSecondary, fontSize: 12)),
            ],
          ),
        ],
        bottom: PrimaryButton(
          label: 'Pay ${plan.price}',
          loading: _paying,
          onPressed: () async {
            setState(() => _paying = true);
            await Future<void>.delayed(const Duration(seconds: 1));
            if (!context.mounted) return;
            context.showSnack('Payment successful');
            context.pushReplacement(AppRoutes.subscriptionStatus);
          },
        ),
      ),
    );
  }
}
