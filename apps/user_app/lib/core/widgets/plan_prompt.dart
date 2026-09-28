import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../router/app_routes.dart';

/// Server error code when the trial is over and there is no premium / extension.
const planRequiredCode = 'SUBSCRIPTION_REQUIRED';

/// "Your trial has ended" with Upgrade / Request extension.
Future<void> showPlanRequired(BuildContext context, String message) {
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
