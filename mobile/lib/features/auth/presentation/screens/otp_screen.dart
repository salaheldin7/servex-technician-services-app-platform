import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String purpose;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.purpose,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _countdown = AppConstants.otpExpirySeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startCountdown() {
    _countdown = AppConstants.otpExpirySeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedCountdown {
    final min = _countdown ~/ 60;
    final sec = _countdown % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    if (_otpCode.length != 6) return;

    final success = await ref.read(authStateProvider.notifier).verifyOtp(
          phone: widget.phone,
          code: _otpCode,
        );

    if (success && mounted) {
      final role = ref.read(authStateProvider).user?.role ?? 'customer';
      context.go(role == 'technician' ? '/technician' : '/home');
    }
  }

  Future<void> _handleResend() async {
    if (_countdown > 0) return;
    await ref.read(authStateProvider.notifier).sendOtp(widget.phone);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpVerification)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: Responsive.value<double>(context, mobile: 32, tablet: 48)),
                  Icon(
                    Icons.sms_outlined,
                    size: Responsive.value<double>(context, mobile: 64, tablet: 80),
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.enterOtp,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    widget.phone,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  // OTP Input fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: Responsive.value<double>(context, mobile: 48, tablet: 56),
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                            if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            if (_otpCode.length == 6) {
                              _handleVerify();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Countdown / Resend
                  Text(
                    _countdown > 0 ? _formattedCountdown : '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _countdown <= 0 ? _handleResend : null,
                    child: Text(l10n.resendOtp),
                  ),
                  const Spacer(),

                  // Verify button
                  ElevatedButton(
                    onPressed: authState.isLoading || _otpCode.length != 6
                        ? null
                        : _handleVerify,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.verify),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
