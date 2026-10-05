import 'dart:async';

import 'package:flutter/services.dart';

import '../../../core/core.dart';

/// Login / signup on one page: mobile number -> email ID -> code sent to the email.
/// Only the field changes between the steps, the page stays the same.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.from});

  /// Location to continue to after login (e.g. an invite link).
  final String? from;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { mobile, email, code }

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _focus = FocusNode();
  _Step _step = _Step.mobile;
  bool _loading = false;
  String? _error;
  String? _devCode;
  bool _emailed = false;
  Timer? _timer;
  int _seconds = 0;

  /// Indian mobile number: exactly 10 digits starting with 6, 7, 8 or 9.
  static final _mobilePattern = RegExp(r'^[6-9]\d{9}$');
  static final _emailPattern = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  @override
  void initState() {
    super.initState();
    // Live validation: the error under the field and the button follow every key press.
    for (final c in [_mobile, _email, _code]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  bool get _mobileValid => _mobilePattern.hasMatch(_mobileValue);
  bool get _emailValid => _email.text.trim().length <= 100 && _emailPattern.hasMatch(_email.text.trim());
  bool get _codeValid => RegExp(r'^\d{6}$').hasMatch(_code.text.trim());

  bool get _stepValid => switch (_step) {
    _Step.mobile => _mobileValid,
    _Step.email => _emailValid,
    _Step.code => _codeValid,
  };

  /// Error shown under the field while typing (null when empty or valid).
  String? get _liveError {
    switch (_step) {
      case _Step.mobile:
        final v = _mobileValue;
        if (v.isEmpty || _mobileValid) return null;
        if (!RegExp(r'^[6-9]').hasMatch(v)) return 'Mobile number must start with 6, 7, 8 or 9';
        return 'Enter all 10 digits (${v.length}/10)';
      case _Step.email:
        final v = _email.text.trim();
        if (v.isEmpty || _emailValid) return null;
        return 'Enter a valid email ID, like name@gmail.com';
      case _Step.code:
        return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobile.dispose();
    _email.dispose();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _mobileValue => _mobile.text.replaceAll(RegExp(r'[\s()-]'), '');

  void _go(_Step step) {
    setState(() {
      _step = step;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  Future<void> _next() async {
    if (_loading) return;
    switch (_step) {
      case _Step.mobile:
        if (!_mobileValid) return setState(() => _error = 'Enter a valid 10 digit mobile number');
        _go(_Step.email);
      case _Step.email:
        if (!_emailValid) return setState(() => _error = 'Enter a valid email ID');
        await _sendCode();
      case _Step.code:
        await _verify();
    }
  }

  Future<void> _sendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AuthService.instance.requestOtpPair(_mobileValue, _email.text.trim());
      if (!mounted) return;
      _devCode = res.devCode;
      _emailed = res.emailed;
      _code.text = res.devCode ?? '';
      _startTimer();
      _go(_Step.code);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) return setState(() => _error = 'Enter the 6 digit code');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AuthService.instance.verifyOtpPair(_mobileValue, _email.text.trim(), code);
      if (!mounted) return;
      final from = widget.from;
      if (!res.user.profileCompleted) {
        context.go(from == null ? AppRoutes.profileSetup : '${AppRoutes.profileSetup}?from=${Uri.encodeComponent(from)}');
      } else {
        context.go(from ?? AppRoutes.home);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_step == _Step.code) return _go(_Step.email);
    if (_step == _Step.email) return _go(_Step.mobile);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (title, subtitle) = switch (_step) {
      _Step.mobile => ('Enter your mobile number', '${AppStrings.appName} uses it to find your account. New here? The same steps create it.'),
      _Step.email => ('Enter your email ID', 'We will send a 6 digit code to this email.'),
      _Step.code => ('Enter the code', 'Sent to ${_email.text.trim()}'),
    };
    return PopScope(
      canPop: _step == _Step.mobile,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _step == _Step.mobile && !context.canPop() ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
          automaticallyImplyLeading: false,
        ),
        body: FormPage(
          items: [
            const Center(child: AppLogo(size: 76)),
            const SizedBox(height: 20),
            _Progress(step: _step.index),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: p.textSecondary, height: 1.5)),
            if (widget.from != null) ...[
              const SizedBox(height: 16),
              const InfoBanner(icon: Icons.link, message: 'Login to continue where you left off.'),
            ],
            const SizedBox(height: 28),
            // Only the field changes between the steps.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(a), child: child),
              ),
              child: KeyedSubtree(key: ValueKey(_step), child: _field(context)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: p.danger, fontSize: 13)),
            ],
            const SizedBox(height: 10),
            if (_step == _Step.email)
              _Chip(icon: Icons.phone_outlined, text: _mobileValue, onEdit: () => _go(_Step.mobile)),
            if (_step == _Step.code) ...[
              _Chip(icon: Icons.mail_outline, text: _email.text.trim(), onEdit: () => _go(_Step.email)),
              const SizedBox(height: 8),
              Center(
                child: _seconds > 0
                    ? Text('Resend code in 0:${_seconds.toString().padLeft(2, '0')}', style: TextStyle(color: p.textSecondary))
                    : TextButton.icon(onPressed: _loading ? null : _sendCode, icon: const Icon(Icons.refresh), label: const Text('Resend code')),
              ),
              if (_devCode != null && !_emailed) ...[
                const SizedBox(height: 8),
                InfoBanner(icon: Icons.developer_mode, message: 'Test mode: email sending is not connected yet, so the code is filled in for you ($_devCode).'),
              ],
            ],
          ],
          bottom: PrimaryButton(
            label: switch (_step) {
              _Step.mobile => 'Next',
              _Step.email => 'Send code',
              _Step.code => 'Verify',
            },
            loading: _loading,
            onPressed: _loading || !_stepValid ? null : _next,
          ),
        ),
      ),
    );
  }

  Widget _field(BuildContext context) {
    return switch (_step) {
      _Step.mobile => TextField(
        controller: _mobile,
        focusNode: _focus,
        autofocus: true,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        // Digits only, at most 10 (the +91 country code is fixed).
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        autofillHints: const [AutofillHints.telephoneNumberNational],
        onSubmitted: (_) => _next(),
        decoration: InputDecoration(
          labelText: 'Mobile number',
          hintText: '9876543210',
          prefixIcon: const Icon(Icons.phone_outlined),
          prefixText: '+91  ',
          errorText: _liveError,
          suffixIcon: _mobileValid ? Icon(Icons.check_circle, color: context.palette.success) : null,
          counterText: '${_mobileValue.length}/10',
        ),
      ),
      _Step.email => TextField(
        controller: _email,
        focusNode: _focus,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.send,
        autofillHints: const [AutofillHints.email],
        // No spaces, at most 100 characters.
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s')), LengthLimitingTextInputFormatter(100)],
        autocorrect: false,
        onSubmitted: (_) => _next(),
        decoration: InputDecoration(
          labelText: 'Email ID',
          hintText: 'you@example.com',
          prefixIcon: const Icon(Icons.mail_outline),
          errorText: _liveError,
          suffixIcon: _emailValid ? Icon(Icons.check_circle, color: context.palette.success) : null,
        ),
      ),
      _Step.code => TextField(
        controller: _code,
        focusNode: _focus,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.w700),
        onChanged: (v) {
          if (v.length == 6) _next();
        },
        onSubmitted: (_) => _next(),
        decoration: const InputDecoration(counterText: '', hintText: '------'),
      ),
    };
  }
}

/// Mobile -> Email -> Code dots.
class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == step ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= step ? AppColors.primary : context.palette.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Already entered value with "Edit".
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.onEdit});

  final IconData icon;
  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(color: context.palette.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.palette.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}
