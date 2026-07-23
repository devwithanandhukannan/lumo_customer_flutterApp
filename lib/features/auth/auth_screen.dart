import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController(text: '+919876543210');
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  String? _errorMessage;
  String? _debugOtp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final raw = _phoneController.text.trim();
    if (raw.startsWith('+')) return raw;
    if (raw.length == 10) return '+91$raw';
    return raw;
  }

  Future<void> _sendBackendOtp() async {
    setState(() { _isSendingOtp = true; _errorMessage = null; });
    try {
      final res = await ApiClient.sendOtp(_normalizedPhone);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _debugOtp = res['debugOtp']?.toString();
          _infoMessage = _debugOtp != null ? 'OTP sent! Your code: $_debugOtp' : 'OTP sent to $_normalizedPhone.';
        });
        FocusScope.of(context).requestFocus(_otpFocus);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _errorMessage = 'Please enter the complete OTP code');
      return;
    }
    setState(() { _isVerifyingOtp = true; _errorMessage = null; });

    try {
      final res = await ApiClient.verifyOtp(phoneNumber: _normalizedPhone, otp: code, role: 'CUSTOMER');
      final data = res['data'] ?? res;
      final token = data['tokens']?['accessToken'] ?? data['accessToken'] ?? '';
      final user = data['user'] ?? {};

      await SessionStorage.setSession(
        token: token,
        phone: user['phoneNumber']?.toString() ?? _normalizedPhone,
        name: user['fullName']?.toString() ?? 'Customer',
        userId: user['id']?.toString(),
      );

      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [BoxShadow(color: Color(0x663B82F6), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: const Icon(Icons.shield_outlined, size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('LUMO', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
                const SizedBox(height: 6),
                const Text('Safety-First Home Services', textAlign: TextAlign.center, style: AppText.caption),

                const SizedBox(height: 40),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.emergencyRedSoft, border: Border.all(color: AppColors.emergencyRedBorder), borderRadius: BorderRadius.circular(12)),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.emergencyRed, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],

                if (!_otpSent) ...[
                  const Text('MOBILE NUMBER', style: AppText.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    decoration: lumoInputDecoration(hint: '+91 98765 43210', prefix: const Icon(Icons.phone_android, color: AppColors.textMuted, size: 20)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSendingOtp ? null : _sendBackendOtp,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: _isSendingOtp
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('GET OTP CODE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
                    ),
                  ),
                ] else ...[
                  const Text('VERIFICATION CODE', style: AppText.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otpController,
                    focusNode: _otpFocus,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.bold),
                    decoration: lumoInputDecoration(hint: '· · · · · ·').copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isVerifyingOtp ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: _isVerifyingOtp
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('VERIFY & ENTER LUMO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
