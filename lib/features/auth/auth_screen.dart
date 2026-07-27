import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';

class CountryRegion {
  final String code;
  final String name;
  final String flag;
  final String dialCode;

  const CountryRegion({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

const List<CountryRegion> defaultCountryRegions = [
  CountryRegion(code: 'IN', name: 'India', flag: '🇮🇳', dialCode: '+91'),
  CountryRegion(code: 'US', name: 'United States', flag: '🇺🇸', dialCode: '+1'),
  CountryRegion(code: 'GB', name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44'),
  CountryRegion(code: 'AE', name: 'UAE', flag: '🇦🇪', dialCode: '+971'),
  CountryRegion(code: 'SG', name: 'Singapore', flag: '🇸🇬', dialCode: '+65'),
  CountryRegion(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', dialCode: '+966'),
  CountryRegion(code: 'QA', name: 'Qatar', flag: '🇶🇦', dialCode: '+974'),
  CountryRegion(code: 'KW', name: 'Kuwait', flag: '🇰🇼', dialCode: '+965'),
  CountryRegion(code: 'OM', name: 'Oman', flag: '🇴🇲', dialCode: '+968'),
  CountryRegion(code: 'BH', name: 'Bahrain', flag: '🇧🇭', dialCode: '+973'),
  CountryRegion(code: 'MY', name: 'Malaysia', flag: '🇲🇾', dialCode: '+60'),
  CountryRegion(code: 'AU', name: 'Australia', flag: '🇦🇺', dialCode: '+61'),
  CountryRegion(code: 'DE', name: 'Germany', flag: '🇩🇪', dialCode: '+49'),
];

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  CountryRegion _selectedRegion = defaultCountryRegions.first;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
    String digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length > 10 && _selectedRegion.dialCode == '+91') {
      digits = digits.substring(2);
    }
    return '${_selectedRegion.dialCode}$digits';
  }

  Future<void> _sendBackendOtp() async {
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || (digits.length < 7 && _selectedRegion.code != 'IN') || (digits.length < 10 && _selectedRegion.code == 'IN')) {
      setState(() => _errorMessage = 'Enter a valid mobile phone number');
      return;
    }
    setState(() { _isSendingOtp = true; _errorMessage = null; _infoMessage = null; });
    try {
      final phone = _normalizedPhone;
      final res = await ApiClient.sendOtp(phone);
      if (mounted) {
        setState(() {
          _otpSent = true;
          final debugOtp = res['debugOtp']?.toString();
          _infoMessage = debugOtp != null
              ? '🔐 Dev Mode: OTP sent to backend terminal. Copy from logs and paste below.'
              : 'OTP sent to $phone.';
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
      final phone = _normalizedPhone;
      final res = await ApiClient.verifyOtp(phoneNumber: phone, otp: code, fullName: 'Customer');
      final data = res['data'] ?? res;
      final token = data['tokens']?['accessToken'] ?? data['accessToken'] ?? '';
      final user = data['user'] ?? {};
      final isReg = (data['isRegistered'] as bool?) ?? false;
      final userName = (user['fullName'] ?? user['full_name'] ?? 'Customer').toString();

      await SessionStorage.setSession(
        token: token,
        phone: (user['phoneNumber'] ?? user['phone_number'] ?? phone).toString(),
        name: userName,
        userId: user['id']?.toString(),
        email: user['email']?.toString(),
        isProfileComplete: isReg || (userName.isNotEmpty && userName != 'Customer' && userName != 'New User'),
      );

      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Select Country / Region Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: defaultCountryRegions.length,
              itemBuilder: (ctx, i) {
                final region = defaultCountryRegions[i];
                final isSelected = region.code == _selectedRegion.code;
                return ListTile(
                  leading: Text(region.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(region.name, style: TextStyle(color: isSelected ? AppColors.primary : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: Text(region.dialCode, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textMuted, fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() => _selectedRegion = region);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -80, right: -80, child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.primary.withAlpha(40), Colors.transparent])),
          )),
          Positioned(bottom: 80, left: -100, child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.secondary.withAlpha(25), Colors.transparent])),
          )),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    Center(
                      child: Container(
                        width: 84, height: 84,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(100), blurRadius: 40, offset: const Offset(0, 16))],
                        ),
                        child: const Icon(Icons.shield_rounded, size: 44, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('LUMO', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                    const SizedBox(height: 6),
                    const Text('Safety-First Home Services', textAlign: TextAlign.center, style: AppText.caption),
                    const SizedBox(height: 48),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.emergencyRedSoft, border: Border.all(color: AppColors.emergencyRedBorder), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppColors.emergencyRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.emergencyRed, fontSize: 13))),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_infoMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primarySoft, border: Border.all(color: AppColors.primary.withAlpha(60)), borderRadius: BorderRadius.circular(12)),
                        child: Text(_infoMessage!, style: const TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!_otpSent) ...[
                      AppGlassCard(
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('MOBILE PHONE & REGION', style: AppText.label),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _showRegionPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.glassBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_selectedRegion.flag, style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 6),
                                        Text(_selectedRegion.dialCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, letterSpacing: 1),
                                    decoration: lumoInputDecoration(
                                      hint: '98765 43210',
                                      prefix: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AppGradientButton(
                              label: 'GET OTP CODE',
                              onTap: _sendBackendOtp,
                              isLoading: _isSendingOtp,
                              icon: Icons.sms_rounded,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      AppGlassCard(
                        borderRadius: 24,
                        borderColor: AppColors.primary.withAlpha(60),
                        gradientColors: [AppColors.primarySoft, const Color(0x06FFFFFF)],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_normalizedPhone, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14))),
                                TextButton(
                                  onPressed: () => setState(() { _otpSent = false; _otpController.clear(); _infoMessage = null; }),
                                  child: const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('ENTER OTP CODE', style: AppText.label),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _otpController,
                              focusNode: _otpFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 14, fontWeight: FontWeight.bold),
                              decoration: lumoInputDecoration(hint: '· · · · · ·').copyWith(counterText: ''),
                            ),
                            const SizedBox(height: 20),
                            AppGradientButton(
                              label: 'VERIFY & ENTER LUMO',
                              onTap: _verifyOtp,
                              isLoading: _isVerifyingOtp,
                              icon: Icons.arrow_forward_rounded,
                              colors: const [AppColors.successGreen, Color(0xFF059669)],
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _isSendingOtp ? null : _sendBackendOtp,
                              child: Text(_isSendingOtp ? 'Sending...' : 'Resend OTP', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined, color: AppColors.successGreen, size: 14),
                        SizedBox(width: 6),
                        Text('All professionals are background-verified', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
