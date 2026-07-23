import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiClient.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = res['data'] ?? res;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profile = {
            'fullName': SessionStorage.userName,
            'phoneNumber': SessionStorage.userPhone,
            'role': 'CUSTOMER',
            'email': null,
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
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SessionStorage.clearSession();
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            child: const Text('LOG OUT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('My Profile'),
        actions: [
          TextButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.emergencyRed, size: 18),
            label: const Text('Logout',
                style: TextStyle(
                    color: AppColors.emergencyRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x663B82F6),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (_profile?['fullName'] as String? ?? 'C')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile?['fullName']?.toString() ?? 'Customer',
                    style: AppText.heading2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile?['phoneNumber']?.toString() ?? '',
                    style: AppText.caption.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreenSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('VERIFIED CUSTOMER',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.successGreen)),
                  ),

                  const SizedBox(height: 28),

                  // Settings tiles
                  _SettingTile(
                    icon: Icons.phone_android,
                    label: 'Mobile Number',
                    value: _profile?['phoneNumber']?.toString() ?? '',
                  ),
                  _SettingTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _profile?['email']?.toString() ?? 'Not set',
                  ),
                  _SettingTile(
                    icon: Icons.router_outlined,
                    label: 'API Gateway',
                    value: ApiClient.baseUrl,
                    onTap: () {
                      // Show IP config
                    },
                  ),

                  const SizedBox(height: 24),

                  // Safety info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user, color: AppColors.successGreen, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LUMO Safety Promise',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text(
                                'All professionals are police-verified, background-checked, and trained for safety.',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.label),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
