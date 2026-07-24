import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            AppGlassCard(
              borderRadius: 20,
              gradientColors: [const Color(0x1A3B82F6), const Color(0x0A3B82F6)],
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(SessionStorage.userName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
                        Text(SessionStorage.userPhone, style: AppText.caption),
                        if (SessionStorage.userEmail.isNotEmpty)
                          Text(SessionStorage.userEmail, style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('ACCOUNT SECURITY', style: AppText.label),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.lock_rounded,
              label: 'Change Password',
              subtitle: 'Update your account password',
              color: AppColors.primary,
              onTap: () => _showChangePasswordSheet(context),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.phone_android_rounded,
              label: 'Change Mobile Number',
              subtitle: 'Verify with OTP to update',
              color: AppColors.secondary,
              onTap: () => _showChangeMobileSheet(context),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.email_rounded,
              label: 'Change Email',
              subtitle: 'Update your email address',
              color: const Color(0xFF8B5CF6),
              onTap: () => _showChangeEmailSheet(context),
            ),

            const SizedBox(height: 24),
            const Text('ABOUT', style: AppText.label),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.shield_outlined,
              label: 'Safety Features',
              subtitle: 'SOS, verified pros, background checks',
              color: AppColors.successGreen,
              onTap: null,
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.info_outline,
              label: 'App Version',
              subtitle: 'LUMO v1.0.0',
              color: AppColors.textMuted,
              onTap: null,
            ),

            const SizedBox(height: 32),

            GestureDetector(
              onTap: () => _confirmLogout(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRedSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.emergencyRedBorder),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.emergencyRed, size: 20),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('You will need to sign in again with your mobile number and OTP.', style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); widget.onLogout(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Password', style: AppText.heading2),
              const SizedBox(height: 20),
              if (error != null) _errorBox(error!),
              TextField(controller: oldCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: lumoInputDecoration(hint: 'Current Password')),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: lumoInputDecoration(hint: 'New Password')),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: lumoInputDecoration(hint: 'Confirm New Password')),
              const SizedBox(height: 20),
              AppGradientButton(
                label: 'UPDATE PASSWORD',
                isLoading: loading,
                onTap: () async {
                  if (newCtrl.text != confirmCtrl.text) { setBS(() => error = 'Passwords do not match'); return; }
                  setBS(() { loading = true; error = null; });
                  try {
                    await ApiClient.changePassword(oldCtrl.text, newCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('Password updated');
                  } catch (e) {
                    setBS(() { error = e.toString().replaceAll('Exception: ', ''); loading = false; });
                  }
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeMobileSheet(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    bool otpSent = false;
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Mobile Number', style: AppText.heading2),
              const SizedBox(height: 6),
              const Text('Enter your new number and verify with OTP', style: AppText.caption),
              const SizedBox(height: 20),
              if (error != null) _errorBox(error!),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
                style: const TextStyle(color: Colors.white),
                decoration: lumoInputDecoration(hint: '+91 New Number'),
              ),
              const SizedBox(height: 12),
              AppGradientButton(
                label: 'SEND OTP',
                isLoading: loading && !otpSent,
                colors: const [AppColors.secondary, Color(0xFF4F46E5)],
                onTap: () async {
                  setBS(() { loading = true; error = null; });
                  try {
                    final num = phoneCtrl.text.trim().startsWith('+') ? phoneCtrl.text.trim() : '+91${phoneCtrl.text.trim()}';
                    await ApiClient.sendOtp(num);
                    setBS(() { otpSent = true; loading = false; });
                  } catch (e) {
                    setBS(() { error = e.toString().replaceAll('Exception: ', ''); loading = false; });
                  }
                },
              ),
              if (otpSent) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                  decoration: lumoInputDecoration(hint: '· · · · · ·').copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
                AppGradientButton(
                  label: 'VERIFY & UPDATE',
                  isLoading: loading && otpSent,
                  onTap: () async {
                    setBS(() { loading = true; error = null; });
                    try {
                      final num = phoneCtrl.text.trim().startsWith('+') ? phoneCtrl.text.trim() : '+91${phoneCtrl.text.trim()}';
                      await ApiClient.verifyOtp(phoneNumber: num, otp: otpCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showSnack('Mobile number updated');
                    } catch (e) {
                      setBS(() { error = e.toString().replaceAll('Exception: ', ''); loading = false; });
                    }
                  },
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeEmailSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Email', style: AppText.heading2),
              const SizedBox(height: 20),
              if (error != null) _errorBox(error!),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: lumoInputDecoration(hint: 'new@email.com'),
              ),
              const SizedBox(height: 20),
              AppGradientButton(
                label: 'UPDATE EMAIL',
                isLoading: loading,
                colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                onTap: () async {
                  setBS(() { loading = true; error = null; });
                  await Future.delayed(const Duration(milliseconds: 500));
                  await SessionStorage.completeProfile(
                    name: SessionStorage.userName,
                    age: SessionStorage.age,
                    sex: SessionStorage.sex,
                    email: emailCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnack('Email updated');
                  setBS(() => loading = false);
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.emergencyRedSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.emergencyRedBorder)),
    child: Text(msg, style: const TextStyle(color: AppColors.emergencyRed, fontSize: 12)),
  );

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                Text(subtitle, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
