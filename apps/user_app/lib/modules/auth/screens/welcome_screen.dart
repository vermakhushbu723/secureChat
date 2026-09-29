import '../../../core/core.dart';

/// First screen (WhatsApp style): logo, one line, terms, "Agree and continue".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                const Spacer(),
                const AppLogo(size: 180, wide: true),
                const SizedBox(height: 40),
                Text(
                  'Welcome to ${AppStrings.appName}',
                  textAlign: TextAlign.center,
                  style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Text(
                  'Private 1-to-1 and group chats. Your number and email always stay hidden.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textSecondary, height: 1.5),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.5),
                    children: [
                      const TextSpan(text: 'Read our '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.terms),
                          child: const Text('Privacy Policy', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                        ),
                      ),
                      const TextSpan(text: '. Tap "Agree and continue" to accept the '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.terms),
                          child: const Text('Terms of Service', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PrimaryButton(label: 'Agree and continue', onPressed: () => context.go(AppRoutes.login)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
