import 'package:flutter/services.dart';

import '../../../core/core.dart';

/// Admin / staff login: email + password, then the 6 digit code sent to the staff email.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  String? _challengeId;
  String? _sentTo;
  String? _devCode;
  String? _error;
  bool _busy = false;

  static final _emailPattern = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  @override
  void initState() {
    super.initState();
    // Live validation: errors under the fields and the button follow every key press.
    for (final c in [_email, _password, _code]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  bool get _emailValid => _emailPattern.hasMatch(_email.text.trim());
  bool get _canSubmit => _challengeId == null ? _emailValid && _password.text.isNotEmpty : RegExp(r'^\d{6}$').hasMatch(_code.text.trim());

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_challengeId == null) {
        if (!_emailValid) throw ApiException('Enter a valid email address');
        if (_password.text.isEmpty) throw ApiException('Enter your password');
        final r = await AdminApi.post<Map<String, dynamic>>('/auth/login', {'email': _email.text.trim(), 'password': _password.text});
        if (r['twoFactor'] == true) {
          setState(() {
            _challengeId = r['challengeId'] as String;
            _sentTo = r['sentTo'] as String?;
            _devCode = r['devCode'] as String?;
          });
          return;
        }
        await _done(r);
      } else {
        if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) throw ApiException('Enter the 6 digit code');
        final r = await AdminApi.post<Map<String, dynamic>>('/auth/verify', {'challengeId': _challengeId, 'code': _code.text.trim()});
        await _done(r);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _done(Map<String, dynamic> session) async {
    await AdminSession.signIn(session);
    if (mounted) context.go(AdminRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final otpStep = _challengeId != null;
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
                child: AutofillGroup(
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
                        otpStep ? 'Enter the 6 digit code sent to ${_sentTo ?? 'your email'}' : 'Sign in to the admin panel',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      if (!otpStep) ...[
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s')), LengthLimitingTextInputFormatter(120)],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.mail_outline),
                            errorText: _email.text.trim().isEmpty || _emailValid ? null : 'Enter a valid email address, like admin@example.com',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                        ),
                      ] else ...[
                        TextField(
                          controller: _code,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onSubmitted: (_) => _submit(),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: '2-step verification code', hintText: '000000', prefixIcon: Icon(Icons.pin_outlined)),
                        ),
                        if (_devCode != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InfoBanner(icon: Icons.science_outlined, tone: Tone.warning, message: 'Test mode (email not set up): your code is $_devCode'),
                          ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        InfoBanner(icon: Icons.error_outline, tone: Tone.danger, message: _error!),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(label: otpStep ? 'Verify & Sign in' : 'Continue', loading: _busy, onPressed: _busy || !_canSubmit ? null : _submit),
                      if (otpStep)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _challengeId = null;
                                  _code.clear();
                                  _error = null;
                                }),
                          child: const Text('Back'),
                        ),
                      const SizedBox(height: 16),
                      const InfoBanner(
                        icon: Icons.policy_outlined,
                        message: 'Every admin action, including viewing user data or locations, is recorded in the audit log.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
