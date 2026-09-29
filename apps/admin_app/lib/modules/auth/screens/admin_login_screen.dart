import '../../../core/core.dart';

/// Admin / staff login with mandatory 2-step verification.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _otpStep = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceAlt,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 96)),
                    const SizedBox(height: 16),
                    Text(
                      '${AppStrings.appName} Admin',
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _otpStep ? 'Enter the 6 digit code from your authenticator' : 'Sign in to the admin panel',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.palette.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (!_otpStep) ...[
                      const AppTextField(label: 'Email', hint: 'admin@securechat.in', prefixIcon: Icons.mail_outline),
                      const SizedBox(height: 16),
                      const AppTextField(label: 'Password', prefixIcon: Icons.lock_outline, obscure: true),
                      const SizedBox(height: 24),
                      PrimaryButton(label: 'Continue', onPressed: () => setState(() => _otpStep = true)),
                    ] else ...[
                      const AppTextField(
                        label: '2-step verification code',
                        hint: '000000',
                        prefixIcon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Verify & Sign in',
                        onPressed: () {
                          AdminSession.loggedIn.value = true;
                          context.go(AdminRoutes.dashboard);
                        },
                      ),
                      TextButton(onPressed: () => setState(() => _otpStep = false), child: const Text('Back')),
                    ],
                    const SizedBox(height: 16),
                    const InfoBanner(
                      icon: Icons.policy_outlined,
                      message:
                          'Every admin action, including viewing user data or locations, is recorded in the audit log.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
