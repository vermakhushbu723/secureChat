import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../network/api_client.dart';
import '../network/auth_service.dart';
import '../router/app_routes.dart';

/// Server error code when the trial is over (or not claimed) and there is no premium / extension.
const planRequiredCode = 'SUBSCRIPTION_REQUIRED';

/// "Your trial has ended" with Upgrade / Request extension.
Future<void> showPlanRequired(BuildContext context, String message) {
  if (AuthService.instance.user.value?.subscription.canClaimTrial ?? false) return showTrialClaim(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.workspace_premium_outlined, size: 36),
      title: const Text('Premium required'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Not now')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.push(AppRoutes.extensionRequest);
          },
          child: const Text('Request extension'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.push(AppRoutes.plans);
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
}

bool _claimOpen = false;

/// After signup: "Claim your 7 day free trial". Returns true when the trial was claimed.
Future<bool> showTrialClaim(BuildContext context) async {
  if (_claimOpen) return false;
  _claimOpen = true;
  try {
    return await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => const _TrialClaimDialog()) ?? false;
  } finally {
    _claimOpen = false;
  }
}

class _TrialClaimDialog extends StatefulWidget {
  const _TrialClaimDialog();

  @override
  State<_TrialClaimDialog> createState() => _TrialClaimDialogState();
}

class _TrialClaimDialogState extends State<_TrialClaimDialog> {
  bool _claiming = false;
  String? _error;

  static const _benefits = [
    (Icons.forum_outlined, '1-to-1 chats and groups'),
    (Icons.lock_outline, 'Private & Highly Protected messages'),
    (Icons.enhanced_encryption_outlined, 'Secure file viewer'),
    (Icons.location_on_outlined, 'Group location features'),
  ];

  Future<void> _claim() async {
    setState(() {
      _claiming = true;
      _error = null;
    });
    try {
      await AuthService.instance.claimTrial();
      if (!mounted) return;
      Navigator.pop(context, true);
      context.showSnack('Your 7 day free trial is active. Enjoy SecureChat!');
    } on ApiException catch (e) {
      if (e.code == 'TRIAL_ALREADY_CLAIMED') {
        await AuthService.instance.reloadMe().then((_) {}, onError: (Object _) {});
        if (mounted) Navigator.pop(context, true);
        return;
      }
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 84),
              const SizedBox(height: 18),
              Text('Your 7 day free trial', textAlign: TextAlign.center, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Claim it now to start chatting. No payment needed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary),
              ),
              const SizedBox(height: 18),
              for (final b in _benefits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(b.$1, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(b.$2)),
                    ],
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: p.danger)),
              ],
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.all(Radius.circular(24))),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    onPressed: _claiming ? null : _claim,
                    icon: _claiming
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.card_giftcard),
                    label: const Text('Claim free trial'),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(onPressed: _claiming ? null : () => Navigator.pop(context, false), child: const Text('Later')),
            ],
          ),
        ),
      ),
    );
  }
}
