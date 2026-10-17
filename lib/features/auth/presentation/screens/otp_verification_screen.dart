import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/core/services/firebase_phone_auth_service.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakan_app/features/auth/presentation/screens/reset_password_screen.dart';

enum OtpMode { register, changePhone, forgotPassword }

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  final OtpMode mode;
  // Extra data for registration
  final String? name;
  final String? password;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.mode,
    this.name,
    this.password,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _sendOtp();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() => _isResending = true);
    final formattedPhone = widget.phone.startsWith('+2')
        ? widget.phone
        : '+2${widget.phone}';

    await ref
        .read(firebasePhoneAuthProvider)
        .sendOtp(
          phone: formattedPhone,
          onCodeSent: () {
            if (mounted) {
              setState(() => _isResending = false);
              _startCooldown();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.translate('otp_sent') ?? 'OTP has been sent',
                  ),
                ),
              );
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() => _isResending = false);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
            }
          },
        );
  }

  Future<void> _verifyOtp() async {
    if (_pinController.text.length != 6) return;

    setState(() => _isLoading = true);

    final idToken = await ref
        .read(firebasePhoneAuthProvider)
        .verifyOtpAndGetIdToken(_pinController.text);

    if (!mounted) return;

    // Cache context-dependent objects before any awaits
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final invalidOtpMsg =
        context.translate('invalid_otp') ?? 'Invalid OTP code';
    final phoneUpdatedMsg =
        context.translate('phone_updated') ?? 'Phone number updated';

    if (idToken == null) {
      setState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text(invalidOtpMsg)));
      return;
    }

    // Handle success based on mode
    try {
      if (widget.mode == OtpMode.register) {
        await ref
            .read(authProvider.notifier)
            .register(widget.name!, widget.password!, widget.phone, idToken);
        if (!mounted) return;
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          navigator.popUntil((route) => route.isFirst);
        } else if (authState.error != null) {
          messenger.showSnackBar(SnackBar(content: Text(authState.error!)));
        }
      } else if (widget.mode == OtpMode.changePhone) {
        final result = await ref
            .read(authProvider.notifier)
            .changePhone(widget.phone, idToken);
        if (!mounted) return;
        if (result['success'] == true) {
          messenger.showSnackBar(SnackBar(content: Text(phoneUpdatedMsg)));
          navigator.pop();
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Error')),
          );
        }
      } else if (widget.mode == OtpMode.forgotPassword) {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              phone: widget.phone,
              firebaseIdToken: idToken,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('verify_phone') ?? 'Verify Phone'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              context.translate('otp_description') ??
                  'Enter the 6-digit code sent to',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.phone,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Pinput(
                length: 6,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                onCompleted: (pin) => _verifyOtp(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading || _pinController.text.length != 6
                  ? null
                  : _verifyOtp,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.translate('verify') ?? 'Verify'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.translate('didnt_receive_code') ??
                      "Didn't receive the code? ",
                ),
                TextButton(
                  onPressed: _resendCooldown > 0 || _isResending
                      ? null
                      : _sendOtp,
                  child: Text(
                    _resendCooldown > 0
                        ? "${context.translate('resend_in') ?? 'Resend in'} $_resendCooldown"
                        : (context.translate('resend_code') ?? 'Resend Code'),
                    style: TextStyle(
                      color: _resendCooldown > 0
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
