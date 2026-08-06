import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String _currentTheme = SessionStorage.themeMode;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiClient.getMyProfile();
      if (mounted) setState(() { _profile = res['data'] ?? res; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _profile = {
            'fullName': SessionStorage.userName,
            'phoneNumber': SessionStorage.userPhone,
            'email': SessionStorage.userEmail,
            'role': 'CUSTOMER'
          };
          _loading = false;
        });
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.glassBorder)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out from LUMO?', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SessionStorage.clearSession();
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SIGN OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet() {
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
                    _showSnack('Password updated successfully');
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

  void _showChangeMobileSheet() {
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
                colors: const [AppColors.secondary, Color(0xFFCA8A04)],
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

  @override
  Widget build(BuildContext context) {
    final fullName = _profile?['fullName']?.toString() ?? SessionStorage.userName;
    final phone = _profile?['phoneNumber']?.toString() ?? SessionStorage.userPhone;
    final email = _profile?['email']?.toString() ?? SessionStorage.userEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Profile & Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Glass Profile Header
                    AppGlassCard(
                      borderRadius: 24,
                      gradientColors: const [Color(0x2EFEF08A), Color(0x0EFEF08A)],
                      borderColor: AppColors.glassBorderBright,
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withAlpha(90), blurRadius: 18, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'C',
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(fullName.isNotEmpty ? fullName : 'LUMO Customer', style: AppText.heading2),
                          const SizedBox(height: 4),
                          Text(phone, style: AppText.caption.copyWith(fontFamily: 'monospace')),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(email, style: AppText.caption),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successGreenSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.successGreen.withAlpha(60)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield, color: AppColors.successGreen, size: 12),
                                SizedBox(width: 4),
                                Text('VERIFIED CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.successGreen, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('APPEARANCE & THEME', style: AppText.label),
                    const SizedBox(height: 10),

                    AppGlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _currentTheme == 'LIGHT' ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('App Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Switch between Dark Obsidian & Light Mode', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _ThemeChip(
                                  label: 'Dark Mode',
                                  icon: Icons.dark_mode_rounded,
                                  isSelected: _currentTheme == 'DARK',
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await SessionStorage.setThemeMode('DARK');
                                    if (!mounted) return;
                                    setState(() => _currentTheme = 'DARK');
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Theme updated to Dark Mode'), duration: Duration(seconds: 1)),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ThemeChip(
                                  label: 'Light Mode',
                                  icon: Icons.light_mode_rounded,
                                  isSelected: _currentTheme == 'LIGHT',
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await SessionStorage.setThemeMode('LIGHT');
                                    if (!mounted) return;
                                    setState(() => _currentTheme = 'LIGHT');
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Theme updated to Light Mode'), duration: Duration(seconds: 1)),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('ACCOUNT SECURITY', style: AppText.label),
                    const SizedBox(height: 10),

                    AppGlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsRow(
                            icon: Icons.lock_rounded,
                            label: 'Change Password',
                            subtitle: 'Update your login password',
                            color: AppColors.primary,
                            onTap: _showChangePasswordSheet,
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          _SettingsRow(
                            icon: Icons.phone_android_rounded,
                            label: 'Change Mobile Number',
                            subtitle: 'Verify with OTP to update',
                            color: AppColors.secondary,
                            onTap: _showChangeMobileSheet,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('SAFETY & APP INFO', style: AppText.label),
                    const SizedBox(height: 10),

                    AppGlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.successGreenSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: AppColors.successGreen, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LUMO Safety Guarantee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('All service partners are police-verified, background checked & trained.', style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    AppGlassCard(
                      padding: const EdgeInsets.all(14),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
                          SizedBox(width: 12),
                          Text('App Version', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                          Spacer(),
                          Text('v1.0.0 (Glass Edition)', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Sign Out Card
                    AppGlassCard(
                      onTap: _confirmLogout,
                      gradientColors: const [Color(0x26EF4444), Color(0x0AEF4444)],
                      borderColor: AppColors.emergencyRedBorder,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.emergencyRed, size: 20),
                          SizedBox(width: 10),
                          Text('Sign Out of LUMO', style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.w900, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                  Text(subtitle, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF0F172A) : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
