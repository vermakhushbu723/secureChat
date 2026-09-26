import '../../../core/core.dart';

/// Login / signup in one step: a single field for the mobile number or email ID,
/// then a 6 digit code. New accounts continue to the Personal / Business step.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.from});

  /// Location to continue to after login (e.g. an invite link).
  final String? from;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  bool _loading = false;

  bool get _isEmail => _identifier.text.contains('@');

  @override
  void initState() {
    super.initState();
    _identifier.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final id = _identifier.text.trim();
    if (id.isEmpty) return context.showSnack('Enter your mobile number or email ID');
    setState(() => _loading = true);
    try {
      final res = await AuthService.instance.requestOtp(id);
      if (!mounted) return;
      context.push(AppRoutes.otpFor(identifier: res.sentTo, from: widget.from, devCode: res.devCode));
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: context.canPop()),
      body: FormPage(
        items: [
          const SizedBox(height: 8),
          Text(
            'Enter your mobile number or email',
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '${AppStrings.appName} will send a 6 digit code to verify it. New here? The same step creates your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, height: 1.5),
          ),
          if (widget.from != null) ...[
            const SizedBox(height: 16),
            const InfoBanner(icon: Icons.link, message: 'Login to continue where you left off.'),
          ],
          const SizedBox(height: 32),
          AppTextField(
            controller: _identifier,
            label: 'Mobile number or email ID',
            hint: '98765 43210 or you@example.com',
            prefixIcon: _isEmail ? Icons.mail_outline : Icons.phone_outlined,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _loading ? null : _continue(),
          ),
          const SizedBox(height: 8),
          Text(
            'Indian numbers can be entered without +91.',
            style: TextStyle(color: p.textMuted, fontSize: 12),
          ),
        ],
        bottom: PrimaryButton(label: 'Next', loading: _loading, onPressed: _loading ? null : _continue),
      ),
    );
  }
}
