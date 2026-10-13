import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../data/subscription_repository.dart';

/// UPI checkout: the plan, the admin's UPI ID / QR (admin panel -> Payments), "Pay with UPI
/// app", then the UTR / transaction ID. Premium starts when the admin confirms the payment.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Checkout',
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: AsyncView<(PremiumPlan?, PaymentInfo, PlanDetails)>(
          load: () async {
            final plans = await SubscriptionRepository.plans();
            return (plans.where((p) => p.id == planId).firstOrNull, await SubscriptionRepository.paymentInfo(), await SubscriptionRepository.status());
          },
          builder: (context, d, reload) {
            final (plan, pay, me) = d;
            if (plan == null) {
              return EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: 'Plan not available',
                message: 'Choose another plan.',
                action: TextButton(onPressed: () => context.pop(), child: const Text('Back to plans')),
              );
            }
            return _Checkout(plan: plan, pay: pay, pending: me.pending);
          },
        ),
      ),
    );
  }
}

class _Checkout extends StatefulWidget {
  const _Checkout({required this.plan, required this.pay, this.pending});

  final PremiumPlan plan;
  final PaymentInfo pay;
  final PlanRequest? pending;

  @override
  State<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<_Checkout> {
  final _utr = TextEditingController();
  bool _sending = false;

  static final _utrPattern = RegExp(r'^[A-Za-z0-9]{6,30}$');

  @override
  void initState() {
    super.initState();
    _utr.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  bool get _canPayInApp => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _openUpiApp(String link) async {
    final ok = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) context.showSnack('No UPI app found. Scan the QR or pay to the UPI ID from another phone.');
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await SubscriptionRepository.submitPayment(widget.plan.id, _utr.text.trim());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40),
          title: const Text('Payment sent for confirmation'),
          content: Text('We received your UTR ${_utr.text.trim().toUpperCase()}. ${widget.plan.name} premium starts as soon as the admin confirms the payment.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      if (mounted) context.pushReplacement(AppRoutes.subscriptionStatus);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final pay = widget.pay;
    final link = pay.upiLink(plan);
    final waiting = widget.pending?.payment;
    return FormPage(
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
                          Text('${plan.name} Plan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          Text('${plan.durationDays} days of premium', style: TextStyle(color: context.palette.textSecondary)),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => context.pop(), child: const Text('Change')),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Total to pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    Text(plan.priceLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (waiting != null)
          InfoBanner(
            icon: Icons.hourglass_top,
            tone: Tone.warning,
            title: 'Payment waiting for confirmation',
            message: '${waiting.planName} - ${waiting.amountLabel}, UTR ${waiting.utr}. You can send a new payment after the admin decides.',
          )
        else if (!pay.enabled)
          const InfoBanner(icon: Icons.info_outline, tone: Tone.warning, title: 'Payments are not available right now', message: 'Please try again later or contact support.')
        else ...[
          const SectionHeader('1. Pay with UPI', padding: EdgeInsets.fromLTRB(0, 4, 0, 8)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.palette.divider),
                    ),
                    child: pay.qrImageUrl != null
                        ? Image.network(ApiConfig.mediaUrl(pay.qrImageUrl!), width: 220, height: 220, fit: BoxFit.contain)
                        : link == null
                        ? const SizedBox(width: 220, height: 220)
                        : QrImageView(data: link, size: 220, backgroundColor: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pay.qrImageUrl != null ? 'Scan with any UPI app and pay ${plan.priceLabel}' : 'Scan with any UPI app - amount ${plan.priceLabel} is filled in',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
                  ),
                  if (pay.upiId != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.alternate_email),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('UPI ID', style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
                              SelectableText(pay.upiId!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              Text(pay.payeeName, style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: pay.upiId!));
                            if (context.mounted) context.showSnack('UPI ID copied');
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                  if (_canPayInApp && link != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(onPressed: () => _openUpiApp(link), icon: const Icon(Icons.open_in_new), label: Text('Pay ${plan.priceLabel} with UPI app')),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (pay.instructions.isNotEmpty) ...[const SizedBox(height: 8), Text(pay.instructions, style: TextStyle(color: context.palette.textSecondary, fontSize: 12))],
          const SectionHeader('2. Enter the UTR / transaction ID', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          TextField(
            controller: _utr,
            keyboardType: TextInputType.visiblePassword,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')), LengthLimitingTextInputFormatter(30)],
            decoration: InputDecoration(
              hintText: 'e.g. 412345678901',
              prefixIcon: const Icon(Icons.receipt_long_outlined),
              errorText: _utr.text.isEmpty || _utrPattern.hasMatch(_utr.text) ? null : 'At least 6 letters or digits',
            ),
          ),
          const SizedBox(height: 6),
          Text('Find it in your UPI app under the payment details (UPI Ref No. / UTR, usually 12 digits).', style: TextStyle(color: context.palette.textSecondary, fontSize: 12)),
        ],
      ],
      bottom: waiting != null || !pay.enabled
          ? PrimaryButton(label: 'View my subscription', onPressed: () => context.pushReplacement(AppRoutes.subscriptionStatus))
          : PrimaryButton(label: 'I have paid - send for confirmation', loading: _sending, onPressed: _sending || !_utrPattern.hasMatch(_utr.text.trim()) ? null : _submit),
    );
  }
}
