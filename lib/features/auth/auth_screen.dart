import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/firebase_auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isFirebaseMode = false;
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  String? _verificationId;
  String? _errorMessage;
  String? _infoMessage;
  String? _debugOtp; // From backend response for testing

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get _normalizedPhone {
    final raw = _phoneController.text.trim();
    if (raw.startsWith('+')) return raw;
    if (raw.startsWith('0')) return '+91${raw.substring(1)}';
    if (raw.length == 10) return '+91$raw';
    return raw;
  }

  bool get _isPhoneValid {
    final p = _normalizedPhone;
    return RegExp(r'^\+\d{10,14}$').hasMatch(p);
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _errorMessage = msg;
        _infoMessage = null;
      });
    }
  }

  // ─── Backend OTP ──────────────────────────────────────────────────────────

  Future<void> _sendBackendOtp() async {
    if (!_isPhoneValid) {
      _setError('Enter a valid mobile number (e.g. +919876543210)');
      return;
    }
    if (mounted) setState(() => _isSendingOtp = true);
    try {
      final res = await ApiClient.sendOtp(_normalizedPhone);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _debugOtp = res['debugOtp']?.toString();
          _infoMessage = _debugOtp != null
              ? 'OTP sent! Your code: $_debugOtp'
              : 'OTP sent to $_normalizedPhone. Check console.';
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(_otpFocus);
        });
      }
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  // ─── Firebase OTP ─────────────────────────────────────────────────────────

  Future<void> _sendFirebaseOtp() async {
    if (!_isPhoneValid) {
      _setError('Enter a valid mobile number (e.g. +919876543210)');
      return;
    }
    if (mounted) setState(() => _isSendingOtp = true);

    await FirebaseAuthService.verifyPhone(
      phoneNumber: _normalizedPhone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isSendingOtp = false;
            _infoMessage = 'Firebase SMS code sent to $_normalizedPhone';
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _errorMessage = err;
            _isSendingOtp = false;
          });
        }
      },
      onAutoVerified: (credential) async {
        if (mounted) setState(() => _isSendingOtp = true);
        try {
          final res = await FirebaseAuthService.signInWithCredential(credential);
          final data = res['data'] ?? res;
          await _saveSessionAndNavigate(data);
        } catch (_) {
        } finally {
          if (mounted) setState(() => _isSendingOtp = false);
        }
      },
    );
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || code.length < 4) {
      _setError('Please enter the complete OTP code');
      return;
    }
    if (mounted) setState(() => _isVerifyingOtp = true);

    try {
      Map<String, dynamic> res;
      if (_isFirebaseMode && _verificationId != null) {
        res = await FirebaseAuthService.signInWithSmsCode(
          verificationId: _verificationId!,
          smsCode: code,
        );
      } else {
        res = await ApiClient.verifyOtp(
          phoneNumber: _normalizedPhone,
          otp: code,
          role: 'CUSTOMER',
        );
      }
      final data = res['data'] ?? res;
      await _saveSessionAndNavigate(data);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _saveSessionAndNavigate(Map<String, dynamic> data) async {
    final token = data['tokens']?['accessToken'] ?? data['accessToken'] ?? '';
    final user = data['user'] ?? {};
    await SessionStorage.setSession(
      token: token,
      phone: user['phoneNumber']?.toString() ?? _normalizedPhone,
      name: user['fullName']?.toString() ?? 'Customer',
      userId: user['id']?.toString(),
    );
    if (mounted) widget.onLoginSuccess();
  }

  // ─── IP Config Dialog ─────────────────────────────────────────────────────

  void _showIpConfigDialog() {
    final ctrl = TextEditingController(text: ApiClient.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Backend Gateway URL',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set the API Gateway endpoint. Use your Mac\'s local Wi-Fi IP for physical devices.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: AppText.mono,
              decoration: lumoInputDecoration(hint: 'http://192.168.x.x:8000'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Physical Device', 'http://192.168.1.8:8000', ctrl),
                _chip('Android Emulator', 'http://10.0.2.2:8000', ctrl),
                _chip('iOS Simulator', 'http://localhost:8000', ctrl),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              ApiClient.updateBaseUrl(ctrl.text.trim());
              Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String url, TextEditingController ctrl) {
    return GestureDetector(
      onTap: () => ctrl.text = url,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: AppText.label),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Auth mode toggle
                    GestureDetector(
                      onTap: () => setState(() => _isFirebaseMode = !_isFirebaseMode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isFirebaseMode
                              ? AppColors.secondary.withAlpha(26)
                              : AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isFirebaseMode ? AppColors.secondary : AppColors.primary,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isFirebaseMode ? Icons.local_fire_department : Icons.router_outlined,
                              size: 14,
                              color: _isFirebaseMode ? AppColors.secondary : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isFirebaseMode ? 'Firebase Auth' : 'Backend OTP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isFirebaseMode ? AppColors.secondary : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Gateway IP
                    GestureDetector(
                      onTap: _showIpConfigDialog,
                      child: Row(
                        children: [
                          const Icon(Icons.settings_ethernet, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            ApiClient.baseUrl.replaceAll('http://', ''),
                            style: AppText.label.copyWith(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Logo
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x663B82F6),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_outlined, size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('LUMO', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
                const SizedBox(height: 6),
                const Text(
                  'Safety-First Home Services',
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),

                const SizedBox(height: 40),

                // Status banners
                if (_errorMessage != null) ...[
                  _Banner(
                    color: AppColors.emergencyRed,
                    softColor: AppColors.emergencyRedSoft,
                    borderColor: AppColors.emergencyRedBorder,
                    icon: Icons.error_outline,
                    text: _errorMessage!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_infoMessage != null && _otpSent) ...[
                  _Banner(
                    color: AppColors.successGreen,
                    softColor: AppColors.successGreenSoft,
                    borderColor: const Color(0x4010B981),
                    icon: Icons.check_circle_outline,
                    text: _infoMessage!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Phone step
                if (!_otpSent) ...[
                  const Text('MOBILE NUMBER', style: AppText.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, letterSpacing: 1),
                    decoration: lumoInputDecoration(
                      hint: '+91 98765 43210',
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.phone_android, color: AppColors.textMuted, size: 20),
                      ),
                    ),
                    onSubmitted: (_) =>
                        _isFirebaseMode ? _sendFirebaseOtp() : _sendBackendOtp(),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSendingOtp
                          ? null
                          : (_isFirebaseMode ? _sendFirebaseOtp : _sendBackendOtp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFirebaseMode
                            ? AppColors.secondary
                            : AppColors.primary,
                        disabledBackgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _isFirebaseMode
                                  ? 'SEND FIREBASE SMS'
                                  : 'GET OTP',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1),
                            ),
                    ),
                  ),
                ]

                // OTP step
                else ...[
                  Row(
                    children: [
                      const Text('VERIFICATION CODE', style: AppText.label),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _otpSent = false;
                          _otpController.clear();
                          _errorMessage = null;
                          _infoMessage = null;
                          _debugOtp = null;
                        }),
                        child: const Text('Change number',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otpController,
                    focusNode: _otpFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: 10,
                        fontWeight: FontWeight.bold),
                    decoration: lumoInputDecoration(hint: '· · · · · ·').copyWith(
                      counterText: '',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.successGreen, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _verifyOtp(),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isVerifyingOtp ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        disabledBackgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isVerifyingOtp
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'VERIFY & ENTER LUMO',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 1),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                const _SafetyNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final Color color, softColor, borderColor;
  final IconData icon;
  final String text;

  const _Banner({
    required this.color,
    required this.softColor,
    required this.borderColor,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color.withAlpha(230), fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 14, color: AppColors.successGreen),
        const SizedBox(width: 6),
        Text(
          'Police-verified professionals · Background checked',
          style: AppText.caption.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
