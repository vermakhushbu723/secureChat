import 'dart:async';

import 'package:flutter/services.dart';

import '../../../core/core.dart';

/// 6 digit code sent to the mobile number / email ID. Existing accounts go to
/// the chats, new ones to the Personal / Business step.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.identifier, this.from, this.devCode});

  /// Normalised mobile number (+91...) or email ID the code was sent to.
  final String identifier;
  final String? from;

  /// Returned by the server in dev mode (no SMS / email provider): pre-fills the code.
  final String? devCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 30;
  bool _verifying = false;
  String _last = '';

  bool get _isEmail => widget.identifier.contains('@');

  @override
  void initState() {
    super.initState();
    if (widget.devCode != null) _code.text = _last = widget.devCode!;
    _code.addListener(_onCode);
    _startTimer();
  }

  /// Auto-verify once the user types the 6th digit (focus / selection changes are ignored).
  void _onCode() {
    final text = _code.text;
    if (text == _last) return;
    _last = text;
    setState(() {});
    if (text.length == _length && !_verifying) _verify();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _resend() async {
    try {
      final res = await AuthService.instance.requestOtp(widget.identifier);
      if (res.devCode != null) {
        _last = res.devCode!;
        _code.text = res.devCode!;
        setState(() {});
      }
      if (mounted) context.showSnack('New code sent');
      _startTimer();
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != _length) return context.showSnack('Enter the 6 digit code');
    setState(() => _verifying = true);
    try {
      final res = await AuthService.instance.verifyOtp(widget.identifier, code);
      if (!mounted) return;
      final from = widget.from;
      if (!res.user.profileCompleted) {
        context.go(from == null ? AppRoutes.profileSetup : '${AppRoutes.profileSetup}?from=${Uri.encodeComponent(from)}');
      } else {
        context.go(from ?? AppRoutes.home);
      }
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(_isEmail ? 'Verify your email' : 'Verify your number')),
      body: FormPage(
        items: [
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(color: p.textSecondary, height: 1.5),
              children: [
                const TextSpan(text: 'Enter the 6 digit code sent to\n'),
                TextSpan(text: widget.identifier, style: TextStyle(color: context.colors.onSurface, fontWeight: FontWeight.w700)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Center(
            child: TextButton(
              onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
              child: Text(_isEmail ? 'Wrong email?' : 'Wrong number?'),
            ),
          ),
          const SizedBox(height: 16),
          // One field that shows 6 slots: works with paste and SMS autofill.
          GestureDetector(
            onTap: () => _focus.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _code,
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: _length,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _length; i++)
                        Container(
                          width: 40,
                          height: 48,
                          margin: EdgeInsets.only(left: i == 3 ? 16 : 4, right: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: i == _code.text.length ? AppColors.primary : p.textMuted,
                                width: i == _code.text.length ? 2 : 1,
                              ),
                            ),
                          ),
                          child: Text(
                            i < _code.text.length ? _code.text[i] : '',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: _seconds > 0
                ? Text('Resend code in 0:${_seconds.toString().padLeft(2, '0')}', style: TextStyle(color: p.textSecondary))
                : TextButton.icon(onPressed: _resend, icon: const Icon(Icons.refresh), label: const Text('Resend code')),
          ),
          if (widget.devCode != null) ...[
            const SizedBox(height: 16),
            InfoBanner(icon: Icons.developer_mode, message: 'Test mode: SMS / email is not connected yet, so the code is filled in for you (${widget.devCode}).'),
          ],
        ],
        bottom: PrimaryButton(label: 'Verify', loading: _verifying, onPressed: _verifying ? null : _verify),
      ),
    );
  }
}
